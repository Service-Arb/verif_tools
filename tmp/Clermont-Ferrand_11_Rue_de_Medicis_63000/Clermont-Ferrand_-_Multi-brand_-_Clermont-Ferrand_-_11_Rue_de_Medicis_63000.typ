#import "/examples/brands/aquafix.typ": brand as aquafix
#import "/examples/brands/serrunova.typ": brand as serrunova
#import "/examples/brands/aerotherm63.typ": brand as aerotherm
#import "/examples/brands/toitvolcan.typ": brand as toitvolcan

#let address = (
  name: "CMF 003",
  street: "11 Rue de Médicis",
  city: "63000 Clermont-Ferrand",
)
#let brands = (
  aquafix
    + (
      descriptor: "Plombier Chauffagiste - Clermont-Ferrand",
      phone: none,
    ),
  serrunova
    + (
      descriptor: "Serrurier - Clermont-Ferrand",
      phone: none,
    ),
  aerotherm
    + (
      descriptor: "Climatisation & Chauffage - Clermont-Ferrand",
      phone: none,
    ),
  toitvolcan
    + (
      descriptor: "Couvreur - Clermont-Ferrand",
      phone: none,
    ),
)
#let nearby = (
  other_businesses: (
    "Le Doyenné de l'Oradou\nÉquipement social",
    "Garage Lafayette Auto\nRéparation automobile",
    "C2i\nInformatique",
  ),
  neighbours: (),
)
