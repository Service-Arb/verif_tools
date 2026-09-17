// This place's doors: ours and the neighbour's on plates, the other businesses on
// boards. `signs/nearby.typ` renders it on its own, `to_print.typ` in the pack.
#import "../__main__.typ": address, nearby
#import "../utils.typ": unit
#import "doorplate.typ": alone, plaque, plate

#let plates = (range(nearby.print_my_address_n).map(_ => plate(address)) + nearby.neighbours.map(plate)).map(unit)
#let boards = nearby.other_businesses.map(name => alone(plaque(name)))
