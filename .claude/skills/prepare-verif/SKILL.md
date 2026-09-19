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

The business itself is a file, not a field — `examples/brands/<brand>.typ`, one
per business however many doors it takes:

| | |
| --- | --- |
| `name` | what it is called, and so the initial the monogram falls back to |
| `person`, `email` | who signs for it and how it is reached |
| `primary`, `accent` | its two colours, only when the user names them |
| `logo` | the mark, a path from the repo root — see §1.1 |

## 1.0 `phone` and `site`, which a reader checks before anything else

Both are optional and neither has a default. Written, they go on the card's back
and the door sheet in the largest type on the page; left out, the sheet closes
after the trade line and nothing marks their absence.

Put one in only when it is **known** — the user gave it, or it was read off the
brand's own site or listing. A number that does not ring and a domain that does
not resolve are the two things a reviewer can check in seconds, and either one
failing costs more than the blank line it filled. So the order is: what the user
says, then what the brand publishes, then nothing.

`phone` sits on the place, since one business can answer on a different line at
each door; `site` sits on the brand file, since a business has one. A door with
no line of its own carries the brand's published number or none.

A source that gives the value but not which door it is for is not knowing. Never
guess an optional field: leave it off, build without it, and say at the end which
door is missing what and what would settle it.

Read that file if the brand already has one and change nothing; write it from
what the user gives if it does not. `primary` fills the card's front and carries
white type, so it has to be dark; `accent` picks out the descriptor, the rule and
the ring. Leave both out — the usual case — and the pack takes the pair
`typ/__main__.typ` names.

## 1.1 The logo, which is the one thing on the door that says the trade

The door sheet is the largest object in the verification shot. Whoever reviews it
is checking that this door belongs to the trade it claims, and the mark is what
carries that before a word is read — a drop, a wrench, a length of pipe says
plumber; a letter in a ring says nothing. **A generic mark is worse than a loud
one.** So every brand file should end up with a `logo`, and the monogram is only
what draws while it has none.

Never invent the mark in Typst. Either the user hands one over, or one is
generated — and what is generated is the **emblem alone**, since `typ/brand/lib.typ`
sets the name in type beside it and a file carrying its own wordmark prints the
name twice. Transparent background: the card's front is navy.

```
user has a file    ──▶ cp into assets/logos/<brand>.<svg|png>
no file            ──▶ generate, crop the wordmark off, same path
                       prompt: the trade's objects in one silhouette,
                       flat vector, <primary>/<accent>, transparent, no text
```

Then `logo: "/assets/logos/<brand>.svg"` in the brand file, and nothing else
changes — the card, the poster and the card back all draw it.

`docs/logos/README.md` is the reference set: four marks that read as plumbing
across the room, and what makes each of them work. Read it before generating, and
add whatever is generated to it if it is better than what is there.

An SVG written with `fill="currentColor"` comes out in `accent` wherever it lands,
which is what `assets/logos/aquafix.svg` is. Prefer that for a one- or two-colour
mark; hand a full-colour one over as it is.

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

`tmp/<city>_-_<service-type>_-_<service-area>_-_<address>.typ`, shaped like the
places under `examples/`, which `typ/__main__.typ` asserts. Keep the service area
that the business actually serves in the filename; it matters more than the exact
municipality containing the door. `tmp/` is untracked, so a real door stays out of
the repo — but a brand is not a door, and its file stays in `examples/brands/`,
where the next place can import it:

For example, a plumbing business at Royat can serve Clermont-Ferrand, so name the
pack `Royat_-_Plumbing_-_Clermont-Ferrand_-_<address>.typ`, not merely
`Royat_-_<address>.typ`.

Use `Plumbing`, `House-Cleaning`, and similar stable English service labels for
`<service-type>`; use the business's actual service area for `<service-area>`.

When the service area contains several words, keep them as words joined by
hyphens inside that field; reserve `_-_` for the four filename fields.

When several businesses share one physical location, put configs under
`tmp/<city>_<street>_<postcode>/` and PDFs under the matching
`~/Downloads/verif_prints/<city>_<street>_<postcode>/`. Keep each four-field
filename unchanged. Never put generated PDFs in `tmp/`.

For that case, build each config with `-o` set to the nested Downloads folder,
then rename its `to_print.pdf` there to the config's four-field `.pdf` name.
For a single business, keep the flat `~/Downloads/verif_prints/` output folder.

```typst
#import "/examples/brands/aquafix.typ": brand as _brand
#let brand = _brand + (descriptor: ..., print_card_n: 2, print_sheet_n: 4)
```

```typst
#import "/examples/brands/aquafix.typ": brand as _brand
#let brand = _brand + (descriptor: ..., print_card_n: 2, print_sheet_n: 4)
```

`phone: ...` joins that dictionary when the door has a number, and is absent when
it has none — see §1.0.

A name in `tmp/` hides the same name in `examples/`, so never park a copy of an
example there.

A `\n` in a board's name breaks its line and sets what follows smaller — the trade
suffix goes there (`"CLO\nCoffee Co."`). No suffix, no `\n`.

## 4. Build — the pack is what was asked for, so always build it

```sh
mkdir -p ~/Downloads/verif_prints
nix run . -- tmp/<place>.typ -o ~/Downloads/verif_prints    # always writes to_print.pdf
mv ~/Downloads/verif_prints/to_print.pdf \
   ~/Downloads/verif_prints/"<City>_-_<ServiceType>_-_<ServiceArea>_-_<address>.pdf"
```

`Royat_-_Plumbing_-_Clermont-Ferrand_-_2_avenue_Abbé_Védrine_63130.pdf`,
spaces as underscores. Every pack is otherwise called `to_print.pdf`, so the
second door would bury the first; the municipality leads for locating the door,
while the service type and especially the service area make its purpose clear.
The brand name is not part of this filename: one brand can cover several service
areas, and the service fields are what distinguish the packs. The same door built
twice overwrites itself, which is what re-reading it is for.

The `.typ` input follows the same four-field naming scheme:
`<City>_-_<ServiceType>_-_<ServiceArea>_-_<address>.typ`.
The address field may contain the street and postcode, but do not add another
`_-_` field separator inside it.

The output PDF uses the same four-field naming scheme:
`<City>_-_<ServiceType>_-_<ServiceArea>_-_<address>.pdf`.

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
