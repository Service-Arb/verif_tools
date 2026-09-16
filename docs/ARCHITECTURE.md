# Architecture

One door's worth of paper: a street plate to cut out, a landlord's attestation,
and the plaques of the neighbour and of the competitors nearby.

A place is data, and the sources are not — nothing under `typ/` names a place
file. `typ/__main__.typ` takes the one handed to it on the command line, asserts
its shape, and is what every sheet imports.

```mermaid
flowchart LR
    A["address, trade"] --> N["scripts/nearby.py<br/>Nominatim, Overpass"]
    N --> P["tmp/place.typ"]
    P -->|--input place=| M["typ/__main__.typ"]
    M --> S["typ/signs/*"]
    M --> D["typ/documents/*"]
    S --> T["typ/to_print.typ"]
    D --> T
    T --> O["one pass through the printer"]
```

`.claude/skills/prepare-verif` walks that left to right.
