# signs

A Lyon street plate, printed on whatever A4 is in the office and cut out.

```sh
nix build .#typ            # result/print/signs/{background,alphabet}.pdf
./tests/cap_height.sh      # the caps come off the paper at the size they claim
```

`background.pdf` is the plate's blue, edge to edge. `alphabet.pdf` is A–Z at the
plate's own cap height, white with a hairline outline to cut along — glue the
letters onto the blue. Accented caps and digits are not there; French drops the
accent at this size and the arrondissement is a separate line on the real plate.

The cap height is measured off the reference photo of `6ème ARRᵗ / AVENUE THIERS`
rather than specified anywhere: no national standard fixes it, and Lyon's plates
are a municipal decision with no published charter. The plate in the photo is
1.67:1, which is the 50×30cm enamel blank the émailleurs sell; the caps on it
span 0.211 of its height at the same perspective, across three letters with flat
tops and baselines — 6.3cm. `--input cap=6.5cm` if you get to hold a ruler to one.

Letters are adjacent with no gap, so the rows are packed by measurement in
`alphabet.typ`: Typst breaks lines at spaces, and there are none.
