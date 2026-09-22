---
name: submit-live
description: Fill Google's Business Profile verification contact form for a place, in the user's logged-in Chrome, up to its submit button. Use on /submit-live, or when asked to fill/prepare the verification support request for a business address.
---

# submit-live

```sh
nix run .#live -- submit tmp/<place>.typ --cdp 127.0.0.1:49300 --account <gmail> --profile-id <id> --docs ~/Downloads/verif_prints

`/prepare-verif` must have been run first. The command reads the matching place PDF and `SIREN.txt` from `--docs` (default `~/Downloads/verif_prints`). It enters the SIREN in Google's official company-register field and uploads that same PDF to both the utility-bill and other-business-proof slots. It still generates the two current Street View images itself.
```

Never press the form's Submit yourself.

- `<place>`: the place file for the address, as `/prepare-verif` writes it. Several brands at the door → `--brand <name>` too.
- `--docs`: directory produced by `/prepare-verif`; it must contain `<place>.pdf` and `SIREN.txt`. Both proof upload fields receive that prepared PDF.
- `--cdp`: the user's own Chrome listens on `49300`. Say `127.0.0.1`, not `localhost`: other Chromes on this machine bind `[::1]:49300`.
- `--account`: the Gmail that manages the profile; from context, else ask.
- `--profile-id`: get it before the run. In a tab of that account's Chrome window, search `my business` (with several profiles, pick this place's), ⋮ → Business Profile settings → Advanced settings → Business Profile ID. That dialog is an iframe: click with `Input.dispatchMouseEvent`, read the digits with `DOM.getDocument` `pierce: true`.

A tab that answers no CDP call was never loaded since Chrome restarted; ask the user to click into that window.

The command ends printing the tab's URL and leaves that tab in front. Screenshot it full-page and show it.

## note
do not bother reading the code please, - this is tested tooling. So unless something with documents provided to you goes wrong, don't waste tokens on that.
And if you find something glaring in terms of critical information that actually wasn't provided to you, which you discovered after failing and then reading code, - you must bring it up to me in the end, so that I extend instructions here. But by default assume they're sufficient.
