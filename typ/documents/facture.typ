// What the landlord bills the business for the door it rents. The company name
// and the postal line come from the place; a bill addressed to them there is the
// piece of paper a verifier asks for.
#import "../__main__.typ": address, brand
#import "../utils.typ": digit-code, format-date, tr
#import "bailleur.typ": coordonnees, letterhead, panel, rule, signature

#let adresse_local = address.street + ", " + address.city
#let iban = "FR76 " + digit-code((4, 4, 4, 4, 4, 3), seed: 5, luhn: false)
#let tva_taux = 20

// Cents, so the total is exact and the printed form is the only place a decimal
// point is decided. Rent, then the two lines a commercial lease adds to it.
#let lignes = (135000, 18000, 6250)

#let _money(cents, lang) = {
  let whole = str(calc.div-euclid(cents, 100))
  let frac = str(calc.rem-euclid(cents, 100))
  let sep = if lang == "fr" { "\u{00A0}" } else { "," }
  let grouped = ()
  for (i, c) in whole.clusters().rev().enumerate() {
    if i > 0 and calc.rem(i, 3) == 0 { grouped.push(sep) }
    grouped.push(c)
  }
  let n = grouped.rev().join()
  let f = if frac.len() < 2 { "0" + frac } else { frac }
  if lang == "fr" { n + "," + f + "\u{00A0}€" } else { "€" + n + "." + f }
}

#let facture(lang: "fr", date: none) = {
  // A month of rent is billed for the month it falls in.
  let debut = datetime(year: date.year(), month: date.month(), day: 1)
  let suivant = if date.month() == 12 {
    datetime(year: date.year() + 1, month: 1, day: 1)
  } else {
    datetime(year: date.year(), month: date.month() + 1, day: 1)
  }
  let fin = suivant - duration(days: 1)

  let s = tr(
    (
      fr: (
        titre: "FACTURE",
        sous_titre: "Loyer et charges locatives",
        numero: "Facture n° :",
        date: "Date :",
        echeance: "Échéance :",
        client: "Client n° :",
        facture_a: "Facturé à",
        periode: "Période facturée",
        local: "Local loué",
        colonnes: ("Désignation", "Qté", "P.U. HT", "Montant HT"),
        lignes: (
          "Loyer commercial — local en rez-de-chaussée",
          "Provision sur charges (eau, parties communes)",
          "Taxe d’enlèvement des ordures ménagères (quote-part)",
        ),
        total_ht: "Total HT",
        tva: "TVA " + str(tva_taux) + " %",
        total_ttc: "Total TTC",
        reglement: "Règlement",
        reglement_corps: [
          Par virement à réception de la facture, au compte #iban. Prière de rappeler le numéro de facture en référence du virement.
        ],
        penalites: [
          Passé l’échéance, pénalités de retard au taux de trois fois le taux d’intérêt légal, et indemnité forfaitaire pour frais de recouvrement de 40 €. Pas d’escompte pour paiement anticipé.
        ],
        signature: "Signature :",
      ),
      en: (
        titre: "INVOICE",
        sous_titre: "Rent and service charges",
        numero: "Invoice no.:",
        date: "Date:",
        echeance: "Due:",
        client: "Customer no.:",
        facture_a: "Billed to",
        periode: "Period billed",
        local: "Premises let",
        colonnes: ("Description", "Qty", "Unit net", "Net amount"),
        lignes: (
          "Commercial rent — ground-floor premises",
          "Service charge on account (water, common parts)",
          "Household waste collection tax (share)",
        ),
        total_ht: "Net total",
        tva: "VAT " + str(tva_taux) + "%",
        total_ttc: "Gross total",
        reglement: "Payment",
        reglement_corps: [
          By transfer on receipt of this invoice, to account #iban. Please quote the invoice number as the reference of the transfer.
        ],
        penalites: [
          After the due date, late payment interest runs at three times the statutory rate, together with a fixed recovery charge of €40. No discount is given for early payment.
        ],
        signature: "Signature:",
      ),
    ),
    lang,
  )

  let ht = lignes.sum()
  let tva = int(calc.round(ht * tva_taux / 100))

  set page(
    paper: "a4",
    margin: (top: 17mm, bottom: 16mm, left: 20mm, right: 20mm),
    numbering: none,
  )
  set text(font: "New Computer Modern", size: 10pt, lang: lang)
  set par(justify: true, leading: 0.58em)

  letterhead(lang)
  v(7mm)

  grid(
    columns: (1fr, auto),
    gutter: 14pt,
    align: (left + horizon, right + horizon),
    [
      #text(size: 20pt, weight: "bold")[#s.titre] \
      #v(2pt)
      #text(size: 12pt, weight: "bold")[#s.sous_titre]
    ],
    grid(
      columns: (auto, auto),
      column-gutter: 8pt,
      row-gutter: 2pt,
      align: (right, right),
      [#strong[#s.numero]], [#str(date.year())-#digit-code((4,), seed: 3, luhn: false)],
      [#strong[#s.date]], [#format-date(date, lang)],
      [#strong[#s.echeance]], [#format-date(date + duration(days: 30), lang)],
      [#strong[#s.client]], [#digit-code((5,), seed: 4, luhn: false)],
    ),
  )
  v(7mm)

  grid(
    columns: (1fr, 1fr),
    gutter: 12pt,
    align: (left, left),
    [
      #strong[#s.facture_a] \
      #v(1.5mm)
      #text(weight: "bold")[#brand.name] \
      #address.street \
      #address.city
    ],
    [
      #strong[#s.periode] \
      #v(1.5mm)
      #format-date(debut, lang) — #format-date(fin, lang) \
      #v(1.5mm)
      #strong[#s.local] #h(1fr) \
      #adresse_local
    ],
  )
  v(6mm)

  table(
    columns: (1fr, auto, auto, auto),
    align: (left, right, right, right),
    stroke: none,
    inset: (x: 5pt, y: 5pt),
    fill: (_, y) => if y == 0 { panel },
    table.header(..s.colonnes.map(strong)),
    table.hline(y: 1, stroke: 0.4pt + rule),
    ..lignes.zip(s.lignes).map(((c, label)) => (label, "1", _money(c, lang), _money(c, lang))).flatten(),
    table.hline(y: lignes.len() + 1, stroke: 0.6pt + rule),
  )
  v(4mm)

  align(right, grid(
    columns: (auto, auto),
    column-gutter: 10pt,
    row-gutter: 3pt,
    align: (right, right),
    grid.hline(y: 2, stroke: 0.4pt + rule),
    s.total_ht, _money(ht, lang),
    s.tva, _money(tva, lang),
    strong(s.total_ttc), strong(_money(ht + tva, lang)),
  ))
  v(7mm)

  strong(s.reglement)
  v(2mm)
  s.reglement_corps
  v(2mm)
  text(size: 8.5pt, s.penalites)
  v(7mm)

  grid(
    columns: (1fr, 0.92fr),
    gutter: 16pt,
    align: (left, top),
    signature(lang, s.signature), coordonnees(lang),
  )
}
