// This place's doors: ours and the neighbour's on plates, the other businesses on
// boards. `signs/nearby.typ` renders it on its own, `to_print.typ` in the pack.
#import "../__main__.typ": address, nearby
#import "doorplate.typ": alone, margin, plaque, plate, width

#let boards = {
  set page(paper: "a4", margin: margin)

  // Tiled edge to edge, so one cut down a seam frees both plates it runs between.
  grid(columns: (width, width), ..range(nearby.print_my_address_n).map(_ => plate(address)) + nearby.neighbours.map(plate))

  nearby.other_businesses.map(name => alone(plaque(name))).join()
}
