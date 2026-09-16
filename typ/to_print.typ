// nix build "path:.#<place>"
// One pass through the printer, in tray order. Add to `sheets`; each entry opens
// its own page, so nothing here has to know what sits above it.
#import "__main__.typ": address, brand, lang
#import "utils.typ": recent-date
#import "brand/lib.typ": cards, poster
#import "documents/attestation_interdiction_enseigne.typ": attestation
#import "documents/facture.typ": facture
#import "signs/cutout.typ": letters, sheet
#import "signs/plaques.typ": boards

#let sheets = (
  sheet(letters(address.street)),
  attestation(lang: lang, date: recent-date()),
  facture(lang: lang, date: recent-date(seed: 1)),
  boards,
  cards(brand.print_card_n),
  ..range(brand.print_sheet_n).map(_ => poster()),
)

#sheets.join(pagebreak(weak: true))
