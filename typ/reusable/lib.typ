// Signs that name no place: any door of any business hangs the same one, so the
// caller passes the language and nothing else.
#import "../utils.typ": tr
#import "../signs/plaques.typ": plaque, plaque-height, width
#import "../brand/lib.typ": copper, fit, ink, ink-soft

#let _words = lang => tr(
  (
    fr: (main: "Réservé au personnel", sub: "Accès interdit au public"),
    en: (main: "Staff only", sub: "No public access"),
  ),
  lang,
)

// Screwed to the door: the same engraved board the neighbours' trades sit on,
// scaled to what the paper allows so it comes off at door size.
#let board(lang) = {
  let w = _words(lang)
  set page(paper: "a4", flipped: true)
  layout(room => scale(
    calc.min(room.width / width, room.height / plaque-height) * 100%,
    origin: top + left,
    reflow: true,
    plaque(upper(w.main) + "\n" + w.sub),
  ))
}

// Taped to the glass: read from the far end of the corridor.
#let notice(lang) = {
  let w = _words(lang)
  set page(paper: "a4", flipped: true, margin: 18mm, fill: white)
  set text(font: "Liberation Sans", fill: ink)
  set par(leading: 0pt, spacing: 0pt)

  align(center + horizon, block(width: 100%, {
    align(center, fit(240mm, 110pt, sz => text(size: sz, weight: "bold", tracking: sz * 0.02, upper(w.main))))
    v(12mm)
    line(length: 100%, stroke: 2.5pt + copper)
    v(12mm)
    align(center, fit(200mm, 30pt, sz => text(size: sz, weight: "medium", tracking: sz * 0.14, fill: ink-soft, upper(w.sub))))
  }))
}
