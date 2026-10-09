// What the user decides once, whatever brand or place a pack is for.

#let lang = "fr"
#let proprietaire = "SCI Les Volcans"

// The blank the street plate is cut from: how tall its letters are and how many A4 it spans.
#let street_plate = (width: 50cm, height: 30cm)

#let print_card_n = 2 // per brand, one card is two sides; one names no door
#let print_my_address_n = 3

// The signs on the way to the door verification is passed at, one door sheet each.
// Each sign has `next_direction` and/or `door`, the arrow one of
// `sym.arrow.{r,l,t,b,tr,tl,br,bl}`, the text in `lang`.
#let directions = (
  (next_direction: (arrow: sym.arrow.r, text: "À droite en entrant"), door: "003"), // outer door
  (door: "003"), // block door
)
