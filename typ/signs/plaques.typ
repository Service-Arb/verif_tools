#import "../__main__.typ": address, nearby

// what a desktop printer refuses to reach, plus a lane to cut in
#let margin = 10mm
#let lane = 4mm
// two across the reachable width of A4, so both plate and plaque tile the same
#let width = 90mm
#let plaque-height = 62mm

#let plate(a) = box(
  width: width,
  height: 32mm,
  fill: gradient.linear(rgb("#dcddd6"), rgb("#c2c3bd"), angle: 100deg),
  stroke: 0.5pt + rgb("#8b8d87"),
  radius: 1mm,
  inset: 5mm,
)[
  #set align(center + horizon)
  #set par(leading: 0.55em)
  #set text(font: "Liberation Sans", size: 13pt, fill: rgb("#2a2b29"))
  #a.name \
  #a.street
]

// Quartersawn stock: the grain runs the long way of the board and the bands
// mirror, so the repeat does not read back as stripes.
#let wood = gradient.linear(rgb("#3d2617"), rgb("#573921"), rgb("#2f1c0e"), rgb("#634026"), rgb("#34200f"), angle: 86deg).repeat(7, mirror: true)
#let gold = rgb("#c9a227")
#let screw = circle(
  radius: 1.4mm,
  fill: gradient.radial(rgb("#e8d59a"), rgb("#87691f")),
  stroke: 0.3pt + rgb("#5d4a1a"),
)

#let engraved(line, size) = text(font: "Liberation Serif", size: size, fill: rgb("#f0e2b8"), tracking: 0.04em, line)
// the line after the break carries the suffix, and sits at
#let sub = 0.62

#let plaque(name) = box(width: width, height: plaque-height, fill: wood, stroke: 0.4pt + rgb("#2d1a0b"))[
  #place(top + left, dx: 3.2mm, dy: 3.2mm, screw)
  #place(top + right, dx: -3.2mm, dy: 3.2mm, screw)
  #place(bottom + left, dx: 3.2mm, dy: -3.2mm, screw)
  #place(bottom + right, dx: -3.2mm, dy: -3.2mm, screw)
  #block(width: 100%, height: 100%, inset: 6mm)[
    #rect(width: 100%, height: 100%, stroke: 1.6pt + gold, inset: 1.4mm)[
      #rect(width: 100%, height: 100%, stroke: 0.5pt + gold, inset: 4mm)[
        // Glyph outlines scale linearly with size, so probing once lands the size
        // that fills the frame exactly. Capped, or a short name comes out a slab.
        #context {
          let probe = 100pt
          let lines = name.split("\n")
          let scaled = lines.enumerate().map(((i, l)) => measure(engraved(l, probe)).width / (if i == 0 { 1.0 } else { sub }))
          let size = calc.min(30pt, probe * ((width - 26.8mm) / calc.max(..scaled)))
          set align(center + horizon)
          set par(leading: 0.4em)
          lines.enumerate().map(((i, l)) => engraved(l, size * (if i == 0 { 1.0 } else { sub }))).join(linebreak())
        }
      ]
    ]
  ]
]

#let boards = {
  set page(paper: "a4", margin: margin)
  set par(justify: false, leading: lane, spacing: lane)

  // Inline boxes wrap at the right margin and break across pages on their own; the
  // lane between them is weak, so it collapses rather than pushing a row over.
  ((address,) + nearby.neighbours).map(a => range(nearby.print_my_address_n).map(_ => plate(a))).flatten().join(h(lane, weak: true))

  // A competitor's board is the thing in the shot, so it gets a page to itself and
  // prints as large as the paper allows — 90:62 is within a hair of landscape A4
  // inside the margins, so scaling the drawn plaque up leaves almost nothing over.
  for name in nearby.competitors {
    page(
      paper: "a4",
      flipped: true,
      layout(room => scale(
        calc.min(room.width / width, room.height / plaque-height) * 100%,
        origin: top + left,
        reflow: true,
        plaque(name),
      )),
    )
  }
}
