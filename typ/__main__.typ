// What every document and plate under typ/ is drawn from. The place itself comes
// in on the command line, so nothing here names a file:
//   typst compile --root . --input place=/tmp/<place>.typ typ/to_print.typ out.pdf
#import "utils.typ": langs

#let _place = sys.inputs.at("place", default: none)
#assert(_place != none, message: "no place; compile with --input place=/tmp/<place>.typ")
#import _place: address, brand, lang, nearby, proprietaire, street_plate

#assert(lang in langs, message: repr(lang) + " is not one of " + repr(langs))
#assert.eq(address.keys().sorted(), ("city", "name", "street"))
#assert.eq(street_plate.keys().sorted(), ("height", "width"))
#for (k, v) in street_plate { assert(type(v) == length, message: "street_plate." + k + " is " + repr(v) + ", not a length") }
#assert.eq(brand.keys().sorted(), ("descriptor", "name", "print_card_n", "print_sheet_n"))
#assert(brand.print_card_n > 0, message: "no business cards asked for")
#assert(brand.print_sheet_n > 0, message: "no door sheets asked for")
#assert(nearby.print_my_address_n > 0, message: "no copies of the address plate asked for")
#assert(nearby.other_businesses.len() > 0, message: "no boards of other businesses to draw")
#for n in nearby.neighbours { assert.eq(n.keys().sorted(), ("name", "street")) }
