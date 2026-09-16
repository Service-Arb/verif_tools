// Cap height of the street-plate lettering, measured off a Lyon plaque (50x30cm
// enamel, "AVENUE THIERS", 6eme arrt): the caps span 0.211 of the plate's height.
// Override to calibrate against a plate you actually hold a ruler to.
#let cap = eval(sys.inputs.at("cap", default: "6.3cm"))
// what a desktop printer refuses to reach, plus a lane to cut in
#let margin = 10mm
#let lane = 4mm

// What a letter sheet keeps of a name: the caps, unaccented, in reading order.
#let dropped = "0123456789 -'.,"
#let letters(s) = {
  str
    .normalize(upper(s), form: "nfd")
    .codepoints()
    .filter(c => {
      let p = c.to-unicode()
      if 0x300 <= p and p <= 0x36f { return false }
      if 0x41 <= p and p <= 0x5a { return true }
      assert(c in dropped, message: repr(c) + " in " + repr(s) + " is neither a cap nor one of " + repr(dropped))
      false
    })
    .join()
}

#let sheet(glyphs) = {
  assert(glyphs.len() > 0, message: "nothing to cut out")

  set page(paper: "a4", margin: margin)
  set par(leading: 0pt, spacing: lane)
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
}
