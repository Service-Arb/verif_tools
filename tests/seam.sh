#!/usr/bin/env bash
# The plate is drawn once and windowed onto sheets, so the only thing that can be
# wrong is where a window starts. Render at a known ppi and read the seam off the
# pixels: a sheet's trailing ink edge has to carry the same strokes as the column
# the next sheet puts it over.
set -euo pipefail
cd "$(dirname "$0")/.."

places=("$@")
if [ ${#places[@]} -eq 0 ]; then
  places=(
    /examples/random_location_france.typ # AVENUE DES / LANDAIS
    /examples/aquafix_-_Clermont-Ferrand_-_Montjuzet.typ # RUE DES / CHANELLES
  )
fi
paper_mm=210
bleed_mm=0.6
overlap_mm=20
ppi=300
tol_px=2

fonts="$(nix build nixpkgs#liberation_ttf --no-link --print-out-paths)/share/fonts/truetype"
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

for place in "${places[@]}"; do
  dir="$out/$(basename "$place" .typ)"
  mkdir -p "$dir"

  typst compile --root . --ignore-system-fonts --input "place=$place" \
    --font-path "$fonts" \
    --format png --ppi "$ppi" typ/signs/street.typ "$dir/p{p}.png"

  python3 - "$dir" "$paper_mm" "$bleed_mm" "$overlap_mm" "$ppi" "$tol_px" "$place" <<'PY'
import glob, subprocess, sys

out, place = sys.argv[1], sys.argv[7]
paper, bleed, overlap, ppi, tol = map(float, sys.argv[2:7])
px = lambda mm: round(mm / 25.4 * ppi)
fail = []

pages = sorted(glob.glob(out + "/p*.png"), key=lambda p: int(p[len(out) + 2:-4]))
assert len(pages) > 1, place + " spans one sheet; nothing to seam"

sheets = []
for page in pages:
    ppm = page[:-4] + ".ppm"
    subprocess.run(["magick", page, "-depth", "8", ppm], check=True)
    with open(ppm, "rb") as f:
        assert f.readline().strip() == b"P6"
        w, h = map(int, f.readline().split())
        f.readline()
        d = f.read()
    sheets.append((page, w, h, d))

    at = lambda x, y: d[(y * w + x) * 3 : (y * w + x) * 3 + 3]
    for cx, cy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        r, g, b = at(cx, cy)
        # #222D5A, the plate blue, edge to edge — a white corner is a page that
        # did not take the fill
        if abs(r - 0x22) > 24 or abs(g - 0x2D) > 24 or abs(b - 0x5A) > 24:
            fail.append(f"{page}: corner {cx},{cy} is #{r:02x}{g:02x}{b:02x}, not the plate blue")

# A run of white in a column is a letter stroke crossing it. The two columns hold
# the same plate coordinate, so they hold the same strokes — read 1mm inside the
# trailing edge, where the registration hairline does not sit.
inset = 1
def strokes(sheet, x_mm):
    page, w, h, d = sheet
    x = px(x_mm)
    assert 0 <= x < w, f"{page}: no column at {x_mm}mm"
    runs, start = [], None
    for y in range(h):
        i = (y * w + x) * 3
        white = d[i] > 200 and d[i + 1] > 200 and d[i + 2] > 200
        if white and start is None:
            start = y
        elif not white and start is not None:
            runs.append((start, y - 1))
            start = None
    if start is not None:
        runs.append((start, h - 1))
    return runs

for k, (above, below) in enumerate(zip(sheets, sheets[1:])):
    a = strokes(above, paper - bleed - inset)
    b = strokes(below, overlap - inset)
    if len(a) != len(b):
        fail.append(f"sheet {k + 1} leaves {len(a)} strokes at its trailing edge, sheet {k + 2} picks up {len(b)}")
        continue
    for (a0, a1), (b0, b1) in zip(a, b):
        if abs(a0 - b0) > tol or abs(a1 - b1) > tol:
            fail.append(f"sheet {k + 1}/{k + 2}: a stroke runs {a0}-{a1} above and {b0}-{b1} below, past {tol:.0f}px")

print("\n".join(fail) or f"ok: {place}, {len(pages)} sheets, {len(strokes(sheets[0], paper - bleed - inset))} strokes at the first seam")
sys.exit(1 if fail else 0)
PY
done
