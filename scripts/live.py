#!/usr/bin/env python3
"""What a place says, carried into Google's own pages through a Chrome that is
already logged in, over the DevTools protocol.

  live submit tmp/<place>.typ --cdp 127.0.0.1:49300 --account <gmail> --profile-id <id> --empty-docs

`submit` walks the verification workflow to its contact form and fills
it, and stops short of the form's own submit button.
"""

import argparse, base64, json, math, re, subprocess, sys, tempfile, time, unicodedata, urllib.request
from pathlib import Path

from websockets.sync.client import connect

from nearby import geocode

WORKFLOW = "https://support.google.com/business/workflow/12825603?hl=en"  # "Check your verification status", which gethelp hands over to; `hl` pins the button text
DETAILS = (
    "The only verification method offered to this profile is a video recording, "
    "which we have not been able to complete. We are available for a live video call instead."
)

# What the page is asked, prepended to each expression: `shown` is whether the user
# can see it, and a conditional field hides by hiding an ancestor.
JS = r"""
const page = () => document.body ? document.body.innerText : '';  // a navigating tab has no body yet
const norm = s => s.replace(/\s+/g, ' ').trim();
const shown = e => e.checkVisibility() || e.parentElement.checkVisibility();
const byText = t => [...document.querySelectorAll('button,[role=button],[role=option],a')]
  .filter(e => shown(e) && (norm(e.textContent) === t || norm(e.textContent).endsWith(t)));
const flat = e => { const w = document.createTreeWalker(e, NodeFilter.SHOW_TEXT), out = []; while (w.nextNode()) out.push(w.currentNode.data); return norm(out.join(' ')); };
const label = e => norm((e.labels && e.labels[0] && e.labels[0].textContent) || e.getAttribute('aria-label') || '');
"""


class Tab:
    def __init__(self, cdp, target):
        self.cdp, self.target, self.n = cdp, target, 0
        self.ws = connect(f"ws://{cdp}/devtools/page/{target}", max_size=None, open_timeout=10)

    def call(self, method, **params):
        self.n += 1
        self.ws.send(json.dumps({"id": self.n, "method": method, "params": params}))
        while True:
            r = json.loads(self.ws.recv(timeout=30))
            if r.get("id") == self.n:
                if "error" in r:
                    raise RuntimeError(f"{method}: {r['error']}")
                return r["result"]

    def js(self, expr):
        r = self.call("Runtime.evaluate", expression=f"(() => {{{JS}\n{expr}\n}})()", returnByValue=True, awaitPromise=True, userGesture=True)
        if "exceptionDetails" in r:
            raise RuntimeError(f"{expr[:120]}: {r['exceptionDetails']['exception']['description']}")
        return r["result"].get("value")

    def until(self, expr, what, timeout=30):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            if v := self.js(expr):
                return v
            time.sleep(0.5)
        sys.exit(f"no {what} after {timeout}s on {self.js('return location.href')}")

    def text(self, t):
        return self.until(f"return page().includes({json.dumps(t)})", repr(t))

    def click(self, t):
        self.until(f"const m = byText({json.dumps(t)}); if (!m.length) return false; m.at(-1).click(); return true", f"button {t!r}")

    def type(self, selector, value):
        q = f"document.querySelector({json.dumps(selector)})"
        assert self.js(f"const e = {q}; e.scrollIntoView({{block: 'center'}}); e.focus(); e.select(); return e.value === ''"), f"{selector} already filled"
        self.call("Input.insertText", text=value)
        assert self.js(f"return {q}.value") == value, f"{selector} did not take {value!r}"

    def choose(self, selector, value):
        self.js(f"const s = document.querySelector({json.dumps(selector)}); s.value = {json.dumps(value)}; s.dispatchEvent(new Event('change', {{bubbles: true}}))")
        assert self.js(f"return document.querySelector({json.dumps(selector)}).value") == value, f"{selector} has no option {value!r}"

    def check(self, element_id):
        assert self.js(f"const e = document.getElementById({json.dumps(element_id)}); e.click(); return e.checked"), f"#{element_id} did not check"


def browser(cdp, method, **params):
    url = json.load(urllib.request.urlopen(f"http://{cdp}/json/version", timeout=10))["webSocketDebuggerUrl"]
    with connect(url, max_size=None) as ws:
        ws.send(json.dumps({"id": 1, "method": method, "params": params}))
        while True:
            r = json.loads(ws.recv(timeout=30))
            if r.get("id") == 1:
                if "error" in r:
                    raise RuntimeError(f"{method}: {r['error']}")
                return r["result"]


def pages(cdp):
    return [t for t in browser(cdp, "Target.getTargets")["targetInfos"] if t["type"] == "page"]


def profile_of(cdp, account):
    """A tab in the Chrome profile that `account` is signed into."""
    seen = {}
    for t in pages(cdp):
        if t["browserContextId"] in seen or not re.match(r"https://(support|www|mail)\.google\.com/", t["url"]):
            continue
        try:
            label = Tab(cdp, t["targetId"]).js("return document.querySelector('[aria-label^=\"Google Account:\"]')?.getAttribute('aria-label')")
        except TimeoutError:
            continue  # a discarded tab answers nothing, and another in its profile will
        if not label:
            continue
        email = re.search(r"\(([^)]+@[^)]+)\)", label)[1]
        seen[t["browserContextId"]] = email
        if email == account:
            return t
    sys.exit(f"no Chrome profile signed into {account}; signed in: {sorted(set(seen.values())) or 'none found'}")


def opened_by(cdp, before, prefix, timeout=20):
    """The tab that appeared since `before` at `prefix`."""
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        new = [t for t in pages(cdp) if t["targetId"] not in before and t["url"].startswith(prefix)]
        if new:
            assert len(new) == 1, f"{len(new)} new tabs at {prefix}"
            tab = Tab(cdp, new[0]["targetId"])
            tab.until(f"return document.readyState === 'complete' && location.href.startsWith({json.dumps(prefix)})", f"{prefix} loaded")
            return tab
        time.sleep(0.5)
    sys.exit(f"no tab opened at {prefix}")


STREET_WORDS = {"rue", "r", "avenue", "av", "ave", "boulevard", "bd", "blvd", "place", "pl", "chemin", "ch", "allee", "impasse", "imp", "route", "rte", "quai", "cours", "de", "des", "du", "la", "le", "les", "l", "d"}


def words(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower()
    return set(re.findall(r"[a-z0-9]+", s))


def pick(listings, brand, street):
    """Which of Google's listings is this brand at this street, by the words both write the same."""
    want = (words(street) - STREET_WORDS) | words(brand["name"])
    hits = [i for i, l in enumerate(listings) if want <= words(l)]
    if len(hits) != 1:
        sys.exit(f"{len(hits)} listings match {brand['name']} at {street!r}:\n  " + "\n  ".join(listings))
    return hits[0]


def placeholder(dir, name, label):
    out = Path(dir) / f"{name}.png"
    src = f'#set page(paper: "a4")\n#align(center + horizon, text(28pt)[PLACEHOLDER] + parbreak() + text(14pt, {json.dumps(label, ensure_ascii=False)}))'
    subprocess.run(["typst", "compile", "--format", "png", "-", str(out)], input=src.encode(), check=True)
    return out


def settled(cdp, sv, timeout=60):
    """A frame of the panorama once its tiles stop arriving."""
    quiet = r"""performance.setResourceTimingBufferSize(1e5);
      const tiles = performance.getEntriesByType('resource').filter(e => e.name.includes('streetviewpixels-pa.googleapis.com'));
      const splash = [...document.querySelectorAll('div')].some(e => e.getBoundingClientRect().width > 200 && /google|logo/i.test(getComputedStyle(e).backgroundImage));  // the logo laid over a panorama still fading in
      return !splash && tiles.length > 0 && performance.now() - Math.max(...tiles.map(e => e.responseEnd)) > 2000"""
    start = time.monotonic()
    while time.monotonic() < start + timeout:
        if re.search(r"No Street View imagery|Aucune image Street View", sv.js("return page()")):
            sys.exit(f"no Street View imagery at {sv.js('return location.href')}")
        if sv.js("return document.visibilityState") != "visible":
            browser(cdp, "Target.activateTarget", targetId=sv.target)  # a tab out of sight draws no panorama
        elif time.monotonic() > start + 3 and sv.js(quiet):
            frame = base64.b64decode(sv.call("Page.captureScreenshot", format="png")["data"])
            if sv.js("return document.visibilityState") == "visible":
                return frame
        time.sleep(1)
    sys.exit(f"the panorama at {sv.js('return location.href')} never settled")


def street_view(cdp, home, lat, lon, dir):
    """The panorama nearest the door, looked at from where Google's car stood: towards it, then away from it."""
    before = {t["targetId"] for t in pages(cdp)}
    Tab(cdp, home).js(f"window.open('https://www.google.com/maps/@?api=1&map_action=pano&viewpoint={lat},{lon}', '_blank')")
    sv = opened_by(cdp, before, "https://www.google.com/maps/")
    at = sv.until(r"const m = location.href.match(/@(-?[\d.]+),(-?[\d.]+),[\d.]+a/); return m && [+m[1], +m[2]]", "a panorama near the door")
    p1, p2, dl = math.radians(at[0]), math.radians(lat), math.radians(lon - at[1])
    towards = round(math.degrees(math.atan2(math.sin(dl) * math.cos(p2), math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)))) % 360
    sv.call("Emulation.setDeviceMetricsOverride", width=1600, height=1000, deviceScaleFactor=1, mobile=False)  # the shot is this size whatever the window is
    shots = []
    for name, heading in (("towards", towards), ("away", (towards + 180) % 360)):
        sv.js(rf"location.href = location.href.replace(/,([\d.]+y),(?:[\d.]+h,)?/, ',$1,{heading}h,')")
        sv.until(f"return document.readyState === 'complete' && location.href.includes(',{heading}h,')", f"heading {heading}")
        out = Path(dir) / f"street_view_{name}.png"
        out.write_bytes(settled(cdp, sv))
        shots.append(out)
    sv.call("Page.close")
    return shots


def submit(a):
    place = json.loads(subprocess.run(
        ["typst", "query", "--root", ".", "--input", f"place=/{a.place}", "scripts/live.typ", "<live>", "--field", "value", "--one"],
        check=True, capture_output=True, text=True,
    ).stdout)
    brands = [b for b in place["brands"] if a.brand in (None, b["name"])]
    if len(brands) != 1:
        sys.exit(f"{a.place} has brands {[b['name'] for b in place['brands']]}; name one with --brand")
    brand, address = brands[0], place["address"]

    home = profile_of(a.cdp, a.account)
    before = {t["targetId"] for t in pages(a.cdp)}
    Tab(a.cdp, home["targetId"]).js(f"window.open({json.dumps(WORKFLOW)}, '_blank')")
    flow = opened_by(a.cdp, before, WORKFLOW)

    stage = flow.until("const t = page(); return t.includes('Start over') ? 'resume' : t.includes('Confirm email') && 'fresh'", "verification workflow")
    if stage == "resume":
        flow.click("Start over")
    flow.text("Confirm email")
    asked = re.search(r"Is (\S+@\S+) the email address", flow.js("return page()"))[1]
    if asked != a.account:
        sys.exit(f"the workflow is signed in as {asked}, not {a.account}")
    flow.click("Confirm")
    rows = flow.until("const r = [...document.querySelectorAll('[role=row]')].filter(r => r.querySelector('input')).map(flat); return r.length && r", "business table")
    flow.js(f"[...document.querySelectorAll('[role=row]')].filter(r => r.querySelector('input'))[{pick(rows, brand, address['street'])}].querySelector('input').click()")
    flow.click("Continue")
    flow.text("What option best describes your business?")
    flow.js("[...document.querySelectorAll('input[type=radio]')].find(i => (i.closest('label') || i.labels[0] || i.parentElement.parentElement).textContent.includes('physical location for customers')).click()")
    flow.click("Continue")
    flow.click("Contact us")
    flow.click("contact our support team")
    flow.until("return location.pathname.endsWith('business_verification_awf') && document.querySelector('select[name=other_expanded_reasons_main_condensed]')", "contact form")

    flow.choose("select[name=other_expanded_reasons_main_condensed]", "business_profile_is_not_verified")
    flow.check("business_type_selector--store")
    flow.choose("select[name=relationship_to_biz]", "owner")
    flow.type("input[name=name]", brand["person"])
    if brand["phone"]:
        national = re.fullmatch(r"\+33\s*(\d[\d ]+)", brand["phone"])
        assert national, f"{brand['phone']} is not a French number, and the form's country code is set for one"
        flow.choose("select[name=phone]", "FR")
        flow.type("input[type=tel]", "0" + national[1])
        flow.check("phone_phone-type-mobile" if national[1][0] in "67" else "phone_phone-type-landline")
    flow.type("input[name=customer_email_GMB_copy]", a.account)
    if flow.js("return shown(document.querySelector('input[name=company_domain_field_updated1]'))"):  # asked of a Gmail account
        flow.type("input[name=company_domain_field_updated1]", brand["email"])
    flow.type("input[name=business_nmx_id]", a.profile_id)
    flow.type("textarea[name=describe_issue1]", f"{brand['name']} {brand['descriptor']}, {address['street']}, {address['city']}. {DETAILS}")
    flow.type("input[name=gmb_business_domain]", f"https://{brand['site']}" if brand["site"] else "N/A")
    flow.choose("select[name=country_of_listing]", "FR")
    flow.check("verification_issue--cannot_complete_verif")
    flow.type("input[name=verification_method_unsuitable]", DETAILS)
    flow.check("ODVV_consent--yes")
    flow.check("yes_consent1--consent")

    docs = tempfile.mkdtemp(prefix="verif_live_")  # the browser reads an attached file when the form is sent, so it outlives this run
    towards, away = street_view(a.cdp, home["targetId"], *geocode(f"{address['street']}, {address['city']}")[:2], docs)
    slots = dict(flow.js("return [...document.querySelectorAll('input[type=file]')].filter(shown).map(e => [e.name, label(e)])"))
    files = {
        "storefront_image_one": towards,
        "storefront_image_two": away,
        "storefront_image_8": placeholder(docs, "storefront_image_8", slots["storefront_image_8"]),
        "proof_upload1": placeholder(docs, "proof_upload1", slots["proof_upload1"]),
    }
    if slots.keys() != files.keys():
        sys.exit(f"the form asks for {sorted(slots)}, and this fills {sorted(files)}")
    root = flow.call("DOM.getDocument")["root"]["nodeId"]
    for name, path in files.items():
        node = flow.call("DOM.querySelector", nodeId=root, selector=f"input[type=file][name={name}]")["nodeId"]
        flow.call("DOM.setFileInputFiles", nodeId=node, files=[str(path)])
        assert flow.js(f"return document.querySelector('input[type=file][name={name}]').files.length") == 1, f"{name} took no file"

    empty = flow.js("return [...document.querySelectorAll('form input:not([type=radio]):not([type=checkbox]):not([type=hidden]), form textarea, form select')].filter(e => shown(e) && label(e).includes('*') && !(e.type === 'file' ? e.files.length : e.value)).map(label)")
    assert not empty, f"required and still empty: {empty}"
    flow.call("Target.activateTarget", targetId=flow.target)
    print(f"filled for {brand['name']} at {address['street']}, not sent: {flow.js('return location.href')}")
    for name, path in files.items():
        print(f"  {name}: {path}")


def main():
    p = argparse.ArgumentParser(prog="live", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="command", required=True)
    s = sub.add_parser("submit", help="fill the verification contact form for a place, up to its submit button")
    s.add_argument("place", help="tmp/<place>.typ or examples/<place>.typ")
    s.add_argument("--cdp", required=True, help="host:port of a Chrome started with --remote-debugging-port")
    s.add_argument("--account", required=True, help="the Google account that manages the profile")
    s.add_argument("--profile-id", required=True, help="Business Profile ID, from the profile's advanced settings")
    s.add_argument("--brand", help="which of the place's brands, when it has several")
    s.add_argument("--empty-docs", action="store_true", required=True, help="attach placeholders in place of the utility bill and the other proof")
    a = p.parse_args()
    if not Path("typ/__main__.typ").exists():
        sys.exit("run from the repository root")
    if not a.profile_id.isdigit():
        sys.exit(f"--profile-id is digits, not {a.profile_id!r}")
    submit(a)


if __name__ == "__main__":
    main()
