// What the user decides once, whatever brand or place a pack is for.

#let lang = "fr"

// The signs on the way to the door verification is passed at, one door sheet each.
// Each sign has `next_direction` and/or `door`, the arrow one of
// `sym.arrow.{r,l,t,b,tr,tl,br,bl}`, the text in `lang`.
#let directions = (
  (next_direction: (arrow: sym.arrow.r, text: "À droite en entrant"), door: "003"), // outer door
  (door: "003"), // block door
)
