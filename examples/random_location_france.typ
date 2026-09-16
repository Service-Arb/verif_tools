// One place. `typ/__main__.typ` is handed this file and checks its shape.
// Named `<business>_-_<city>_-_<branch>`, since one business gets one per door.

#let lang = "fr"
#let proprietaire = "SCI Les Volcans"

// `name` is what the plate on the building calls the place; the documents quote
// street and city as the one line a notary would write.
#let address = (
  name: "Résidence des Landais",
  street: "23 avenue des Landais",
  city: "63100 Clermont-Ferrand",
)

// The enamel blank the street plate at this door is cut from. Its height sets how
// tall the letters to cut out come off the paper; the width records the blank.
#let street_plate = (width: 50cm, height: 30cm)

// The business as its own paper calls it. For "Aquafix Plombier Chauffagiste -
// Lyon, Nord", `name` is "Aquafix" and `descriptor` is everything after it.
#let brand = (
  name: "Hexaclim",
  descriptor: "Chauffagiste - Clermont-Ferrand Sud",
  print_card_n: 1, // one card is two sides, so this many of each
  print_sheet_n: 4,
)

#let nearby = (
  // The nearest doors that carry a name of their own, whatever they sell. One
  // plaque each. A "\n" is where that plaque breaks its line, and what follows is
  // set smaller — where the trade suffix sits on a real one.
  other_businesses: (
    "Freeman Law Center,\nLLC",
    "CLO\nCoffee Co.",
  ),
  // Plates for the doors next door, drawn like ours and tiled the same.
  neighbours: (
    (name: "Résidence des Cézeaux", street: "25 avenue des Landais"),
  ),
  print_my_address_n: 3,
)
