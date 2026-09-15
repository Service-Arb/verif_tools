#let adresse_bailleur = "12 rue des Carmes, 63000 Clermont-Ferrand, France"
#let date_attestation = "10 septembre 2026"
#let ville = "Clermont-Ferrand"
#let adresse_local = "23 avenue des Landais, 63100 Clermont-Ferrand"
#let proprietaire = "SCI Les Volcans"
#let forme_juridique = "Société civile immobilière"
#let telephone = "04 73 00 00 00"
#let email = "contact@lesvolcans-immo.fr"
#let siren = "123 456 789"
#let signataire = "Jean Dupont"
#let qualite = "Gérant"

#set page(
  paper: "a4",
  margin: (top: 17mm, bottom: 16mm, left: 20mm, right: 20mm),
  numbering: none,
)
#set text(font: "New Computer Modern", size: 10pt, lang: "fr")
#set par(justify: true, leading: 0.58em)

#let ink = rgb("202124")
#let muted = rgb("666666")
#let rule = rgb("B8BDC5")
#let panel = rgb("F4F5F7")

#block(fill: none)[
  #grid(
    columns: (1fr, auto),
    gutter: 12pt,
    align: (left, top),
    [
      #text(size: 16pt, weight: "bold")[#proprietaire] \
      #text(size: 9pt)[#forme_juridique] \
      #text(size: 9pt)[#adresse_bailleur] \
    ],
    [
      #align(right)[
        #text(size: 8pt, weight: "bold", tracking: 0.8pt)[CONTACT] \
        #text(size: 9pt)[Tél. : #telephone] \
        #text(size: 9pt)[Email : #email] \
        #text(size: 9pt)[SIREN : #siren]
      ]
    ],
  ),
  )
  #v(6mm)
  #line(length: 100%, stroke: 0.6pt + rule)
  #v(7mm)

  #align(center)[
    #text(size: 20pt, weight: "bold")[ATTESTATION] \
    #v(2pt)
    #text(size: 13pt, weight: "bold")[Interdiction d’enseigne permanente sur la façade]
  ]
  #v(6mm)

  #grid(
    columns: (auto, 1fr),
    column-gutter: 8pt,
    row-gutter: 2pt,
    [#strong[Date :]], [#date_attestation],
    [#strong[Objet :]], [Absence d’autorisation d’enseigne permanente],
    [#strong[Local concerné :]], [#adresse_local],
  )
  #v(6mm)

  Madame, Monsieur,
  #v(3mm)

  Je soussigné, #signataire, #qualite de la #proprietaire, propriétaire de l’immeuble situé au #adresse_local, atteste par la présente que le bail commercial conclu avec le locataire n’autorise pas l’installation d’une enseigne permanente sur la façade de l’immeuble.
  #v(3mm)

  Conformément aux clauses du bail et au règlement de copropriété (le cas échéant), toute installation d’enseigne, de panneau ou de support publicitaire visible depuis l’extérieur du bâtiment est interdite sans accord écrit préalable du propriétaire.
  #v(3mm)

  Cette attestation est délivrée à la demande de l’intéressé pour servir et valoir ce que de droit.
  #v(5mm)

  Fait à #ville, le #date_attestation.
  #v(7mm)

  #grid(
    columns: (1fr, 0.92fr),
    gutter: 16pt,
    align: (left, top),
    [
      #text(weight: "bold")[Signature :] \
      #v(3mm)
      #text(font: "Nanum Pen", size: 24pt, fill: rgb("182b55"), baseline: -2pt)[Jean Dupont] \
      #line(length: 44mm, stroke: 0.7pt + rgb("182b55")) \
      #v(3mm)
      #text(weight: "bold")[#signataire] \
      #text()[#qualite] \
      #text()[#proprietaire]
    ],
    [
      #box(fill: panel, inset: 6pt, width: 100%)[
        #text(size: 9pt)[
          #strong[Coordonnées du bailleur / gestionnaire] \
          #v(2pt)
          #proprietaire \
          #adresse_bailleur \
          Tél. : #telephone \
          Email : #email \
          SIREN : #siren
        ]
      ]
    ],
  )
]
