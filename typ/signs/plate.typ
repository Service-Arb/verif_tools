// The street plate, drawn whole at its real size and windowed onto A4. A drawing
// rather than a sheet, so the blank comes in as arguments and nothing here names
// a place. Two stages, in this order: solve the plate in plate coordinates, then
// cut that same drawing into sheets.
#import "../utils.typ": unit

#let blue = rgb("#222D5A")

// Measured off a Lyon plaque ("AVENUE THIERS", 6eme arrt): the caps span 0.211 of
// the plate's height, whatever blank the plate is cut from.
#let cap_frac = 0.211

// `typst compile --input bleed=0.4 …`; a nix build takes no argument and keeps
// the constant.
#let _mm(key, fallback) = {
  let v = sys.inputs.at(key, default: none)
  if v == none { fallback } else { float(v) * 1mm }
}

#let paper = 210mm // A4's short side, the plate's width runs across it
#let bleed = _mm("bleed", 0.6mm) // what the printer leaves white at a paper edge
#let overlap = _mm("overlap", 20mm) // how much of the sheet below the one above covers

#let _dropped = "0123456789 '.,"

// The caps of a name, split into the words a line can break between. Hyphens stay
// a glyph, so CLERMONT-FERRAND neither loses its hyphen nor breaks across lines.
#let words(s) = {
  str
    .normalize(upper(s), form: "nfd")
    .codepoints()
    .map(c => {
      let p = c.to-unicode()
      if 0x300 <= p and p <= 0x36f { return "" }
      if (0x41 <= p and p <= 0x5a) or c == "-" { return c }
      assert(c in _dropped, message: repr(c) + " in " + repr(s) + " is neither a cap nor one of " + repr(_dropped))
      if c == " " { " " } else { "" }
    })
    .join()
    .split(" ")
    .filter(w => w != "")
}

#let _glyphs(size, s) = text(
  font: "Liberation Sans",
  weight: "bold",
  fill: white,
  top-edge: "cap-height",
  bottom-edge: "baseline",
  hyphenate: false,
  size: size,
  s,
)

// A line's box is exactly a cap tall, so the block L lines make is
// cap * (L + (L - 1) * _leading).
#let _leading = 0.3

// Every way of breaking the words into consecutive lines, scored by the cap it
// affords. Call inside `context`; the widths are arithmetic on one probe measure.
#let layout(name, width, height) = {
  let ws = words(name)
  assert(ws.len() > 0, message: repr(name) + " spells nothing to put on a plate")
  assert(ws.len() <= 8, message: repr(name) + " is " + str(ws.len()) + " words; the solve enumerates 2^(n-1) breaks")

  let probe = 100pt
  let capratio = measure(_glyphs(probe, "H")).height / probe
  let space = measure(_glyphs(probe, "A A")).width - measure(_glyphs(probe, "AA")).width
  let drawn = ws.map(w => measure(_glyphs(probe, w)).width)

  let best = none
  for mask in range(int(calc.pow(2, ws.len() - 1))) {
    let lines = ((ws.at(0),),)
    let widths = (drawn.at(0),)
    for i in range(1, ws.len()) {
      if calc.odd(int(mask / calc.pow(2, i - 1))) {
        lines.push((ws.at(i),))
        widths.push(drawn.at(i))
      } else {
        lines.at(-1).push(ws.at(i))
        widths.at(-1) += space + drawn.at(i)
      }
    }

    let n = lines.len()
    let span = n + (n - 1) * _leading
    let maxw = calc.max(..widths)
    let cap = calc.min(cap_frac * height, probe * capratio * (width / maxw), height / span)
    if best == none or cap > best.cap or (cap == best.cap and n < best.lines.len()) {
      best = (
        lines: lines.map(l => l.join(" ")),
        cap: cap,
        size: cap / capratio,
        width: maxw * (cap / (probe * capratio)),
        height: cap * span,
      )
    }
  }
  best
}

#let _plate(name, width, height) = context {
  let l = layout(name, width, height)
  block(width: width, height: height, fill: blue, {
    set align(center + horizon)
    set par(leading: _leading * l.cap, spacing: 0pt)
    l.lines.map(line => _glyphs(l.size, line)).join(linebreak())
  })
}

#let _mark(stroke) = line(angle: 90deg, length: 4mm, stroke: stroke)

// The same drawing windowed onto as many A4 sheets as it spans. Cut the white
// strip off each sheet's trailing edge, lay each over the next, glue.
#let sheets(name, width: none, height: none) = {
  assert(width != none and height != none, message: "a plate needs the blank it is cut from")
  let advance = paper - bleed - overlap
  let n = calc.max(1, 1 + calc.ceil((width - paper + 2 * bleed) / advance))
  let drawn = _plate(name, width, height)
  let hair = 0.2pt + white

  range(n).map(k => {
    let origin = -bleed + k * advance
    unit(
      full_page: true,
      page(
        paper: "a4",
        margin: 0pt,
        fill: blue,
        block(width: 100%, height: 100%, clip: true, {
          place(top + left, dx: -origin, dy: -(height - 297mm) / 2, drawn)
          // where the sheet above lands, so it ends up underneath it
          if k > 0 {
            place(top + left, dx: overlap, line(angle: 90deg, length: 100%, stroke: hair))
            place(top + left, dx: overlap + 1.5mm, dy: 1.5mm, _glyphs(8pt, str(k + 1)))
          }
          if k == n - 1 {
            let right = width - origin
            place(top + left, dx: right, dy: bleed, _mark(hair))
            place(bottom + left, dx: right, dy: -bleed - 4mm, _mark(hair))
          }
        }),
      ),
    )
  })
}
