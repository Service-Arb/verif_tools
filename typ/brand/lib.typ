// What the business prints for itself: the sheet that goes on a door or a van,
// and the card. The place file names the business; the mark and the colours are
// the same whoever it is, so a new door redraws nothing.
#import "../__main__.typ": address, brand, lang
#import "../utils.typ": fit, tr, unit

#let _ink = rgb("#051726")
#let _ink-soft = rgb("#5a6b7c")
#let _navy = rgb("#0a2540")
#let _copper = rgb("#c2703d")
#let _hairline = rgb("#dce3ea")

#let _labels = tr((fr: ("DIRECT", "COURRIEL", "SITE"), en: ("DIRECT", "EMAIL", "WEB")), lang)

// Nothing about a door decides these, and the pack is printed before a business
// has any of them for real.
#let _contact = (
  person: "Valeriy Sakharov",
  phone: "+33 4 23 50 06 40",
  email: "val@aquafix.top",
  site: "aquafix.top",
)

#let _card-w = 85mm
#let _card-h = 55mm

// A monogram: one drawing that reads as a logo whatever the business is called.
#let _mark(size, fill) = box(width: size, height: size, {
  place(center + horizon, polygon.regular(size: size, vertices: 6, stroke: (paint: fill, thickness: size / 11)))
  place(
    center + horizon,
    text(size: size * 0.44, weight: "bold", fill: fill, top-edge: "cap-height", bottom-edge: "baseline", upper(brand.name.first())),
  )
})

#let _lockup(size, fill) = grid(
  columns: 2,
  column-gutter: size * 0.42,
  align: horizon,
  _mark(size * 1.25, _copper), text(size: size, weight: "bold", tracking: size * 0.015, fill: fill, upper(brand.name)),
)

#let _front = box(width: _card-w, height: _card-h, fill: _navy, {
  set text(font: "Liberation Sans")
  place(center + horizon, stack(
    dir: ttb,
    spacing: 7mm,
    align(center, fit(58mm, 22pt, sz => _lockup(sz, white))),
    align(center, fit(66mm, 7pt, sz => text(size: sz, weight: "medium", tracking: sz * 0.2, fill: _copper, upper(brand.descriptor)))),
  ))
})

#let _back = box(width: _card-w, height: _card-h, fill: white, stroke: 0.4pt + _hairline, {
  set text(font: "Liberation Sans", fill: _ink)
  place(top + left, rect(width: _card-w, height: 2mm, fill: _copper))
  // placed rather than flowed, or the face's baseline is its last line rather
  // than its edge, and it hangs below the front beside it
  place(top + left, block(inset: (x: 7mm, top: 5mm), {
    _mark(8mm, _copper)
    v(3mm)
    text(size: 13pt, weight: "bold", _contact.person)
    v(3mm)
    grid(
      columns: (14mm, auto),
      column-gutter: 3mm,
      row-gutter: 1.6mm,
      align: horizon,
      .._labels
        .zip((_contact.phone, _contact.email, _contact.site))
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

// One card is one piece, so the cut that frees a front frees the back that
// belongs to it, and the faces share the edge between them.
#let cards(n) = range(n).map(_ => unit(box(_front + _back)))

// A4 on whatever is in the office. Each line is set to the distance it is read
// from: the lock-up from the corridor, the number from across the room.
#let poster() = unit(full_page: true, {
  set page(paper: "a4", flipped: true, margin: 18mm, fill: white)
  set text(font: "Liberation Sans", fill: _ink)
  set par(leading: 0pt, spacing: 0pt)

  align(center + horizon, block(width: 100%, {
    align(center, fit(200mm, 90pt, sz => _lockup(sz, _ink)))
    v(16mm)
    align(center, fit(200mm, 20pt, sz => text(size: sz, weight: "medium", tracking: sz * 0.18, fill: _copper, upper(brand.descriptor))))
    v(20mm)
    align(center, fit(190mm, 66pt, sz => text(size: sz, weight: "bold", _contact.phone)))
    v(9mm)
    align(center, text(size: 24pt, weight: "medium", tracking: 2.2pt, fill: _ink-soft, _contact.site))
  }))
})
