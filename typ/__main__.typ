// What every document and plate under typ/ is drawn from. The place itself comes
// in on the command line, so nothing here names a file:
//   typst compile --root . --input place=/tmp/<place>.typ typ/to_print.typ out.pdf
#import "utils.typ": langs

#let _place = sys.inputs.at("place", default: none)
#assert(_place != none, message: "no place; compile with --input place=/tmp/<place>.typ")
#import _place: address, brand as _brand, lang, nearby, proprietaire, street_plate

// The two the mark and the card are drawn in: the dark the front is filled with
// and reads white on, and the one that picks out the descriptor and the rule. A
// place that has its own says so and keeps the rest. `logo` is the drawn mark, and
// no brand has to have one — left out, its initial is the mark.
#let brand = (primary: rgb("#0a2540"), accent: rgb("#c2703d"), logo: none, phone: none, site: none) + _brand

#assert(lang in langs, message: repr(lang) + " is not one of " + repr(langs))
#assert.eq(address.keys().sorted(), ("city", "name", "street"))
#assert.eq(street_plate.keys().sorted(), ("height", "width"))
#for (k, v) in street_plate { assert(type(v) == length, message: "street_plate." + k + " is " + repr(v) + ", not a length") }
// The brand's half of these comes from a file under `examples/brands/`, this
// door's half from the place — asserted together, since a sheet reads them so.
#assert.eq(
  brand.keys().sorted(),
  ("accent", "descriptor", "email", "logo", "name", "person", "phone", "primary", "print_card_n", "print_sheet_n", "site"),
)
#for k in ("primary", "accent") { assert(type(brand.at(k)) == color, message: "brand." + k + " is " + repr(brand.at(k)) + ", not a colour") }
#assert(brand.logo == none or type(brand.logo) == str, message: "brand.logo is " + repr(brand.logo) + ", not a path from the repo root")
// A number that does not ring and a site that does not answer are what a reader
// checks first, so each is drawn only where the brand has one.
#for k in ("phone", "site") {
  assert(
    brand.at(k) == none or type(brand.at(k)) == str,
    message: "brand." + k + " is " + repr(brand.at(k)) + "; leave it out rather than invent one",
  )
}
#assert(brand.print_card_n > 0, message: "no business cards asked for")
#assert(brand.print_sheet_n > 0, message: "no door sheets asked for")
#assert(nearby.print_my_address_n > 0, message: "no copies of the address plate asked for")
#assert(nearby.other_businesses.len() > 0, message: "no boards of other businesses to draw")
#for n in nearby.neighbours { assert.eq(n.keys().sorted(), ("name", "street")) }
