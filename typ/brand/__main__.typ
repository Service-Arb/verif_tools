// typst compile --root . --input place=/tmp/<place>.typ typ/brand/__main__.typ out.pdf
#import "../utils.typ": pack
#import "lib.typ": cards, poster
#pack((poster(),) + cards(1))
