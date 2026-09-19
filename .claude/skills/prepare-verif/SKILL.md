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
| `brands[].descriptor` | each trade and territory line under its name |

The business itself is a file, not a field — `examples/brands/<brand>.typ`, one
per business however many doors it takes:

| | |
| --- | --- |
| `name` | what it is called, and so the initial the monogram falls back to |
| `person`, `email` | who signs for it and how it is reached |
| `primary`, `accent` | its two colours, only when the user names them |
| `logo` | the mark, preferably SVG but any supported image path — see §1.1 |
| `name_segments` | optional persistent colored name segments, reused on every branded sheet |

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
one.**

Prefer an SVG emblem when the source is an emblem, because it scales cleanly and
can use the brand accent. But `logo` accepts any image path Typst can read: SVG,
PNG, JPEG, or another supported raster format. A supplied full-brand image may
contain the emblem, name, slogan and colors together. In that case preserve the
source in `docs/logos/` or `assets/logos/`, extract a clean emblem PNG for `logo`,
and record the extracted colors, written name, and slogan in the brand file before
rendering. Do not replace a strong supplied reference with an invented generic
mark.

```
full brand image ──▶ save reference, extract emblem PNG, colors, name, slogan
emblem source     ──▶ prefer assets/logos/<brand>.svg; accept .png/.jpg too
no source         ──▶ generate an application-specific emblem, never a placeholder
```

Then set `logo` to the extracted emblem path. The card, poster and card back all
draw it. If the supplied image already contains the wordmark, do not place that
full image where the pipeline expects an emblem: use the extracted emblem and
persistent text fields instead.

The visible name can be defined once with `name_segments`, then every branded
sheet reuses it:

```typst
name_segments: (
  (text: "Secure", color: rgb("#102A43")),
  (text: "Lock", color: rgb("#1677D2")),
),
```

Use this for persistent treatments such as `Secure` plus blue `Lock`. Keep the
plain `name` as the canonical searchable name.

`docs/logos/` is the reference set. Read it before creating a mark and add supplied
references there; reference images are inputs, not disposable inspiration.

An SVG written with `fill="currentColor"` comes out in `accent` wherever it lands,
which is what `assets/logos/aquafix.svg` is. Prefer that for a one- or two-colour
emblem; hand a full-colour raster over as it is when extraction would lose detail.

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

One place file may import several brand files. Keep the place-derived address,
nearby businesses, landlord and print counts in the place file, and add each
brand's place-specific descriptor and counts to `brands`:

```typst
#import "/examples/brands/aquafix.typ": brand as aquafix
#import "/examples/brands/serrunova.typ": brand as serrunova
#let brands = (
  aquafix + (descriptor: ..., phone: none, print_card_n: 2, print_sheet_n: 4),
  serrunova + (descriptor: ..., phone: none, print_card_n: 2, print_sheet_n: 4),
)
```

A physical location has one place file and one `to_print.pdf`. Shared place
sheets are rendered once; each configured brand then contributes its own posters
and cards. Put the place config under `tmp/<city>_<street>_<postcode>/` when the
location is temporary. Generated PDFs never go in `tmp/`.

`nix run . -- tmp/<place>.typ` writes one PDF by default to
`~/Downloads/verif_prints/<place>.pdf`; use `-o DIR` only when a different output
folder is required.

```typst
#import "/examples/brands/aquafix.typ": brand as aquafix
#let brands = (aquafix + (descriptor: ..., phone: none, print_card_n: 2, print_sheet_n: 4))
```

Each brand file remains under `examples/brands/` so another place can import it.

`phone: ...` joins that dictionary when the door has a number, and is absent when
it has none — see §1.0.

A name in `tmp/` hides the same name in `examples/`, so never park a copy of an
example there.

A `\n` in a board's name breaks its line and sets what follows smaller — the trade
suffix goes there (`"CLO\nCoffee Co."`). No suffix, no `\n`.

## 4. Build — the pack is what was asked for, so always build it

```sh
nix run . -- tmp/<place>.typ
```

The command writes one PDF by default to `~/Downloads/verif_prints/<place>.pdf`.
Pass `-o DIR` only when a different output folder is required. The PDF contains
one shared set of place-derived sheets, followed by each brand's posters and
cards.

Hand over the path it ends at, and say what is on it: the street plate, the
attestation, the rent invoice addressed to the location, our address plate tiled,
the neighbour's plate, one business board per page, then each configured brand's
cards and door sheets.

## 5. Then read back what the door needs that the pack does not carry

`typ/reusable/` is signs no place decides: the same ones hang on every door, so
they are printed once rather than per pack, and `to_print.pdf` leaves them out.

List what `typ/reusable/` holds — one line each, in the user's `lang`, read off
the files rather than from memory — and ask them to confirm each is already on the
door. Whatever is not:

```sh
nix build .#typ && cp result/typ/reusable/*.<lang>.pdf .
```
