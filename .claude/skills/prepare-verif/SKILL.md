---
name: prepare-verif
description: Turn an address into a printable verification pack — write tmp/<place>.typ, filling neighbour and competitor plaques from OpenStreetMap, then build it. Use on /prepare-verif, or when asked to prepare/generate the verification sheets, signs or attestation for a business address.
---

# prepare-verif

## 1. Collect what cannot be looked up

From the conversation, or from a half-written place file the user points at:

| field | |
| --- | --- |
| `address.name` | what the plate on *our* building says |
| `address.street`, `address.city` | the postal line |
| `proprietaire` | landlord on the attestation |
| trade | OSM selector for competitors, e.g. `shop=hairdresser`, `office=lawyer`, `amenity=cafe` |

Ask only for the ones still missing. `lang` defaults to `"fr"`,
`print_my_address_n` to `3`.

## 2. Look up the neighbourhood

```sh
./scripts/nearby.py "<street>, <city>" --trade <selector>
```

Nearest doors on the same street, and the nearest named businesses of that trade.
Take the closest door as the neighbour and the closest three as competitors. OSM
names shops far more often than buildings — if the neighbour comes back
`"name": null`, search the web for what that door is called, and ask if that turns
up nothing.

## 3. Write the place

`tmp/<business>_-_<city>_-_<branch>.typ`, shaped like the file under `examples/`
— `tmp/` is untracked, so a real door does not land in the repo unless the user
asks for it. `typ/__main__.typ` holds the asserts it has to satisfy. In a
competitor's name,
`\n` is where its board breaks the line, and everything after it sets smaller —
put the trade suffix there (`"CLO\nCoffee Co."`).

## 4. Build

Always build — the pack, not the place file, is what the user asked for.

```sh
nix run . -- tmp/<place>.typ          # to_print.pdf, in the user's downloads
nix run . -- tmp/<place>.typ -o DIR   # -o names a directory, the file is always to_print.pdf
nix build "path:.#<place>"            # every sheet on its own, under result/typ/
```

Prefer `nix run`: it prints the path it wrote, and that path is a file the user
can open, not a symlink into the store. It writes one `to_print.pdf`, so a second
door overwrites the first unless you give `-o`. `path:` and not `.` on the build,
or nix reads the git tree, which does not have `tmp/` in it.

Show the user the path it printed and what is on it: the street letters to cut out, the
attestation, our address plate tiled, the neighbour's plate, one competitor board
per page.
