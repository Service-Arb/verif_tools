# verif_tools
![Lines Of Code](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/valeratrades/b48e6f02c61942200e7d1e3eeabf9bcb/raw/verif_tools-loc.json)

TODO
<!-- markdownlint-disable -->
<details>
<summary>
<h2>Installation</h2>
</summary>

TODO

</details>
<!-- markdownlint-restore -->

## Usage
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



<br>

<sup>
	This repository follows <a href="https://github.com/valeratrades/.github/tree/master/best_practices">my best practices</a> and <a href="https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md">Tiger Style</a> (except "proper capitalization for acronyms": (VsrState, not VSRState) and formatting). For project's architecture, see <a href="./docs/ARCHITECTURE.md">ARCHITECTURE.md</a>.
</sup>

#### License

<sup>
	Licensed under <a href="LICENSE">Blue Oak 1.0.0</a>
</sup>

<br>

<sub>
	Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in this crate by you, as defined in the Apache-2.0 license, shall
be licensed as above, without any additional terms or conditions.
</sub>

