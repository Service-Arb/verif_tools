// typst compile tests/utils.typ /dev/null
#import "../utils.typ": fr-date, recent-date

#let today = datetime.today()
#for seed in range(200) {
  let d = recent-date(seed: seed)
  let back = (today - d).days()
  assert(0 <= back and back <= 75, message: "seed " + str(seed) + " landed " + str(back) + " days back")
}

// the draw has to move within the window, not sit on one day
#let distinct = range(200).map(s => (today - recent-date(seed: s)).days()).dedup()
#assert(distinct.len() > 40, message: "only " + str(distinct.len()) + " distinct offsets in 200 draws")

#assert.eq(fr-date(datetime(year: 2026, month: 9, day: 1)), "1er septembre 2026")
#assert.eq(fr-date(datetime(year: 2026, month: 2, day: 10)), "10 février 2026")
