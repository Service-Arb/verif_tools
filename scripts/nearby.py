#!/usr/bin/env python3
"""What is next door and what is across the street, from OpenStreetMap.

  ./scripts/nearby.py "23 avenue des Landais, 63100 Clermont-Ferrand"

Neighbours are the two nearest street numbers on the same street; the businesses
are the nearest named ones of any trade — what OSM carries of the profiles a map
shows around that door. Both come out as JSON, to be read and folded into a
tmp/<place>.typ by hand — OSM names a building far less often than it names a
shop, so the neighbour usually comes back without a `name`.
"""

import argparse, json, math, sys, urllib.parse, urllib.request

UA = "verif_tools (https://github.com/Service-Arb/verif_tools)"


def _get(url, data=None):
    req = urllib.request.Request(url, data=data, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def geocode(address):
    q = urllib.parse.urlencode({"q": address, "format": "jsonv2", "limit": 1, "addressdetails": 1})
    hits = _get("https://nominatim.openstreetmap.org/search?" + q)
    if not hits:
        sys.exit(f"nominatim knows no {address!r}")
    h = hits[0]
    return float(h["lat"]), float(h["lon"]), h["address"]


def overpass(query):
    body = urllib.parse.urlencode({"data": query}).encode()
    return _get("https://overpass-api.de/api/interpreter", body)["elements"]


def by_distance(elements, lat, lon):
    out = []
    for e in elements:
        c = e.get("center", e)
        if "lat" not in c:
            continue
        dx = (c["lon"] - lon) * math.cos(math.radians(lat)) * 111320
        dy = (c["lat"] - lat) * 110540
        out.append((round(math.hypot(dx, dy)), e.get("tags", {})))
    return sorted(out, key=lambda p: p[0])


# Anything a map puts a named pin on counts, a car park as much as a shop — the
# board only has to read as a door we are next to. What drops out is what never
# carries a name and an address of its own.
TRADE_KEYS = ("shop", "office", "craft", "amenity", "healthcare", "leisure", "tourism")
NO_NAMEPLATE = {
    "bench", "bicycle_parking", "clock", "drinking_water", "fountain", "parking_space",
    "post_box", "recycling", "shelter", "telephone", "waste_basket", "waste_disposal",
}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("address")
    p.add_argument("--radius", type=int, default=600, help="metres to look for businesses in")
    p.add_argument("-n", type=int, default=3, help="how many businesses")
    a = p.parse_args()

    lat, lon, addr = geocode(a.address)
    street = addr.get("road", "")

    doors = by_distance(
        overpass(f'[out:json][timeout:25];nwr(around:300,{lat},{lon})["addr:housenumber"]["addr:street"="{street}"];out center tags;'),
        lat,
        lon,
    )
    # one door can be a node and a way at once, and both carry the name
    seen = set()
    around = [
        (m, t)
        for m, t in by_distance(
            overpass(
                "[out:json][timeout:25];("
                + "".join(f'nwr(around:{a.radius},{lat},{lon})["name"]["{k}"];' for k in TRADE_KEYS)
                + ");out center tags;"
            ),
            lat,
            lon,
        )
        if not NO_NAMEPLATE & {t.get(k) for k in TRADE_KEYS} and not (t["name"] in seen or seen.add(t["name"]))
    ]

    json.dump(
        {
            "resolved": {"lat": lat, "lon": lon, "street": street, "city": f"{addr.get('postcode', '')} {addr.get('city', addr.get('town', ''))}".strip()},
            "neighbours": [
                {"m": m, "name": t.get("name"), "street": f"{t['addr:housenumber']} {t['addr:street']}"}
                for m, t in doors[:4]
            ],
            # `what` is only there to write the smaller line of a board with
            "businesses": [
                {"m": m, "name": t["name"], "what": next(t[k] for k in TRADE_KEYS if k in t)}
                for m, t in around[: a.n]
            ],
        },
        sys.stdout,
        indent=2,
        ensure_ascii=False,
    )
    print()


if __name__ == "__main__":
    main()
