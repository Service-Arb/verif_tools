---
name: submit-live
description: Fill Google's Business Profile verification contact form for a place, in the user's logged-in Chrome, up to its submit button. Use on /submit-live, or when asked to fill/prepare the verification support request for a business address.
---

# submit-live

```sh
nix run .#live -- submit <place> --cdp 127.0.0.1:49300
```

`/prepare-verif` must have been run first: the command reads `<place>.pdf` and `SIREN.txt` from `--docs` (default `~/Downloads/verif_prints`).

Never press the form's Submit yourself.

- `<place>`: a place file, or words of its name under `tmp/` (`Royat`). Several brands at the door → `--brand <name>` too.
- `--cdp`: the user's own Chrome listens on `49300`. Say `127.0.0.1`, not `localhost`: other Chromes on this machine bind `[::1]:49300`.
- The managing account and the Business Profile ID are read off an open `my business` Google search showing this place's profile. None open → ask the user to open one.

A tab that answers no CDP call was never loaded since Chrome restarted; ask the user to click into that window.

The command leaves the filled form in front and prints every filled field. Show the user that list.

## note
do not bother reading the code please, - this is tested tooling. So unless something with documents provided to you goes wrong, don't waste tokens on that.
And if you find something glaring in terms of critical information that actually wasn't provided to you, which you discovered after failing and then reading code, - you must bring it up to me in the end, so that I extend instructions here. But by default assume they're sufficient.
