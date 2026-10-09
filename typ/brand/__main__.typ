// typst compile --root . --input place=/tmp/<place>.typ typ/brand/__main__.typ out.pdf
#import "../__main__.typ": address, brands, lang
#import "../utils.typ": pack
#import "lib.typ": cards, poster

#let brand = brands.first()
#let door = (descriptor: brand.descriptor, street: address.street, city: address.city)
#pack((poster(brand, lang, false, door: door),) + cards(brand, 1, lang, door: door))
