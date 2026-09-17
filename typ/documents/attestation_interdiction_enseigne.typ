#import "../__main__.typ": address, proprietaire
#import "../utils.typ": format-date, tr, unit
#import "bailleur.typ": coordonnees, letterhead, signataire, signature, ville

#let adresse_local = address.street + ", " + address.city

#let attestation(lang: "fr", date: none) = unit(full_page: true, {
  let s = tr(
    (
      fr: (
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
      ),
      en: (
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

  letterhead(lang)
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
    signature(s.signature), coordonnees(lang),
  )
})
