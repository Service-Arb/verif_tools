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
#for l in langs {
  assert(type(format-date(today, l)) == str)
}
