// A brand before it has a door; `nix build .#typ` draws one per brand file and language:
//   typst compile --root . --input brand=/examples/brands/<brand>.typ --input lang=fr typ/brand/stock.typ out.pdf
#import "../utils.typ": pack
#import "lib.typ": cards, poster, resolve
#import sys.inputs.brand: brand as _brand

#let lang = sys.inputs.lang
#let brand = resolve(_brand)
#pack((poster(brand, lang),) + cards(brand, 5, lang))
