// What every document and plate under typ/ is drawn from.
#import "utils.typ": langs

#let lang = "fr"
#let proprietaire = "SCI Les Volcans"

// `name` is what the plate on the building calls the place; the documents quote
// street and city as the one line a notary would write.
#let address = (
  name: "Résidence des Landais",
  street: "23 avenue des Landais",
  city: "63100 Clermont-Ferrand",
)

#let nearby = (
  // One plaque each. A "\n" is where that plaque breaks its line, and what
  // follows is set smaller — where the trade suffix sits on a real one.
  competitors: (
    "Freeman Law Center,\nLLC",
    "CLO\nCoffee Co.",
  ),
  // Plates for the doors next door, drawn like ours and tiled the same.
  neighbours: (
    (name: "Résidence des Cézeaux", street: "25 avenue des Landais"),
  ),
  print_my_address_n: 6,
)

#assert(lang in langs, message: repr(lang) + " is not one of " + repr(langs))
#assert(nearby.print_my_address_n > 0, message: "no copies of the address plate asked for")
