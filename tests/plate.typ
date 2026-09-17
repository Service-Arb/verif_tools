// typst compile --root . tests/plate.typ -f pdf /dev/null
#import "../typ/signs/plate.typ": cap_frac, layout, sheets, words

#assert.eq(words("23 avenue des Landais"), ("AVENUE", "DES", "LANDAIS"))
#assert.eq(words("Résidence"), ("RESIDENCE",))
#assert.eq(words("Clermont-Ferrand, 1er"), ("CLERMONT-FERRAND", "ER"))

#context {
  let plate = layout("36 rue des Chanelles", 50cm, 30cm)
  assert.eq(plate.lines, ("RUE DES", "CHANELLES"))

  // a name short enough keeps the cap a plate this tall is cut to
  assert.eq(layout("rue Neuve", 50cm, 30cm).cap, cap_frac * 30cm)

  // and one too long for that shrinks, but never past the blank
  for name in ("36 rue des Chanelles", "rue Neuve", "avenue du Marechal de Lattre de Tassigny") {
    let l = layout(name, 50cm, 30cm)
    assert(l.cap <= cap_frac * 30cm, message: name + " solves past the plate's cap")
    assert(l.width <= 50cm, message: name + " draws " + repr(l.width) + " wide on a 50cm plate")
    assert(l.height <= 30cm, message: name + " draws " + repr(l.height) + " tall on a 30cm plate")
  }
}

#let n(width) = sheets("36 rue des Chanelles", width: width, height: 30cm).len()
#assert.eq(n(18.8cm), 1)
#assert.eq(n(50cm), 3)
#assert.eq(n(100cm), 6)
