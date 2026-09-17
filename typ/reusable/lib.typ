// Signs that name no place: the same one hangs on any door of any business, so
// the caller passes a language and nothing else.
#import "../utils.typ": fit, tr, unit

// ISO 7010 safety red, and the near-black signage is printed in rather than the
// paper's own black.
#let _red = rgb("#c8102e")
#let _ink = rgb("#1a1a1a")

#let _words = lang => tr(
  (
    fr: (main: "Réservé au personnel", sub: "Accès interdit au public"),
    en: (main: "Staff only", sub: "No public access"),
  ),
  lang,
)

// The general prohibition sign is a red ring and a bar across it, and carries
// whatever the words underneath say it forbids.
#let _disc(size) = box(width: size, height: size, {
  place(center + horizon, circle(radius: size / 2, stroke: (paint: _red, thickness: size * 0.125)))
  place(center + horizon, rotate(45deg, rect(width: size * 0.82, height: size * 0.125, fill: _red)))
})

#let notice(lang) = unit(full_page: true, {
  let w = _words(lang)
  set page(paper: "a4", margin: 20mm, fill: white)
  set text(font: "Liberation Sans", fill: _ink)
  set par(leading: 0pt, spacing: 0pt)

  align(center + horizon, block(width: 100%, {
    align(center, _disc(70mm))
    v(18mm)
    align(center, fit(170mm, 52pt, sz => text(size: sz, weight: "bold", upper(w.main))))
    v(8mm)
    align(center, fit(150mm, 20pt, sz => text(size: sz, weight: "regular", w.sub)))
  }))
})
