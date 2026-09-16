# signs

What hangs on a wall, printed on whatever A4 is in the office and cut out: a Lyon
street plate, and the plaques of the place's `nearby`.

```sh
nix build "path:.#<place>" # result/typ/signs/{background,alphabet,street,nearby}.pdf
./tests/cap_height.sh      # the caps come off the paper at the size they claim
```

`background.pdf` is the plate's blue, edge to edge. `alphabet.pdf` is A–Z at the
plate's own cap height, white with a hairline outline to cut along — glue the
letters onto the blue. `street.pdf` is the same sheet cut down to the glyphs
the place's street spells, so the plate composes without hunting A–Z for them.

A sheet is caps: `letters()` folds the name to upper case and drops the accents
(French drops them at this size) and the house number, which belongs to the
postal line rather than the plate.

The place gives the blank its plate is cut from — `street_plate`, 50×30cm being
what the émailleurs sell — and the caps are a fraction of its height, 0.211. That
fraction is measured off the reference photo of `6ème ARRᵗ / AVENUE THIERS` rather
than specified anywhere: no national standard fixes it, and Lyon's plates are a
municipal decision with no published charter. The plate in the photo is 1.67:1, so
the same blank, and three of its letters have flat tops and baselines to read the
span across. 30cm of plate puts the caps at 6.3cm.

Letters are adjacent with no gap, so the rows are packed by measurement in
`cutout.typ`: Typst breaks lines at spaces, and there are none.

`nearby.pdf` draws `plaques.typ`: the address plate at the size one is screwed to
a door, tiled `print_my_address_n` times for our address and once for each of
`neighbours`, then the board of each of `other_businesses` at the size it
fills a landscape sheet, one per page. A `\n` in a name is where its board breaks
the line, and the tail sets smaller — where the trade suffix sits.
