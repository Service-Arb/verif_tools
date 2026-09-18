// One brand, whatever door it sits behind: what it is called, what it is drawn
// in, and how it is reached. A place imports this and adds what its own door
// decides — the trade line, the phone, how many of each to print.
//
// `logo` is the mark set beside the name; leave it out and the mark is `name`'s
// first letter, which says nothing about the trade. `primary` fills the card's
// front and carries white type, so it has to be dark; leave it and `accent` out
// and every door takes the pair `typ/__main__.typ` names.

#let brand = (
  name: "Aquafix",
  person: "Valeriy Sakharov",
  email: "val@aquafix.top",
  site: "aquafix.top",
  // a drop in a hex; `currentColor`, so it comes out in `accent` wherever it lands
  logo: "/assets/logos/aquafix.svg",
)
