# Architecture

One door's worth of paper: a street plate to cut out, the landlord's attestation
and rent invoice, the plaques of the neighbour and of the other businesses
nearby, and what the business hangs and hands out itself.

A place is data, and the sources are not — nothing under `typ/` names a place
file. `typ/__main__.typ` takes the one handed to it on the command line, asserts
its shape, and is what a specialized sheet imports.

Which splits the sources in two, and a build is the query that picks a half:

| | `nix build .#typ` | `nix build "path:.#<place>"` |
| --- | --- | --- |
| asks for | the stock, before there is a door | one door's `to_print.pdf` |
| gets | `typ/reusable/`, every language | every other sheet, specialized |
| reaches `typ/__main__.typ` | never — it is handed no place | through it, for all of them |

A sheet no door configures belongs under `typ/reusable/`, and stays printed until
it runs out. Anything it draws with has to be place-free too, so the drawing sits
apart from the sheet that specializes it — `signs/doorplate.typ` is the plate and
the board, `signs/plaques.typ` is this address tiled across them.

```mermaid
flowchart LR
    A["address"] --> N["scripts/nearby.py<br/>Nominatim, Overpass"]
    N --> P["tmp/place.typ"]
    P -->|--input place=| M["typ/__main__.typ"]
    M --> S["typ/signs/*"]
    M --> D["typ/documents/*"]
    M --> B["typ/brand/*"]
    S --> T["typ/to_print.typ"]
    D --> T
    B --> T
    T --> O["one pass through the printer"]
    R["typ/reusable/*"] --> O
```

`.claude/skills/prepare-verif` walks that left to right.
