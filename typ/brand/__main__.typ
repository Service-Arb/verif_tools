// typst compile --root . --input place=/tmp/<place>.typ typ/brand/__main__.typ out.pdf
#import "../__main__.typ": brands
#import "../utils.typ": pack
#import "lib.typ": cards, poster

#let brand = brands.first()
#pack((poster(brand),) + cards(brand, 1))
