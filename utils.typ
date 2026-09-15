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

// Doubles as Typst's own `text(lang:)` codes.
#let langs = ("fr", "en")

// Documents hold their text keyed by language. A half-translated one fails here,
// rather than on the day someone renders the language that is missing.
#let tr(strings, lang) = {
  assert.eq(strings.keys().sorted(), langs.sorted(), message: "document covers " + repr(strings.keys()) + ", not " + repr(langs))
  strings.at(lang)
}

#let _months = (
  fr: ("janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"),
  en: ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"),
)

#let format-date(d, lang) = {
  let day = if lang == "fr" and d.day() == 1 { "1er" } else { str(d.day()) }
  day + " " + _months.at(lang).at(d.month() - 1) + " " + str(d.year())
}
