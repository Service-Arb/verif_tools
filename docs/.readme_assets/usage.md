Some sheets are the same for all addresses. Build them with no place file:

```sh
nix build .#typ
```

This makes one PDF for each: the signs in `result/typ/reusable/`, and the plate
colour in `result/typ/signs/`. A sign has one PDF for each language. Print the
one you want.

Each business is a file in `examples/brands/`. It holds the name, the contact and
the two colours. One business can have many addresses, and they all read this
file.

For one address, write a place file into `tmp/`. The place file imports a brand,
and adds what this address gives: the trade line, the phone, and the count of
each sheet. Then build the sheets for it:

```sh
nix build "path:.#<place>"
```

The package name is the file name without `.typ`. Use `path:`, because git does
not track `tmp/`. A plain `.` shows nix only the tracked files.

This makes `result/typ/to_print.pdf`. Print it, and cut out the parts.

Print one side of each sheet, at full size. The PDF asks for this, but many
printer dialogs do not obey. Set these in the dialog:

| setting | value |
| --- | --- |
| Two-Sided | Off |
| Scale | 100% |

With the `lp` command, use `-o sides=one-sided -o fit-to-page=false`.

The street plate is on the first sheets. It is wider than one sheet, so it uses
more than one. Cut the white edge off each of these sheets. Then put each sheet
on the next sheet and glue it. The letters continue across the join.

To get that file in your download directory, use this:

```sh
nix run . -- tmp/<place>.typ          # -o DIR puts it in DIR instead
```

In Claude Code, `/prepare-verif` writes the place file from an address.
