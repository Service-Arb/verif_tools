// What the business prints for itself: the sheet that goes on a door or a van,
// and the card. The brand is explicit so several businesses can share one place.
#import "../__main__.typ": address, lang
#import "../utils.typ": fit, tr, unit

#let _ink = rgb("#051726")
#let _ink-soft = rgb("#5a6b7c")
#let _hairline = rgb("#dce3ea")
#let _labels = tr((fr: ("DIRECT", "COURRIEL", "SITE"), en: ("DIRECT", "EMAIL", "WEB")), lang)
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

#let _lockup(brand, size, fill) = grid(
  columns: 2,
  column-gutter: size * 0.42,
  align: horizon,
  _mark(brand, size * 1.25, brand.accent), text(size: size, weight: "bold", tracking: size * 0.015, fill: fill, upper(brand.name)),
)

#let _front(brand) = box(width: _card-w, height: _card-h, fill: brand.primary, {
  set text(font: "Liberation Sans")
  place(center + horizon, stack(
    dir: ttb,
    spacing: 7mm,
    align(center, fit(58mm, 22pt, sz => _lockup(brand, sz, white))),
    align(center, fit(66mm, 7pt, sz => text(size: sz, weight: "medium", tracking: sz * 0.2, fill: brand.accent, upper(brand.descriptor)))),
  ))
})

#let _back(brand) = box(width: _card-w, height: _card-h, fill: white, stroke: 0.4pt + _hairline, {
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
      .._labels
        .zip((brand.phone, brand.email, brand.site))
        .filter(((_, v)) => v != none)
        .map(((l, v)) => (
          text(size: 6pt, weight: "medium", tracking: 0.8pt, fill: _ink-soft, l),
          text(size: 8.5pt, weight: "semibold", v),
        ))
        .flatten()
    )
  }))
  place(bottom + left, dx: 7mm, dy: -8.5mm, line(length: _card-w - 14mm, stroke: 0.4pt + _hairline))
  place(bottom + left, dx: 7mm, dy: -6mm, text(size: 6.5pt, fill: _ink-soft, address.street + "  ·  " + address.city))
})

#let cards(brand, n) = range(n).map(_ => unit(box(_front(brand) + _back(brand))))

#let poster(brand) = unit(full_page: true, {
  set page(paper: "a4", flipped: true, margin: 18mm, fill: white)
  set text(font: "Liberation Sans", fill: _ink)
  set par(leading: 0pt, spacing: 0pt)
  align(center + horizon, block(width: 100%, {
    align(center, fit(200mm, 90pt, sz => _lockup(brand, sz, _ink)))
    v(16mm)
    align(center, fit(200mm, 20pt, sz => text(size: sz, weight: "medium", tracking: sz * 0.18, fill: brand.accent, upper(brand.descriptor))))
    let reached = ()
    if brand.phone != none { reached.push(align(center, fit(190mm, 66pt, sz => text(size: sz, weight: "bold", brand.phone)))) }
    if brand.site != none { reached.push(align(center, text(size: 24pt, weight: "medium", tracking: 2.2pt, fill: _ink-soft, brand.site))) }
    if reached.len() > 0 {
      v(20mm)
      stack(dir: ttb, spacing: 9mm, ..reached)
    }
  }))
})
