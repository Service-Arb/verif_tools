// typst compile --root . --input place=/tmp/<place>.typ typ/brand/__main__.typ out.pdf
#import "lib.typ": back, card-h, card-w, contact, front, poster

#poster()
#page(width: card-w, height: card-h, margin: 0pt, front)
#page(width: card-w, height: card-h, margin: 0pt, back(contact))
