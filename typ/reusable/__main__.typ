// typst compile --root . typ/reusable/__main__.typ out.pdf
// No place, so no language either: every sign in every language it knows, and
// the page you want is the one you print.
#import "../utils.typ": langs
#import "lib.typ": board, notice

#langs.map(lang => (board(lang), notice(lang))).flatten().join(pagebreak(weak: true))
