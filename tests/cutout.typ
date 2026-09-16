// typst compile --root . --input place=/examples/random_location_france.typ tests/cutout.typ -f pdf /dev/null
#import "../typ/signs/cutout.typ": letters

#assert.eq(letters("23 avenue des Landais"), "AVENUEDESLANDAIS")
#assert.eq(letters("Résidence"), "RESIDENCE")
#assert.eq(letters("Clermont-Ferrand, 1er"), "CLERMONTFERRANDER")
