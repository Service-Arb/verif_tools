// typst compile --root . tests/utils.typ -f pdf /dev/null
#import "../typ/utils.typ": digit-code, format-date, langs, recent-date, tr

#let today = datetime.today()
#for seed in range(200) {
  let d = recent-date(seed: seed)
  let back = (today - d).days()
  assert(0 <= back and back <= 75, message: "seed " + str(seed) + " landed " + str(back) + " days back")
}

// the draw has to move within the window, not sit on one day
#let distinct = range(200).map(s => (today - recent-date(seed: s)).days()).dedup()
#assert(distinct.len() > 40, message: "only " + str(distinct.len()) + " distinct offsets in 200 draws")

#assert.eq(format-date(datetime(year: 2026, month: 2, day: 10), "fr"), "10 février 2026")
#assert.eq(format-date(datetime(year: 2026, month: 9, day: 1), "fr"), "1er septembre 2026")
#assert.eq(format-date(datetime(year: 2026, month: 9, day: 1), "en"), "1 September 2026")

#assert.eq(tr((fr: "oui", en: "yes"), "en"), "yes")

#let siren = digit-code((3, 3, 3))
#assert.eq(siren.len(), 11)
#assert.eq(siren.split(" ").map(g => g.len()), (3, 3, 3))
#assert(siren.clusters().all(c => c in "0123456789 "), message: siren)
#assert.eq(digit-code((2, 4), seed: 1).split(" ").map(g => g.len()), (2, 4))
// a code has to be drawn, not repeated: same shape, different seeds
#assert(range(20).map(s => digit-code((3, 3, 3), seed: s)).dedup().len() > 15)
// and the digits inside one code have to move too
#assert(digit-code((9,)).clusters().dedup().len() > 3)

// read back the way a registry reads it, off the printed string, and by its own
// arithmetic rather than the one that wrote it
#let luhn-ok(code) = {
  let total = 0
  for (i, d) in code.replace(" ", "").clusters().map(int).rev().enumerate() {
    let d = if calc.odd(i) { d * 2 } else { d }
    total += if d > 9 { d - 9 } else { d }
  }
  calc.rem(total, 10) == 0
}
#assert(luhn-ok("79927398713"), message: "the check the test brought is wrong")
#for wrong in range(10).filter(d => d != 3) {
  assert(not luhn-ok("7992739871" + str(wrong)))
}
#for s in range(50) {
  let code = digit-code((3, 3, 3), seed: s)
  assert(luhn-ok(code), message: code + " does not check out")
}
#assert(luhn-ok(digit-code((2,), seed: 7)))
#assert.eq(digit-code((3, 3, 3), seed: 0, luhn: false).split(" ").map(g => g.len()), (3, 3, 3))
#for l in langs {
  assert(type(format-date(today, l)) == str)
}
