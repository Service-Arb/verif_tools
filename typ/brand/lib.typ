// What the business prints for itself: the sheet that goes on a door or a van,
// and the card. Nothing here names a place, so `.#typ` can draw a brand before it
// has a door; `door` is what one adds — its `descriptor`, `street` and `city`.
#import "../utils.typ": fit, tr, unit

#let _defaults = (
  primary: rgb("#0a2540"),
  accent: rgb("#c2703d"),
  logo: none,
  name_segments: none,
  phone: none,
  site: none,
  trade: none,
  promise: none,
)

// A brand file as the sheets take it.
#let resolve(brand) = {
  let brand = _defaults + brand
  let keys = brand.keys()
  assert(
    ("accent", "email", "logo", "name", "name_segments", "person", "phone", "primary", "promise", "site", "trade").all(key => key in keys),
    message: "brand is missing a required field: " + repr(keys.sorted()),
  )
  for k in ("primary", "accent") { assert(type(brand.at(k)) == color, message: "brand." + k + " is " + repr(brand.at(k)) + ", not a colour") }
  assert(brand.logo == none or type(brand.logo) == str, message: "brand.logo is " + repr(brand.logo) + ", not an image path from the repo root")
  assert(brand.name_segments == none or type(brand.name_segments) == array, message: "brand.name_segments must be an array of styled text segments")
  for k in ("phone", "site") {
    assert(
      brand.at(k) == none or type(brand.at(k)) == str,
      message: "brand." + k + " is " + repr(brand.at(k)) + "; leave it out rather than invent one",
    )
  }
  for k in ("trade", "promise") {
    assert(brand.at(k) == none or type(brand.at(k)) == dictionary, message: "brand." + k + " is " + repr(brand.at(k)) + ", not text keyed by language")
  }
  brand
}

#let _ink = rgb("#051726")
#let _ink-soft = rgb("#5a6b7c")
#let _hairline = rgb("#dce3ea")
#let _card-w = 85mm
#let _card-h = 55mm

#let _monogram(brand, size, fill) = box(width: size, height: size, {
  place(center + horizon, polygon.regular(size: size, vertices: 6, stroke: (paint: fill, thickness: size / 11)))
  place(center + horizon, text(size: size * 0.44, weight: "bold", fill: fill, top-edge: "cap-height", bottom-edge: "baseline", upper(brand.name.first())))
})

#let _mark(brand, size, fill) = if brand.logo == none {
  _monogram(brand, size, fill)
} else if brand.logo.ends-with(".svg") {
  image(bytes(read(brand.logo).replace("currentColor", fill.to-hex())), format: "svg", height: size)
} else {
  image(brand.logo, height: size)
}

#let _name(brand, size, fill) = if brand.name_segments == none {
  text(size: size, weight: "bold", tracking: size * 0.015, fill: fill, upper(brand.name))
} else {
  stack(dir: ltr, spacing: 0pt, ..brand.name_segments.map(segment => text(size: size, weight: "bold", tracking: size * 0.015, fill: segment.color, upper(segment.text))))
}

#let _lockup(brand, size, fill) = grid(
  columns: 2,
  column-gutter: size * 0.42,
  align: horizon,
  _mark(brand, size * 1.25, brand.accent), _name(brand, size, fill),
)

// Without a door, the brand's own lines stand where the descriptor would; the
// second is set in `rest`.
#let _taglines(brand, lang, door, rest) = if door == none {
  (brand.trade, brand.promise).zip((brand.accent, rest)).filter(((s, _)) => s != none).map(((s, fill)) => (tr(s, lang), fill))
} else {
  ((door.descriptor, brand.accent),)
}

#let _front(brand, lang, door) = box(width: _card-w, height: _card-h, fill: brand.primary, {
  set text(font: "Liberation Sans")
  let lines = _taglines(brand, lang, door, white).map(((s, fill)) => align(center, fit(66mm, 7pt, sz => text(size: sz, weight: "medium", tracking: sz * 0.2, fill: fill, upper(s)))))
  place(center + horizon, stack(
    dir: ttb,
    spacing: 7mm,
    align(center, fit(58mm, 22pt, sz => _lockup(brand, sz, white))),
    stack(dir: ttb, spacing: 3mm, ..lines),
  ))
})

#let _back(brand, lang, door) = box(width: _card-w, height: _card-h, fill: white, stroke: 0.4pt + _hairline, {
  set text(font: "Liberation Sans", fill: _ink)
  place(top + left, rect(width: _card-w, height: 2mm, fill: brand.accent))
  place(top + left, block(inset: (x: 7mm, top: 5mm), {
    _mark(brand, 8mm, brand.accent)
    v(3mm)
    text(size: 13pt, weight: "bold", brand.person)
    v(3mm)
    grid(
      columns: (14mm, auto),
      column-gutter: 3mm,
      row-gutter: 1.6mm,
      align: horizon,
      ..tr((fr: ("DIRECT", "COURRIEL", "SITE"), en: ("DIRECT", "EMAIL", "WEB")), lang)
        .zip((brand.phone, brand.email, brand.site))
        .filter(((_, v)) => v != none)
        .map(((l, v)) => (
          text(size: 6pt, weight: "medium", tracking: 0.8pt, fill: _ink-soft, l),
          text(size: 8.5pt, weight: "semibold", v),
        ))
        .flatten()
    )
  }))
  if door != none {
    place(bottom + left, dx: 7mm, dy: -8.5mm, line(length: _card-w - 14mm, stroke: 0.4pt + _hairline))
    place(bottom + left, dx: 7mm, dy: -6mm, text(size: 6.5pt, fill: _ink-soft, door.street + "  ·  " + door.city))
  }
})

#let cards(brand, n, lang, door: none) = range(n).map(_ => unit(box(_front(brand, lang, door) + _back(brand, lang, door))))

#let _band-h = 46mm

// The one arrow, drawn pointing right; every `sym.arrow.*` a place may name is a turn of it.
#let _turns = (
  (sym.arrow.r, 0deg),
  (sym.arrow.br, 45deg),
  (sym.arrow.b, 90deg),
  (sym.arrow.bl, 135deg),
  (sym.arrow.l, 180deg),
  (sym.arrow.tl, -135deg),
  (sym.arrow.t, -90deg),
  (sym.arrow.tr, -45deg),
)

#let _arrow(glyph, size, fill) = {
  let turn = _turns.find(((g, _)) => g == glyph)
  assert(turn != none, message: "arrow " + str(glyph) + " is not one of " + _turns.map(((g, _)) => str(g)).join(" ") + ", the sym.arrow.{r,br,b,bl,l,tl,t,tr}")
  rotate(turn.last(), reflow: true, box(width: size * 1.5, height: size, polygon(
    fill: fill,
    (0pt, size * 0.36),
    (size * 0.85, size * 0.36),
    (size * 0.85, 0pt),
    (size * 1.5, size * 0.5),
    (size * 0.85, size),
    (size * 0.85, size * 0.64),
    (0pt, size * 0.64),
  )))
}

#let _band(brand, lang, sign) = rect(width: 100%, height: _band-h, inset: 0pt, fill: brand.primary, {
  place(top, rect(width: 100%, height: 2.2mm, fill: brand.accent))
  let parts = ()
  if "next_direction" in sign {
    let way = sign.next_direction
    parts.push(stack(dir: ltr, spacing: 9mm, align(horizon, _arrow(way.arrow, 17mm, brand.accent)), align(horizon, fit(150mm, 30pt, sz => text(
      size: sz,
      weight: "bold",
      tracking: sz / 15,
      fill: white,
      upper(way.text),
    )))))
  }
  if "door" in sign {
    parts.push(stack(dir: ttb, spacing: 4.5mm, align(center, text(size: 14pt, weight: "bold", tracking: 4pt, fill: brand.accent, tr((fr: "PORTE", en: "DOOR"), lang))), align(center, text(
      size: 56pt,
      weight: "bold",
      fill: white,
      top-edge: "cap-height",
      bottom-edge: "baseline",
      sign.door,
    ))))
  }
  let rule = line(angle: 90deg, length: 26mm, stroke: 0.8pt + white.transparentize(65%))
  place(center + horizon, dy: 1.1mm, stack(dir: ltr, spacing: 14mm, ..parts.map(p => align(horizon, p)).intersperse(align(horizon, rule))))
})

// `sign`: what this sheet points the way to, from the place's `directions`.
#let poster(brand, lang, dark, door: none, sign: none) = unit(full_page: true, {
  assert(not (dark and sign != none), message: "a sign's band is the brand's primary, so it vanishes on a dark sheet")
  let ink = if dark { white } else { _ink }
  set page(
    paper: "a4",
    flipped: true,
    margin: (x: 18mm, top: 18mm, bottom: 18mm + if sign == none { 0mm } else { _band-h }),
    fill: if dark { brand.primary } else { white },
    background: if sign != none {
      set text(font: "Liberation Sans")
      place(bottom, _band(brand, lang, sign))
    },
  )
  set text(font: "Liberation Sans", fill: ink)
  set par(leading: 0pt, spacing: 0pt)
  align(center + horizon, block(width: 100%, {
    align(center, fit(200mm, 90pt, sz => _lockup(brand, sz, ink)))
    v(16mm)
    stack(
      dir: ttb,
      spacing: 6mm,
      .._taglines(brand, lang, door, ink).map(((s, fill)) => align(center, fit(200mm, 22pt, sz => text(size: sz, weight: "bold", tracking: sz * 0.18, fill: fill, upper(s))))),
    )
    let reached = ()
    if brand.phone != none { reached.push(align(center, fit(190mm, 58pt, sz => text(size: sz, weight: "bold", brand.phone)))) }
    if brand.site != none { reached.push(align(center, text(size: 24pt, weight: "medium", tracking: 2.2pt, fill: if dark { white.transparentize(35%) } else { _ink-soft }, brand.site))) }
    if reached.len() > 0 {
      v(20mm)
      stack(dir: ttb, spacing: 9mm, ..reached)
    }
  }))
})
