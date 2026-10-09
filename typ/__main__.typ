// What every document and plate under typ/ is drawn from. The place itself comes
// in on the command line, so nothing here names a file:
//   typst compile --root . --input place=/tmp/<place>.typ typ/to_print.typ out.pdf
#import "utils.typ": langs
#import "brand/lib.typ": resolve

#let _place = sys.inputs.at("place", default: none)
#assert(_place != none, message: "no place; compile with --input place=/tmp/<place>.typ")
#import _place: address, brands as _brands, nearby
#import "/examples/main.typ": directions, lang, print_card_n, print_my_address_n, proprietaire, street_plate

#let brands = _brands.map(resolve)

#assert(lang in langs, message: repr(lang) + " is not one of " + repr(langs))
#assert.eq(address.keys().sorted(), ("city", "name", "street"))
#assert.eq(street_plate.keys().sorted(), ("height", "width"))
#for (k, v) in street_plate { assert(type(v) == length, message: "street_plate." + k + " is " + repr(v) + ", not a length") }
#assert(brands.len() > 0, message: "no brands configured for this place")

#for brand in brands { assert(type(brand.descriptor) == str, message: brand.name + "'s descriptor is " + repr(brand.descriptor)) }
#assert(print_card_n > 0, message: "no business cards asked for")
#assert(type(directions) == array, message: "directions is " + repr(directions) + ", not the signs on the way to the door")
#for sign in directions {
  assert(sign.len() > 0 and sign.keys().all(k => k in ("next_direction", "door")), message: "a sign is next_direction and/or door, not " + repr(sign))
  if "next_direction" in sign {
    assert.eq(sign.next_direction.keys().sorted(), ("arrow", "text"), message: "next_direction is " + repr(sign.next_direction))
    assert(type(sign.next_direction.text) == str, message: "next_direction.text is " + repr(sign.next_direction.text))
  }
  if "door" in sign { assert(type(sign.door) == str, message: "door is " + repr(sign.door) + ", not what is written on it") }
}
#assert(print_my_address_n > 0, message: "no copies of the address plate asked for")
#assert(nearby.other_businesses.len() > 0, message: "no boards of other businesses to draw")
#for n in nearby.neighbours { assert.eq(n.keys().sorted(), ("name", "street")) }
