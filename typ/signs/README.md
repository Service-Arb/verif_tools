# signs

What hangs on a wall, printed on whatever A4 is in the office: a Lyon street
plate, and the plaques of the place's `nearby`.

```sh
nix build "path:.#<place>" # result/typ/signs/{street,nearby}.pdf
./tests/seam.sh            # the letters continue across the sheets they are cut over
./tests/cap_height.sh      # the fallback's caps come off the paper at the size they claim
```

## The plate

`street.pdf` is the whole plate, drawn at its real size and windowed onto as many
A4 sheets as it spans. Print, cut the white strip off each sheet's trailing edge,
lay each over the next, glue.

Two stages, in this order and never mixed:

```
stage 1 — the plate, in plate coordinates. No paper exists yet.
   0                                                      W = 50cm
   ├──────────────────────────────────────────────────────────┤
   │              R U E   D E S                               │  H = 30cm
   │     C H A N E L L E S                                    │
   └──────────────────────────────────────────────────────────┘
   both axes centred; cap = min(0.211·H, width bound, height bound)

stage 2 — that same drawing, windowed onto paper
   p₀ = −b        p₁ = 189.4          p₂ = 378.8
   ├── sheet 0 ──────┤
   ▓▓▓ ink 209.4mm ▓▓|▒ 0.6mm white → cut it off along the blue edge
              ├── sheet 1 ──────┤
              ◁ 20mm ▷ overlap: same content as the sheet above it,
                       so the letter strokes are the alignment guide
                        ├── sheet 2 ──────┤
                                  plate's right end ──┤ ticks mark it
```

The plate's height runs along the paper's long side, so every sheet is portrait
A4 and the plate's width runs across the 210mm. Drawn 1:1 — 300mm of plate on
297mm of paper loses 1.5mm of blue at the top and bottom, plus the printer's own
white edge.

| | |
| --- | --- |
| `paper` | 210mm, A4's short side |
| `bleed` `b` | 0.6mm, what the printer leaves white at a paper edge |
| `overlap` | 20mm, how much of the sheet below the one above covers |
| trimmed width | `paper − b` — cut along the blue/white boundary, no tick needed; wandering *inward* is free, the sheet below has that content |
| advance `a` | `paper − b − overlap` = 189.4mm |
| sheet `k` origin | `pₖ = −b + k·a`, so the plate's left end sits at sheet 0's ink boundary |
| sheet count | `n = max(1, 1 + ceil((W − paper + 2b) / a))` |

`bleed` and `overlap` are constants, overridable as millimetre numbers on the
direct path (`typst compile --input bleed=0.4 …`); `nix build` takes no argument
and keeps them.

The place gives the blank the plate is cut from — `street_plate`, 50×30cm being
what the émailleurs sell — and the caps are a fraction of its height, 0.211. That
fraction is measured off the reference photo of `6ème ARRᵗ / AVENUE THIERS` rather
than specified anywhere: no national standard fixes it, and Lyon's plates are a
municipal decision with no published charter. The plate in the photo is 1.67:1, so
the same blank, and three of its letters have flat tops and baselines to read the
span across. 30cm of plate puts the caps at 6.3cm.

`layout()` enumerates every way of breaking the name's words into consecutive
lines and keeps the one affording the largest cap, ties going to fewer lines. A
short name keeps the full cap and sits centred with blue either side; one too wide
shrinks. Words are the A–Z runs between spaces, accents stripped and digits
dropped, but a hyphen stays a glyph, so `CLERMONT-FERRAND` neither loses it nor
breaks across lines.

## The fallback

`background.pdf` is the plate's blue, edge to edge, and `alphabet.pdf` is A–Z at
the plate's own cap height, white with a hairline outline to cut along. Tape the
blue together, cut the letters out, glue them on. An hour of scissors, for when
the plate cannot be printed whole.

Letters are adjacent with no gap, so `cutout.typ` packs the rows by measurement:
Typst breaks lines at spaces, and there are none.

## The plaques

`nearby.pdf` draws `plaques.typ`: the board of each of `other_businesses` at the
size it fills a landscape sheet, one per page, then the address plate at the size
one is screwed to a door — ours `print_my_address_n` times and one for each of
`neighbours`, tiled onto as few sheets as they fit. A `\n` in a name is where its
board breaks the line, and the tail sets smaller — where the trade suffix sits.
