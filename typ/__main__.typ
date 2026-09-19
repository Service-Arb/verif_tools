// What every document and plate under typ/ is drawn from. The place itself comes
// in on the command line, so nothing here names a file:
//   typst compile --root . --input place=/tmp/<place>.typ typ/to_print.typ out.pdf
#import "utils.typ": langs

#let _place = sys.inputs.at("place", default: none)
#assert(_place != none, message: "no place; compile with --input place=/tmp/<place>.typ")
#import _place: address, brands as _brands, lang, nearby, proprietaire, street_plate

#let _brand_defaults = (
  primary: rgb("#0a2540"),
  accent: rgb("#c2703d"),
  logo: none,
  name_segments: none,
  phone: none,
  site: none,
)
#let brands = _brands.map(brand => _brand_defaults + brand)

#assert(lang in langs, message: repr(lang) + " is not one of " + repr(langs))
#assert.eq(address.keys().sorted(), ("city", "name", "street"))
#assert.eq(street_plate.keys().sorted(), ("height", "width"))
#for (k, v) in street_plate { assert(type(v) == length, message: "street_plate." + k + " is " + repr(v) + ", not a length") }
#assert(brands.len() > 0, message: "no brands configured for this place")

#for brand in brands {
  let keys = brand.keys().sorted()
  assert(
    ("accent", "descriptor", "email", "logo", "name", "name_segments", "person", "phone", "primary", "print_card_n", "print_sheet_n", "site").all(key => key in keys),
    message: "brand is missing a required field: " + repr(keys),
  )
  for k in ("primary", "accent") { assert(type(brand.at(k)) == color, message: "brand." + k + " is " + repr(brand.at(k)) + ", not a colour") }
  assert(brand.logo == none or type(brand.logo) == str, message: "brand.logo is " + repr(brand.logo) + ", not an image path from the repo root")
  assert(brand.name_segments == none or type(brand.name_segments) == array, message: "brand.name_segments must be an array of styled text segments")
  for k in ("phone", "site") {
    assert(
      brand.at(k) == none or type(brand.at(k)) == str,
      message: "brand." + k + " is " + repr(brand.at(k)) + "; leave it out rather than invent one",
    )
  }
  assert(brand.print_card_n > 0, message: "no business cards asked for")
  assert(brand.print_sheet_n > 0, message: "no door sheets asked for")
}
#assert(nearby.print_my_address_n > 0, message: "no copies of the address plate asked for")
#assert(nearby.other_businesses.len() > 0, message: "no boards of other businesses to draw")
#for n in nearby.neighbours { assert.eq(n.keys().sorted(), ("name", "street")) }
