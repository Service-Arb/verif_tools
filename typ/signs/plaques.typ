// This place's doors: ours and the neighbour's on plates, the other businesses on
// boards. `signs/nearby.typ` renders it on its own, `to_print.typ` in the pack.
#import "../__main__.typ": address, nearby
#import "doorplate.typ": alone, lane, margin, plaque, plate

#let boards = {
  set page(paper: "a4", margin: margin)
  set par(justify: false, leading: lane, spacing: lane)

  // Inline boxes wrap at the right margin and break across pages on their own; the
  // lane between them is weak, so it collapses rather than pushing a row over.
  ((address,) + nearby.neighbours).map(a => range(nearby.print_my_address_n).map(_ => plate(a))).flatten().join(h(lane, weak: true))

  nearby.other_businesses.map(name => alone(plaque(name))).join()
}
