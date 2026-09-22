// typst query --root . --input place=/tmp/<place>.typ scripts/live.typ "<live>" --field value --one
#import "/typ/__main__.typ": address, brands

#metadata((
  address: address,
  brands: brands.map(b => (name: b.name, descriptor: b.descriptor, person: b.person, email: b.email, phone: b.phone, site: b.site)),
)) <live>
