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
Write a place file. Then build the sheets for it:

```sh
nix run . -- examples/aquafix_-_Clermont-Ferrand_-_North.typ
```

This makes one PDF. Print it, and cut out the parts.

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

