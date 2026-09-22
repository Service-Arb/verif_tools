---
name: submit-live
description: Fill Google's Business Profile verification contact form for a place, in the user's logged-in Chrome, up to its submit button. Use on /submit-live, or when asked to fill/prepare the verification support request for a business address.
---

# submit-live

```sh
nix run .#live -- submit tmp/<place>.typ --cdp 127.0.0.1:49300 --account <gmail> --profile-id <id> --empty-docs
```

Always pass `--empty-docs`. Never press the form's Submit.

- `<place>`: the place file for the address, as `/prepare-verif` writes it. Several brands at the door → `--brand <name>` too.
- `--cdp`: the user's own Chrome listens on `49300`. Say `127.0.0.1`, not `localhost`: other Chromes on this machine bind `[::1]:49300`.
- `--account`: the Gmail that manages the profile; from context, else ask.
- `--profile-id`: get it before the run. In a tab of that account's Chrome window, search `my business` (with several profiles, pick this place's), ⋮ → Business Profile settings → Advanced settings → Business Profile ID. That dialog is an iframe: click with `Input.dispatchMouseEvent`, read the digits with `DOM.getDocument` `pierce: true`.

A tab that answers no CDP call was never loaded since Chrome restarted; ask the user to click into that window.

The command ends printing the tab's URL and leaves that tab in front. Screenshot it full-page and show it.
