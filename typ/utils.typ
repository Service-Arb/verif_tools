// Shared across the documents under typ/.

#let _lcg(x) = calc.rem(x * 1103515245 + 12345, 2147483648)
#let _digit(x) = calc.rem(calc.floor(x / 4096), 10)

// Typst has no RNG and no clock finer than the day, so the day is the entropy:
// a draw holds across recompiles and moves on by itself the next day. `seed`
// separates two draws made in the same document.
#let _rand(seed) = {
  let today = datetime.today()
  // `typst` reads SOURCE_DATE_EPOCH over the system clock, and nix's build sandbox
  // sets it — a document dated 1970 is worse than one that failed to compile.
  assert(today.year() >= 2026, message: "clock reads " + str(today.year()) + "; unset SOURCE_DATE_EPOCH")
  _lcg(_lcg(today.year() * 366 + today.ordinal() + seed * 7919))
}

// A date in the `window` days behind today.
#let recent-date(seed: 0, window: 75) = {
  datetime.today() - duration(days: calc.rem(calc.floor(_rand(seed) / 4096), window + 1))
}

// Doubles every second digit from the right, the rightmost one left alone. A
// number passes when this comes out a multiple of 10.
#let _luhn-sum(digits) = {
  let total = 0
  for (i, d) in digits.rev().enumerate() {
    let d = if calc.odd(i) { d * 2 } else { d }
    total += if d > 9 { d - 9 } else { d }
  }
  total
}

// Digits in the shape the code is written in: `(3, 3, 3)` reads back as
// "123 456 789". Typst has no tuple, so the shape is an array. The last digit
// checks the rest, as SIREN, IBAN and card numbers all do.
// ponytail: shape and checksum, nothing behind them — carry the real number if
// the document has to survive a lookup.
#let digit-code(groups, seed: 0, luhn: true) = {
  assert(groups.len() > 0, message: "a code of no groups")
  for n in groups {
    assert(n > 0, message: "a group of " + str(n) + " digits")
  }
  let total = groups.sum()
  assert(not luhn or total > 1, message: "a code of one digit has nothing to check")

  let x = _rand(seed)
  let digits = ()
  for _ in range(if luhn { total - 1 } else { total }) {
    x = _lcg(x)
    digits.push(_digit(x))
  }
  // the check digit sits where it contributes itself, so summing over a 0 in its
  // place gives the amount it has to make up
  if luhn {
    digits.push(calc.rem(10 - calc.rem(_luhn-sum(digits + (0,)), 10), 10))
  }

  let out = ()
  let cut = 0
  for n in groups {
    out.push(digits.slice(cut, cut + n).map(str).join())
    cut += n
  }
  out.join(" ")
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
