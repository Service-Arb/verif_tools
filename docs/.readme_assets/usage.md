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
