// nix build "path:.#<place>"
// One pass through the printer, in tray order. Add to `sheets`; each entry opens
// its own page, so nothing here has to know what sits above it.
#import "__main__.typ": address, lang, proprietaire
#import "utils.typ": recent-date
#import "documents/attestation_interdiction_enseigne.typ": attestation
#import "signs/cutout.typ": letters, sheet
#import "signs/plaques.typ": boards

#let sheets = (
  sheet(letters(address.street)),
  attestation(lang: lang, proprietaire: proprietaire, date: recent-date()),
  boards,
)

#sheets.join(pagebreak(weak: true))
