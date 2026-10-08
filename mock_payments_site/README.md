# mock_payments_site

A Stripe-style payments dashboard over a synthetic transaction history.
`nix run .#payments-site -- KIND NAME [--lang en|fr] [--months N] [--seed N]` generates one into a temp dir and serves it.

```
generate.py ──▶ transactions.json ──fetch──▶ index.html + app.js (+ i18n.js, style.css)
 KIND NAME --lang                              no build step, no dependencies
```

- `generate.py` is the only source of data. It simulates a business day by day (seasonality, holidays, recurring clients, declines and retries, refunds, disputes, Stripe fees) and writes one JSON file shaped after Stripe's PaymentIntent objects. Locale (`en`/`fr`) decides currency, market and copy for descriptions.
- `app.js` is a hash-routed single page: Home (`#/`), Transactions (`#/payments?…`, all filter state lives in the query), payment detail (`#/payments/<id>`). Every number on screen is derived from the transactions at load; nothing is precomputed by the generator.
- `i18n.js` holds all UI copy, keyed by the dataset's `lang`. Data and UI language therefore cannot disagree.
- The dataset's `generated_at` is "now" for the UI, so a file renders the same regardless of when it is opened.
