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

This makes one PDF for each: the signs in `result/typ/reusable/`, the letters to
cut out and the plate colour in `result/typ/signs/`. A sign has one PDF for each
language. Print the one you want.

For one address, write a place file into `tmp/`. Then build the sheets for it:

```sh
nix build "path:.#<place>"
```

The package name is the file name without `.typ`. Use `path:`, because git does
not track `tmp/`. A plain `.` shows nix only the tracked files.

This makes `result/typ/to_print.pdf`. Print it, and cut out the parts.

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

