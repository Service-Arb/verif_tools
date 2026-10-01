Some sheets are the same for all addresses. Build them with no place file:

```sh
nix build .#typ
```

This makes one PDF for each: the signs in `result/typ/reusable/`. A sign has one
PDF for each language. Print the one you want.

Each business is a file in `examples/brands/`. It holds the name, the contact and
the two colours. One business can have many addresses, and they all read this
file.

For one address, write a place file into `tmp/`. The place file imports a brand,
and adds what this address gives: the trade line and the count of each sheet. Add
the phone number only if this door has one. Add the web site to the brand file
only if the business has one. The sheets show no line for what you do not give.
Then build the sheets for it:

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
more than one. Cut each of these sheets along the edge of its blue. Then put each
sheet on the next sheet and glue it. The letters continue across the join, and
the blue is as wide as the plate.

To get that file in your download directory, use this:

```sh
nix run . -- tmp/<place>.typ          # -o DIR puts it in DIR instead
```

In Claude Code, `/prepare-verif` writes the place file from an address.
