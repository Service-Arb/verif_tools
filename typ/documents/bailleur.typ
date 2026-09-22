// The landlord as their own paper has them. The place file names them; everything
// below is the letterhead that the same name signs every sheet with, so two
// documents in one envelope agree on the address, the SIREN and the hand.
#import "../__main__.typ": proprietaire
#import "../utils.typ": digit-code, tr

#let forme_juridique = "Société civile immobilière"
#let adresse = "12 rue des Carmes, 63000 Clermont-Ferrand, France"
#let ville = "Clermont-Ferrand"
#let telephone = "04 73 00 00 00"
#let email = "contact@lesvolcans-immo.fr"
#let siren = sys.inputs.at("siren", default: digit-code((3, 3, 3)))
#metadata(siren) <siren>
#let signataire = "Jean Dupont"

#let rule = rgb("B8BDC5")
#let panel = rgb("F4F5F7")

#let _words = lang => tr(
  (
    fr: (contact: "CONTACT", tel: "Tél. : ", colon: " : ", panneau: "Coordonnées du bailleur / gestionnaire"),
    en: (contact: "CONTACT", tel: "Phone: ", colon: ": ", panneau: "Landlord / manager contact details"),
  ),
  lang,
)

#let letterhead(lang) = {
  let w = _words(lang)
  grid(
    columns: (1fr, auto),
    gutter: 12pt,
    align: (left, top),
    [
      #text(size: 16pt, weight: "bold")[#proprietaire] \
      #text(size: 9pt)[#forme_juridique] \
      #text(size: 9pt)[#adresse] \
    ],
    align(right)[
      #text(size: 8pt, weight: "bold", tracking: 0.8pt)[#w.contact] \
      #text(size: 9pt)[#w.tel#telephone] \
      #text(size: 9pt)[Email#w.colon#email] \
      #text(size: 9pt)[SIREN#w.colon#siren]
    ],
  )
  v(6mm)
  line(length: 100%, stroke: 0.6pt + rule)
}

#let coordonnees(lang) = {
  let w = _words(lang)
  box(fill: panel, inset: 6pt, width: 100%)[
    #text(size: 9pt)[
      #strong[#w.panneau] \
      #v(2pt)
      #proprietaire \
      #adresse \
      #w.tel#telephone \
      Email#w.colon#email \
      SIREN#w.colon#siren
    ]
  ]
}

// The scan carries the name and the qualité under the hand, so nothing is set
// under it but who the hand signs for.
#let signature(label) = [
  #text(weight: "bold")[#label] \
  #v(1mm)
  #image("/assets/signature.png", width: 42mm) \
  #v(1mm)
  #text()[#proprietaire]
]
