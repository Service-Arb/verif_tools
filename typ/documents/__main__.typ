// typst compile --root . --input place=/tmp/<place>.typ typ/documents/__main__.typ out.pdf
#import "../__main__.typ": lang
#import "../utils.typ": pack, recent-date
#import "attestation_interdiction_enseigne.typ": attestation
#import "facture.typ": facture

#pack((
  attestation(lang: lang, date: recent-date()),
  facture(lang: lang, date: recent-date(seed: 1)),
))
