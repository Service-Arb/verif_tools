// typst compile --root .. documents/__main__.typ out.pdf
#import "/utils.typ": langs, recent-date
#import "attestation_interdiction_enseigne.typ": attestation

#let lang = "fr"
#let proprietaire = "SCI Les Volcans"
#let date = recent-date()

#assert(lang in langs, message: repr(lang) + " is not one of " + repr(langs))

#attestation(lang: lang, proprietaire: proprietaire, date: date)
