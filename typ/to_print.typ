// nix build "path:.#<place>"
// One pass through the printer. Add to `sheets`; `pack` lays what wants a page of
// its own first and tiles the rest onto what is left, so nothing here has to know
// what sits above it.
#import "__main__.typ": address, brands, directions, lang, street_plate
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
    .map(brand => {
      let door = (descriptor: brand.descriptor, street: address.street, city: address.city)
      (
        ..directions.map(sign => poster(brand, lang, false, door: door, sign: sign)),
        poster(brand, lang, false, door: door),
        poster(brand, lang, true, door: door),
        ..cards(brand, brand.print_card_n - 1, lang, door: door),
        ..cards(brand, 1, lang),
      )
    })
    .flatten()
)

#pack((..place_sheets, ..brand_sheets))
