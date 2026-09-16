// typst compile --root . --input place=/tmp/<place>.typ typ/documents/__main__.typ out.pdf
#import "../__main__.typ": lang, proprietaire
#import "../utils.typ": recent-date
#import "attestation_interdiction_enseigne.typ": attestation

#attestation(lang: lang, proprietaire: proprietaire, date: recent-date())
