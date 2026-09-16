---
name: prepare-verif
description: Turn an address into a printable verification pack — write tmp/<place>.typ, filling the neighbour's plate and the boards of the nearest businesses from OpenStreetMap, then build it. Use on /prepare-verif, or when asked to prepare/generate the verification sheets, signs or attestation for a business address.
---

# prepare-verif

## 1. What only the user has

| field | |
| --- | --- |
| `address.street`, `address.city` | the postal line |
| `proprietaire` | landlord on the attestation |
| `brand.name`, `brand.descriptor` | the business, and the trade and territory line under it |

`lang` is `"fr"`, `print_my_address_n` is `3`, `brand.print_card_n` is `2` and
`brand.print_sheet_n` is `4` unless the user says otherwise.
The rest of the letterhead — address, e-mail, SIREN, signatory — is fixed in
`typ/documents/attestation_interdiction_enseigne.typ` to `SCI Les Volcans`, so
`proprietaire` is that name unless the user gives their own landlord.

## 2. Look up the rest

```sh
./scripts/nearby.py "<street>, <city>"     # --radius, -n when the street is bare
```

- `address.name` — what our own building is called. OSM names a building far less
  often than a shop; the copropriété registers do name it, so search the web for
  the street number.
- `neighbours` — the closest door that is not ours, its name found the same way.
- `other_businesses` — the closest three named businesses, whatever they sell. A
  car park counts as readily as a shop; the board only has to read as a door
  beside ours.

Ask the user only for what neither OSM nor the web gives up.

## 3. Write the place

`tmp/<business>_-_<city>_-_<branch>.typ`, shaped like the file under `examples/`,
which `typ/__main__.typ` asserts. `tmp/` is untracked, so a real door stays out of
the repo.

A `\n` in a board's name breaks its line and sets what follows smaller — the trade
suffix goes there (`"CLO\nCoffee Co."`). No suffix, no `\n`.

## 4. Build — the pack is what was asked for, so always build it

```sh
nix run . -- tmp/<place>.typ           # prints the path it wrote
nix run . -- tmp/<place>.typ -o DIR    # DIR is a directory; the file is always to_print.pdf
```

Without `-o` it lands in the user's downloads, where a second door overwrites the
first. Hand over the path it printed, and say what is on it: the street letters to
cut out, the attestation, our address plate tiled, the neighbour's plate, one
business board per page, the cards to cut out, and the door sheets.

`nix build "path:.#<place>"` draws every sheet on its own under `result/typ/` —
a symlink into the store, not something to hand over.

## 5. Then read back what the door needs that the pack does not carry

`typ/reusable/` is signs no place decides: the same ones hang on every door, so
they are printed once rather than per pack, and `to_print.pdf` leaves them out.

Read `typ/reusable/lib.typ` and list what it draws — one line each, in the user's
`lang` — and ask them to confirm each is already on the door. Whatever is not:

```sh
nix build "path:.#<place>" && cp result/typ/reusable/__main__.pdf .   # one version per page
```
