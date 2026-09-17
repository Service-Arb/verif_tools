---
name: prepare-verif
description: Turn an address into a printable verification pack — write tmp/<place>.typ, filling the neighbour's plate and the boards of the nearest businesses from OpenStreetMap, then build it. Use on /prepare-verif, or when asked to prepare/generate the verification sheets, signs or attestation for a business address.
---

# prepare-verif

## 1. What only the user has

| field | |
| --- | --- |
| `address.street`, `address.city` | the postal line |
| `proprietaire` | landlord on the attestation and the rent invoice |
| `brand.descriptor` | the trade and territory line under the name |
| `brand.phone` | the number on this door's card and sheet |

The business itself is a file, not a field — `examples/brands/<brand>.typ`, one
per business however many doors it takes:

| | |
| --- | --- |
| `name` | what it is called, and so the initial the monogram is drawn from |
| `person`, `email`, `site` | who signs for it and how it is reached |
| `primary`, `accent` | its two colours, only when the user names them |

Read that file if the brand already has one and change nothing; write it from
what the user gives if it does not. `primary` fills the card's front and carries
white type, so it has to be dark; `accent` picks out the descriptor, the rule and
the ring. Leave both out — the usual case — and the pack takes the pair
`typ/__main__.typ` names.

`lang` is `"fr"`, `print_my_address_n` is `3`, `brand.print_card_n` is `2`,
`brand.print_sheet_n` is `4` and `street_plate` is `(width: 50cm, height: 30cm)` —
the blank the street plate is cut from, and so both how tall its letters are and
how many A4 sheets it spans — unless the user says otherwise.
The rest of the letterhead — address, e-mail, SIREN, signatory — is fixed in
`typ/documents/bailleur.typ` to `SCI Les Volcans`, so `proprietaire` is that name
unless the user gives their own landlord.

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
  beside ours. Pass over the names a reader already knows — a supermarket chain,
  a bank, a fast-food brand: those doors carry a shopfront, not a plaque, and the
  reader can check them from memory. Take the next one out instead.

Ask the user only for what neither OSM nor the web gives up.

## 3. Write the place

`tmp/<business>_-_<city>_-_<branch>.typ`, shaped like the places under
`examples/`, which `typ/__main__.typ` asserts. `tmp/` is untracked, so a real
door stays out of the repo — but a brand is not a door, and its file stays in
`examples/brands/`, where the next place can import it:

```typst
#import "/examples/brands/aquafix.typ": brand as _brand
#let brand = _brand + (descriptor: ..., phone: ..., print_card_n: 2, print_sheet_n: 4)
```

A name in `tmp/` hides the same name in `examples/`, so never park a copy of an
example there.

A `\n` in a board's name breaks its line and sets what follows smaller — the trade
suffix goes there (`"CLO\nCoffee Co."`). No suffix, no `\n`.

## 4. Build — the pack is what was asked for, so always build it

```sh
mkdir -p ~/Downloads/verif_prints
nix run . -- tmp/<place>.typ -o ~/Downloads/verif_prints    # always writes to_print.pdf
mv ~/Downloads/verif_prints/to_print.pdf ~/Downloads/verif_prints/"<street>_-_<postcode>.pdf"
```

The name is the door — `2_Avenue_Abbé_Védrine_-_63130.pdf`, spaces as
underscores — since every pack is otherwise called `to_print.pdf` and the second
door would bury the first. The same door built twice overwrites itself, which is
what re-reading it is for.

Hand over the path it ends at, and say what is on it: the street plate,
whole, over the first `n` sheets — cut the white strip off each sheet's trailing
edge, lay each over the next, glue — then the attestation, the rent invoice
addressed to the business at that door, our address plate tiled, the neighbour's
plate, one business board per page, the cards to cut out, and the door sheets.

The pack asks the printer for one side and full size, and only Acrobat reads that
— tell the user to set **Two-Sided: Off** and **Scale: 100%** in the dialog
(`lp -o sides=one-sided -o fit-to-page=false`) before they send it. A sheet
printed on both sides is cut through what is on its back, and one scaled to fit
breaks the join between the street plate's sheets.

`nix build "path:.#<place>"` draws every sheet on its own under `result/typ/` —
a symlink into the store, not something to hand over.

## 5. Then read back what the door needs that the pack does not carry

`typ/reusable/` is signs no place decides: the same ones hang on every door, so
they are printed once rather than per pack, and `to_print.pdf` leaves them out.

List what `typ/reusable/` holds — one line each, in the user's `lang`, read off
the files rather than from memory — and ask them to confirm each is already on the
door. Whatever is not:

```sh
nix build .#typ && cp result/typ/reusable/*.<lang>.pdf .
```
