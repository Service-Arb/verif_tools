#import "/examples/brands/aerotherm63.typ": brand as _brand
#let lang = "fr"
#let proprietaire = "SCI Les Volcans"
#let address = (
  name: "CMF 003",
  street: "11 Rue de Médicis",
  city: "63000 Clermont-Ferrand",
)
#let street_plate = (width: 50cm, height: 30cm)
#let brand = (
  _brand
    + (
      descriptor: "Climatisation & Chauffage - Clermont-Ferrand",
      phone: none,
      print_card_n: 2,
      print_sheet_n: 4,
    )
)
#let nearby = (
  other_businesses: (
    "Le Doyenné de l'Oradou\nÉquipement social",
    "Garage Lafayette Auto\nRéparation automobile",
    "C2i\nInformatique",
  ),
  neighbours: (),
  print_my_address_n: 3,
)
