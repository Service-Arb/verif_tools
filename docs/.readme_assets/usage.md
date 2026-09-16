Write a place file into `tmp/`. Then build the sheets for it:

```sh
nix build "path:.#<place>"
```

The package name is the file name without `.typ`. Use `path:`, because git does
not track `tmp/`. A plain `.` shows nix only the tracked files.

This makes `result/typ/to_print.pdf`. Print it, and cut out the parts.

In Claude Code, `/prepare-verif` writes the place file from an address.
