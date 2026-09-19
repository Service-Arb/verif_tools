#import "/examples/brands/aquafix.typ": brand as aquafix
#import "/examples/brands/serrunova.typ": brand as serrunova
#import "/examples/brands/aerotherm63.typ": brand as aerotherm
#import "/examples/brands/toitvolcan.typ": brand as toitvolcan

#let lang = "fr"
#let proprietaire = "SCI Les Volcans"
#let address = (
  name: "CMF 003",
  street: "11 Rue de Médicis",
  city: "63000 Clermont-Ferrand",
)
#let street_plate = (width: 50cm, height: 30cm)
#let brands = (
  aquafix
    + (
      descriptor: "Plombier Chauffagiste - Clermont-Ferrand",
      phone: none,
      print_card_n: 2,
      print_sheet_n: 4,
    ),
  serrunova
    + (
      descriptor: "Serrurier - Clermont-Ferrand",
      phone: none,
      print_card_n: 2,
      print_sheet_n: 4,
    ),
  aerotherm
    + (
      descriptor: "Climatisation & Chauffage - Clermont-Ferrand",
      phone: none,
      print_card_n: 2,
      print_sheet_n: 4,
    ),
  toitvolcan
    + (
      descriptor: "Couvreur - Clermont-Ferrand",
      phone: none,
      print_card_n: 2,
      print_sheet_n: 4,
    ),
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
