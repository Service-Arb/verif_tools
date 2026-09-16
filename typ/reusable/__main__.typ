// typst compile --root . --input place=/tmp/<place>.typ typ/reusable/__main__.typ out.pdf
#import "../__main__.typ": lang
#import "lib.typ": board, notice

#(board(lang), notice(lang)).join(pagebreak(weak: true))
