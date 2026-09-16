// typst compile --root . --input place=/tmp/<place>.typ typ/documents/__main__.typ out.pdf
#import "../__main__.typ": lang
#import "../utils.typ": recent-date
#import "attestation_interdiction_enseigne.typ": attestation
#import "facture.typ": facture

#(
  attestation(lang: lang, date: recent-date()),
  facture(lang: lang, date: recent-date(seed: 1)),
).join(pagebreak(weak: true))
