// Shared across the documents under documents/ and typ/.

#let _lcg(x) = calc.rem(x * 1103515245 + 12345, 2147483648)

// A date in the 75 days behind today. Typst has no RNG and no clock finer than
// the day, so the day is the entropy: stable across recompiles, moving on its
// own afterwards. `seed` separates two dates drawn in the same document.
#let recent-date(seed: 0, window: 75) = {
  let today = datetime.today()
  // `typst` reads SOURCE_DATE_EPOCH over the system clock, and nix's build sandbox
  // sets it — a document dated 1970 is worse than one that failed to compile.
  assert(today.year() >= 2026, message: "clock reads " + str(today.year()) + "; unset SOURCE_DATE_EPOCH")
  let r = _lcg(_lcg(today.year() * 366 + today.ordinal() + seed * 7919))
  today - duration(days: calc.rem(calc.floor(r / 4096), window + 1))
}

#let _fr-months = ("janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre")

#let fr-date(d) = {
  let day = if d.day() == 1 { "1er" } else { str(d.day()) }
  day + " " + _fr-months.at(d.month() - 1) + " " + str(d.year())
}
