// What the business prints for itself: the sheet that goes on a door or a van,
// and the card. The place file names the business; the mark and the colours are
// the same whoever it is, so a new door redraws nothing.
#import "../__main__.typ": address, brand, lang
#import "../utils.typ": fit, tr
// the reach of a desktop printer is the same here as for the plates, and it is
// the printer's, not the plate's
#import "../signs/doorplate.typ": margin

#let ink = rgb("#051726")
#let ink-soft = rgb("#5a6b7c")
#let navy = rgb("#0a2540")
#let copper = rgb("#c2703d")
#let hairline = rgb("#dce3ea")

#let labels = tr((fr: ("DIRECT", "COURRIEL", "SITE"), en: ("DIRECT", "EMAIL", "WEB")), lang)

// Nothing about a door decides these, and the pack is printed before a business
// has any of them for real.
#let contact = (
  person: "Valeriy Sakharov",
  phone: "+33 4 23 50 06 40",
  email: "val@aquafix.top",
  site: "aquafix.top",
)

#let card-w = 85mm
#let card-h = 55mm

// A monogram: one drawing that reads as a logo whatever the business is called.
#let mark(size, fill) = box(width: size, height: size, {
  place(center + horizon, polygon.regular(size: size, vertices: 6, stroke: (paint: fill, thickness: size / 11)))
  place(
    center + horizon,
    text(size: size * 0.44, weight: "bold", fill: fill, top-edge: "cap-height", bottom-edge: "baseline", upper(brand.name.first())),
  )
})

#let lockup(size, fill) = grid(
  columns: 2,
  column-gutter: size * 0.42,
  align: horizon,
  mark(size * 1.25, copper), text(size: size, weight: "bold", tracking: size * 0.015, fill: fill, upper(brand.name)),
)

#let front = box(width: card-w, height: card-h, fill: navy, {
  set text(font: "Liberation Sans")
  place(center + horizon, stack(
    dir: ttb,
    spacing: 7mm,
    align(center, fit(58mm, 22pt, sz => lockup(sz, white))),
    align(center, fit(66mm, 7pt, sz => text(size: sz, weight: "medium", tracking: sz * 0.2, fill: copper, upper(brand.descriptor)))),
  ))
})

#let back(c) = box(width: card-w, height: card-h, fill: white, stroke: 0.4pt + hairline, {
  set text(font: "Liberation Sans", fill: ink)
  place(top + left, rect(width: card-w, height: 2mm, fill: copper))
  block(inset: (x: 7mm, top: 5mm), {
    mark(8mm, copper)
    v(3mm)
    text(size: 13pt, weight: "bold", c.person)
    v(3mm)
    grid(
      columns: (14mm, auto),
      column-gutter: 3mm,
      row-gutter: 1.6mm,
      align: horizon,
      ..labels
        .zip((c.phone, c.email, c.site))
        .map(((l, v)) => (
          text(size: 6pt, weight: "medium", tracking: 0.8pt, fill: ink-soft, l),
          text(size: 8.5pt, weight: "semibold", v),
        ))
        .flatten()
    )
  })
  place(bottom + left, dx: 7mm, dy: -8.5mm, line(length: card-w - 14mm, stroke: 0.4pt + hairline))
  place(bottom + left, dx: 7mm, dy: -6mm, text(size: 6.5pt, fill: ink-soft, address.street + "  ·  " + address.city))
})

// Both faces of `n` cards. A row is one card, so what comes off the guillotine is
// a front and the back that belongs to it; the grid pages itself once a column of
// them runs off the paper. Cards share their edges, so a cut frees two at once.
#let cards(n, c: contact) = {
  set page(paper: "a4", margin: margin, fill: white)
  grid(columns: (card-w, card-w), ..range(n).map(_ => (front, back(c))).flatten())
}

// A4 on whatever is in the office. Each line is set to the distance it is read
// from: the lock-up from the corridor, the number from across the room.
#let poster(c: contact) = {
  set page(paper: "a4", flipped: true, margin: 18mm, fill: white)
  set text(font: "Liberation Sans", fill: ink)
  set par(leading: 0pt, spacing: 0pt)

  align(center + horizon, block(width: 100%, {
    align(center, fit(200mm, 90pt, sz => lockup(sz, ink)))
    v(16mm)
    align(center, fit(200mm, 20pt, sz => text(size: sz, weight: "medium", tracking: sz * 0.18, fill: copper, upper(brand.descriptor))))
    v(20mm)
    align(center, fit(190mm, 66pt, sz => text(size: sz, weight: "bold", c.phone)))
    v(9mm)
    align(center, text(size: 24pt, weight: "medium", tracking: 2.2pt, fill: ink-soft, c.site))
  }))
}
