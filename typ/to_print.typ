// nix build "path:.#<place>"
// One pass through the printer. Add to `sheets`; `pack` lays what wants a page of
// its own first and tiles the rest onto what is left, so nothing here has to know
// what sits above it.
#import "__main__.typ": address, brands, lang, street_plate
#import "utils.typ": pack, recent-date
#import "brand/lib.typ": cards, poster
#import "documents/attestation_interdiction_enseigne.typ": attestation
#import "documents/facture.typ": facture
#import "signs/plate.typ": sheets as plate_sheets
#import "signs/plaques.typ": boards, plates

#let place_sheets = (
  ..plate_sheets(address.street, ..street_plate),
  attestation(lang: lang, date: recent-date()),
  facture(lang: lang, date: recent-date(seed: 1)),
  ..boards,
  ..plates,
)

#let brand_sheets = (
  brands
    .map(brand => (
      ..range(brand.print_sheet_n).map(_ => poster(brand)),
      ..cards(brand, brand.print_card_n),
    ))
    .flatten()
)

#pack((..place_sheets, ..brand_sheets))
