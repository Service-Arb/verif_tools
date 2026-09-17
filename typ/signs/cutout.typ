// The hand-cut fallback: caps to cut out one by one and glue onto a blue
// background, for when the plate cannot be printed whole (`plate.typ`).
#import "../__main__.typ": street_plate
#import "../utils.typ": margin, unit
#import "plate.typ": cap_frac

#let cap = cap_frac * street_plate.height

#let sheet(glyphs) = unit(full_page: true, {
  assert(glyphs.len() > 0, message: "nothing to cut out")

  set page(paper: "a4", margin: margin)
  set par(leading: 0pt, spacing: 0pt)
  set text(
    font: "Liberation Sans",
    weight: "bold",
    fill: white,
    stroke: 0.2pt + black,
    top-edge: "cap-height",
    bottom-edge: "baseline",
    hyphenate: false,
  )

  // The size that makes the drawn caps exactly `cap` tall. Glyph outlines scale
  // linearly with size, so probing once lands exactly.
  context {
    let probe = 100pt
    let size = probe * (cap / measure(text(size: probe)[H]).height)
    let room = page.width - 2 * margin

    // Typst will not break inside a word, and the letters carry no spaces to break
    // at, so the rows are packed here — greedily, since the run is in reading order
    // and reordering it would stop being the name it spells.
    let rows = ((),)
    for letter in glyphs.clusters() {
      let grown = rows.last() + (letter,)
      assert(
        measure(text(size: size, letter)).width <= room,
        message: letter + " at a " + repr(cap) + " cap is wider than the " + repr(room) + " between the margins",
      )
      rows = if measure(text(size: size, grown.join())).width <= room {
        rows.slice(0, -1) + (grown,)
      } else { rows + ((letter,),) }
    }
    for row in rows { text(size: size, row.join()) + parbreak() }
  }
})
