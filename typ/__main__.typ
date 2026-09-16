// What every document and plate under typ/ is drawn from. The place itself comes
// in on the command line, so nothing here names a file:
//   typst compile --root . --input place=/tmp/<place>.typ typ/to_print.typ out.pdf
#import "utils.typ": langs

#let _place = sys.inputs.at("place", default: none)
#assert(_place != none, message: "no place; compile with --input place=/tmp/<place>.typ")
#import _place: address, lang, nearby, proprietaire

#assert(lang in langs, message: repr(lang) + " is not one of " + repr(langs))
#assert.eq(address.keys().sorted(), ("city", "name", "street"))
#assert(nearby.print_my_address_n > 0, message: "no copies of the address plate asked for")
#assert(nearby.other_businesses.len() > 0, message: "no boards of other businesses to draw")
#for n in nearby.neighbours { assert.eq(n.keys().sorted(), ("name", "street")) }
