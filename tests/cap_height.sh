#!/usr/bin/env bash
# The letters are cut out and stuck on a plate, so the only thing that can be
# wrong is their size on paper. Render at a known ppi and read it back off the
# pixels rather than trusting the solve in alphabet.typ.
set -euo pipefail
cd "$(dirname "$0")/.."

cap_mm=63
margin_mm=10
ppi=300
tol_mm=0.5

out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

typst compile --ignore-system-fonts \
  --font-path "$(nix build nixpkgs#liberation_ttf --no-link --print-out-paths)/share/fonts/truetype" \
  --format png --ppi "$ppi" typ/print/signs/alphabet.typ "$out/p{p}.png"

python3 - "$out" "$cap_mm" "$margin_mm" "$ppi" "$tol_mm" <<'PY'
import glob, subprocess, sys

out, cap, margin, ppi, tol = sys.argv[1], *map(float, sys.argv[2:])
mm = lambda px: px / ppi * 25.4
fail, heights = [], []

pages = sorted(glob.glob(out + "/p*.png"))
assert pages, "alphabet.typ rendered nothing"

for page in pages:
    ppm = page[:-4] + ".ppm"
    subprocess.run(["magick", page, "-depth", "8", ppm], check=True)
    with open(ppm, "rb") as f:
        assert f.readline().strip() == b"P6"
        w, h = map(int, f.readline().split())
        f.readline()
        d = f.read()
    ink = lambda x, y: d[(y * w + x) * 3] < 200
    rows = [y for y in range(h) if any(ink(x, y) for x in range(w))]
    assert rows, page + " is blank"

    bands, s, p = [], rows[0], rows[0]
    for y in rows[1:]:
        if y > p + 5:
            bands.append((s, p))
            s = y
        p = y
    bands.append((s, p))

    for (_, above), (below, _) in zip(bands, bands[1:]):
        if mm(below - above) < 1:
            fail.append(f"{page}: two rows clear each other by {mm(below - above):.2f}mm, nothing to cut between")

    for top, bot in bands:
        # a row is never shorter than the cap; O overshoots it and Q descends past
        # it, so only the floor is an invariant here
        heights.append(mm(bot - top + 1))
        if heights[-1] < cap - tol:
            fail.append(f"{page}: a row of caps measures {heights[-1]:.2f}mm, want at least {cap}mm")
        cols = [x for x in range(w) if any(ink(x, y) for y in range(top, bot + 1))]
        edge = min(mm(cols[0]), mm(w - 1 - cols[-1]))
        if edge < margin - tol:
            fail.append(f"{page}: a row reaches {edge:.2f}mm from the paper edge, want {margin}mm")

# every flat-topped, flat-bottomed cap draws exactly the cap height, and A-Z has
# plenty of them — so the shortest row in the document is the solve, measured
if abs(min(heights) - cap) > tol:
    fail.append(f"the shortest row measures {min(heights):.2f}mm, so the cap solves to that, not {cap}mm")

print("\n".join(fail) or f"ok: {len(pages)} pages, {len(heights)} rows, cap {min(heights):.2f}mm")
sys.exit(1 if fail else 0)
PY
