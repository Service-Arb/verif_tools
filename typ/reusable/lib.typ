// Signs that name no place: the same one hangs on any door of any business, so
// the caller passes a language and nothing else.
#import "../utils.typ": fit, tr
#import "../signs/doorplate.typ": alone, plaque

#let _ink = rgb("#051726")
#let _ink-soft = rgb("#5a6b7c")
#let _rule = rgb("#c2703d")

#let _words = lang => tr(
  (
    fr: (main: "Réservé au personnel", sub: "Accès interdit au public"),
    en: (main: "Staff only", sub: "No public access"),
  ),
  lang,
)

// Screwed to the door: the same engraved board the neighbours' trades sit on.
#let board(lang) = {
  let w = _words(lang)
  alone(plaque(upper(w.main) + "\n" + w.sub))
}

// Taped to the glass: read from the far end of the corridor.
#let notice(lang) = {
  let w = _words(lang)
  set page(paper: "a4", flipped: true, margin: 18mm, fill: white)
  set text(font: "Liberation Sans", fill: _ink)
  set par(leading: 0pt, spacing: 0pt)

  align(center + horizon, block(width: 100%, {
    align(center, fit(240mm, 110pt, sz => text(size: sz, weight: "bold", tracking: sz * 0.02, upper(w.main))))
    v(12mm)
    line(length: 100%, stroke: 2.5pt + _rule)
    v(12mm)
    align(center, fit(200mm, 30pt, sz => text(size: sz, weight: "medium", tracking: sz * 0.14, fill: _ink-soft, upper(w.sub))))
  }))
}
