#import "../utils.typ": digit-code, format-date, tr

#let adresse_bailleur = "12 rue des Carmes, 63000 Clermont-Ferrand, France"
#let ville = "Clermont-Ferrand"
#let adresse_local = "23 avenue des Landais, 63100 Clermont-Ferrand"
#let forme_juridique = "Société civile immobilière"
#let telephone = "04 73 00 00 00"
#let email = "contact@lesvolcans-immo.fr"
#let siren = digit-code((3, 3, 3))
#let signataire = "Jean Dupont"

#let attestation(lang: "fr", proprietaire: none, date: none) = {
  let s = tr(
    (
      fr: (
        qualite: "Gérant",
        contact: "CONTACT",
        tel: "Tél. : " + telephone,
        colon: " : ",
        titre: "ATTESTATION",
        sous_titre: "Interdiction d’enseigne permanente sur la façade",
        date: "Date :",
        objet: "Objet :",
        objet_valeur: "Absence d’autorisation d’enseigne permanente",
        local: "Local concerné :",
        salutation: "Madame, Monsieur,",
        corps: [
          Je soussigné, #signataire, Gérant de la #proprietaire, propriétaire de l’immeuble situé au #adresse_local, atteste par la présente que le bail commercial conclu avec le locataire n’autorise pas l’installation d’une enseigne permanente sur la façade de l’immeuble.
        ],
        clauses: [
          Conformément aux clauses du bail et au règlement de copropriété (le cas échéant), toute installation d’enseigne, de panneau ou de support publicitaire visible depuis l’extérieur du bâtiment est interdite sans accord écrit préalable du propriétaire.
        ],
        delivrance: [
          Cette attestation est délivrée à la demande de l’intéressé pour servir et valoir ce que de droit.
        ],
        fait: [Fait à #ville, le #format-date(date, lang).],
        signature: "Signature :",
        panneau: "Coordonnées du bailleur / gestionnaire",
      ),
      en: (
        qualite: "Manager",
        contact: "CONTACT",
        tel: "Phone: " + telephone,
        colon: ": ",
        titre: "CERTIFICATE",
        sous_titre: "Permanent façade signage not permitted",
        date: "Date:",
        objet: "Subject:",
        objet_valeur: "No authorisation for permanent signage",
        local: "Premises concerned:",
        salutation: "Dear Sir or Madam,",
        corps: [
          I, the undersigned, #signataire, Manager of #proprietaire, owner of the building located at #adresse_local, hereby certify that the commercial lease entered into with the tenant does not authorise the installation of permanent signage on the façade of the building.
        ],
        clauses: [
          Under the terms of the lease and of the co-ownership rules where they apply, the installation of any sign, panel or advertising support visible from outside the building is prohibited without the prior written consent of the owner.
        ],
        delivrance: [
          This certificate is issued at the request of the party concerned, to serve as and where required.
        ],
        fait: [Done at #ville, on #format-date(date, lang).],
        signature: "Signature:",
        panneau: "Landlord / manager contact details",
      ),
    ),
    lang,
  )

  set page(
    paper: "a4",
    margin: (top: 17mm, bottom: 16mm, left: 20mm, right: 20mm),
    numbering: none,
  )
  set text(font: "New Computer Modern", size: 10pt, lang: lang)
  set par(justify: true, leading: 0.58em)

  let rule = rgb("B8BDC5")
  let panel = rgb("F4F5F7")

  grid(
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
        #text(size: 8pt, weight: "bold", tracking: 0.8pt)[#s.contact] \
        #text(size: 9pt)[#s.tel] \
        #text(size: 9pt)[Email#s.colon#email] \
        #text(size: 9pt)[SIREN#s.colon#siren]
      ]
    ],
  )
  v(6mm)
  line(length: 100%, stroke: 0.6pt + rule)
  v(7mm)

  align(center)[
    #text(size: 20pt, weight: "bold")[#s.titre] \
    #v(2pt)
    #text(size: 13pt, weight: "bold")[#s.sous_titre]
  ]
  v(6mm)

  grid(
    columns: (auto, 1fr),
    column-gutter: 8pt,
    row-gutter: 2pt,
    [#strong[#s.date]], [#format-date(date, lang)],
    [#strong[#s.objet]], [#s.objet_valeur],
    [#strong[#s.local]], [#adresse_local],
  )
  v(6mm)

  s.salutation
  v(3mm)

  s.corps
  v(3mm)

  s.clauses
  v(3mm)

  s.delivrance
  v(5mm)

  s.fait
  v(7mm)

  grid(
    columns: (1fr, 0.92fr),
    gutter: 16pt,
    align: (left, top),
    [
      #text(weight: "bold")[#s.signature] \
      #v(1mm)
      #image("signature.png", width: 42mm) \
      #v(2mm)
      #text(weight: "bold")[#signataire] \
      #text()[#s.qualite] \
      #text()[#proprietaire]
    ],
    [
      #box(fill: panel, inset: 6pt, width: 100%)[
        #text(size: 9pt)[
          #strong[#s.panneau] \
          #v(2pt)
          #proprietaire \
          #adresse_bailleur \
          #s.tel \
          Email#s.colon#email \
          SIREN#s.colon#siren
        ]
      ]
    ],
  )
}
