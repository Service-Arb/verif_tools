import { STRINGS } from "./i18n.js";

const data = await fetch("transactions.json").then((r) => {
  if (!r.ok) throw new Error("transactions.json missing: run `nix run .#payments-site -- plumbing|cleaning 'Company Name' [--lang en|fr]`");
  return r.json();
});

const S = STRINGS[data.lang];
const LOCALE = S.locale;
const CUR = data.currency.toUpperCase();
// the dataset's own clock, so a stale file still reads as "today"
const NOW = new Date(data.generated_at * 1000);
const TXS = data.transactions;
const CUSTOMERS = new Map(data.customers.map((c) => [c.id, c]));
const TX_BY_ID = new Map(TXS.map((t) => [t.id, t]));
const CAPTURED = new Set(["succeeded", "refunded", "partially_refunded", "disputed"]);
const view = document.getElementById("view");
const tooltip = document.getElementById("tooltip");

document.documentElement.lang = data.lang;
document.getElementById("account-name").textContent = data.business.name;
document.getElementById("company").textContent = data.business.name;
const logo = document.getElementById("account-logo");
logo.textContent = data.business.name[0];
logo.style.background = data.business.color;
document.title = `${data.business.name} – ${S.dashboard}`;
document.getElementById("search").placeholder = S.search;
document.querySelectorAll("[data-nav]").forEach((a) => ([...a.childNodes].find((n) => n.nodeType === Node.TEXT_NODE).textContent = S.nav[a.dataset.nav]));
document.querySelectorAll("[data-i18n]").forEach((el) => (el.textContent = S.nav[el.dataset.i18n]));

// ---------- formatting ----------

const moneyFmt = new Intl.NumberFormat(LOCALE, { style: "currency", currency: CUR });
const moneyFmt0 = new Intl.NumberFormat(LOCALE, { style: "currency", currency: CUR, maximumFractionDigits: 0 });
const compactMoney = new Intl.NumberFormat(LOCALE, { style: "currency", currency: CUR, notation: "compact", minimumFractionDigits: 1, maximumFractionDigits: 1 });
const compactNum = new Intl.NumberFormat(LOCALE, { notation: "compact", minimumFractionDigits: 1, maximumFractionDigits: 1 });
const int = new Intl.NumberFormat(LOCALE);
const CUR_SYMBOL = moneyFmt.formatToParts(0).find((p) => p.type === "currency").value;
const money = (c) => moneyFmt.format(c / 100);
const esc = (s) => String(s).replace(/[&<>"]/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[ch]);

const fmtTime = (d) => d.toLocaleTimeString(LOCALE, { hour: "numeric", minute: "2-digit" });
function fmtDateTime(ts) {
  const d = new Date(ts * 1000);
  const opts = { month: "short", day: "numeric" };
  if (d.getFullYear() !== NOW.getFullYear()) opts.year = "numeric";
  return `${d.toLocaleDateString(LOCALE, opts)}, ${fmtTime(d)}`;
}
const fmtDay = (d, year) => d.toLocaleDateString(LOCALE, year ? { month: "short", day: "numeric", year: "numeric" } : { month: "short", day: "numeric" });
const fmtFull = (ts) => new Date(ts * 1000).toLocaleString(LOCALE, { month: "short", day: "numeric", year: "numeric", hour: "numeric", minute: "2-digit", second: "2-digit" });

const STATUS_STYLE = {
  succeeded: ["green", "check"],
  refunded: ["gray", "refund"],
  partially_refunded: ["gray", "refund"],
  failed: ["red", "x"],
  blocked: ["red", "block"],
  uncaptured: ["gray", "clock"],
  canceled: ["gray", "block"],
  needs_response: ["orange", "alert"],
  under_review: ["gray", "clock"],
  won: ["green", "check"],
  lost: ["red", "x"],
};
const ICONS = {
  check: '<path d="m3.5 8.5 3 3 6-7" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
  refund: '<path d="M5.5 3.5 2.5 6.5l3 3M3 6.5h6.5a3.5 3.5 0 0 1 0 7H7" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
  x: '<path d="m4.5 4.5 7 7m0-7-7 7" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
  block: '<circle cx="8" cy="8" r="5.5" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="m4.2 11.8 7.6-7.6" stroke="currentColor" stroke-width="1.8"/>',
  clock: '<circle cx="8" cy="8" r="5.5" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M8 5v3.3l2 1.2" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
  alert: '<path d="M8 2.5 14 13H2Z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/><path d="M8 6.5v2.8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="8" cy="11.2" r=".9" fill="currentColor"/>',
};
const statusKey = (t) => (t.status === "disputed" ? t.dispute.status : t.status === "failed" && t.decline_code === "highest_risk_level" ? "blocked" : t.status);
function badge(key) {
  const [color, icon] = STATUS_STYLE[key];
  return `<span class="badge badge-${color}">${S.status[key]}<svg viewBox="0 0 16 16">${ICONS[icon]}</svg></span>`;
}

const BRAND_NAMES = { visa: "Visa", mastercard: "Mastercard", amex: "American Express", discover: "Discover", jcb: "JCB", diners: "Diners Club", cartes_bancaires: "Cartes Bancaires" };
const WALLET_NAMES = { apple_pay: "Apple Pay", google_pay: "Google Pay", link: "Link" };
const isBank = (pm) => pm.type !== "card";
function brandIcon(brand) {
  const b = {
    visa: '<rect width="24" height="16" rx="2" fill="#1434CB"/><path d="M10.2 10.9h-1.4l.9-5.6h1.4Zm5-5.5a3.4 3.4 0 0 0-1.2-.2c-1.4 0-2.4.7-2.4 1.8 0 .8.7 1.2 1.3 1.5s.8.4.8.7c0 .4-.5.6-.9.6a3 3 0 0 1-1.4-.3l-.2-.1-.2 1.2a4.6 4.6 0 0 0 1.7.3c1.5 0 2.4-.7 2.4-1.8 0-.6-.4-1.1-1.2-1.5-.5-.2-.8-.4-.8-.7 0-.2.3-.5.8-.5a2.6 2.6 0 0 1 1.1.2l.1.1Zm3.6-.1h-1.1a.7.7 0 0 0-.7.4l-2.1 5.2h1.5l.3-.8h1.8l.2.8h1.3Zm-1.7 3.6.6-1.6.3 1.6ZM7.6 5.3 6.2 9.1l-.2-.8a4.1 4.1 0 0 0-1.9-2.2l1.3 4.8h1.5l2.2-5.6Z" fill="#fff"/><path d="M5 5.3H2.7v.1c1.8.5 3 1.5 3.4 2.8l-.5-2.5a.6.6 0 0 0-.6-.4Z" fill="#fff"/>',
    mastercard: '<rect width="24" height="16" rx="2" fill="#252525"/><circle cx="9.5" cy="8" r="4.2" fill="#EB001B"/><circle cx="14.5" cy="8" r="4.2" fill="#F79E1B"/><path d="M12 4.6a4.2 4.2 0 0 1 0 6.8 4.2 4.2 0 0 1 0-6.8Z" fill="#FF5F00"/>',
    amex: '<rect width="24" height="16" rx="2" fill="#1F72CD"/><path d="M4 10.5 5.6 5.5h1.6l1.6 5h-1.2l-.3-1H5.6l-.3 1Zm1.9-1.9h1.2L6.5 6.7ZM9.2 10.5v-5h1.6l.9 3.1.9-3.1h1.6v5h-1V6.9l-1 3.6h-.9l-1-3.6v3.6Zm5.5 0v-5h3.6v.9h-2.5v1.1h2.4v.9h-2.4v1.2h2.5v.9Z" fill="#fff"/>',
    discover: '<rect width="24" height="16" rx="2" fill="#fff" stroke="#D8DEE4"/><path d="M12 16h10a2 2 0 0 0 2-2V9.5A22 22 0 0 1 12 16Z" fill="#F48120"/><circle cx="13.2" cy="7.6" r="2" fill="#F48120"/><path d="M3.5 6h1.2a1.6 1.6 0 0 1 0 3.2H3.5Zm.8.7v1.8h.3a.9.9 0 0 0 0-1.8ZM7 6h.8v3.2H7Zm3.2.9a1 1 0 0 0-.8-.3c-.3 0-.5.2-.5.4s.2.3.6.4c.6.2.9.5.9 1 0 .6-.5 1-1.1 1a1.6 1.6 0 0 1-1.2-.5l.5-.5a.9.9 0 0 0 .7.4c.3 0 .4-.2.4-.4s-.2-.3-.6-.5c-.5-.2-.8-.4-.8-.9a1.1 1.1 0 0 1 1.2-1 1.5 1.5 0 0 1 1 .4Z" fill="#231F20"/>',
    jcb: '<rect width="24" height="16" rx="2" fill="#fff" stroke="#D8DEE4"/><rect x="5" y="3" width="4.5" height="10" rx="1.5" fill="#0E4C96"/><rect x="9.75" y="3" width="4.5" height="10" rx="1.5" fill="#E21836"/><rect x="14.5" y="3" width="4.5" height="10" rx="1.5" fill="#007B40"/>',
    diners: '<rect width="24" height="16" rx="2" fill="#fff" stroke="#D8DEE4"/><circle cx="12" cy="8" r="5" fill="none" stroke="#0079BE" stroke-width="1.5"/><path d="M10.6 5.5v5M13.4 5.5v5" stroke="#0079BE" stroke-width="1.2"/>',
    cartes_bancaires: '<defs><linearGradient id="cbg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2C9ED8"/><stop offset=".5" stop-color="#1B5DAA"/><stop offset="1" stop-color="#0F8F57"/></linearGradient></defs><rect width="24" height="16" rx="2" fill="url(#cbg)"/><path d="M11.2 6.1a2.4 2.4 0 1 0 0 3.8l-.6-.8a1.4 1.4 0 1 1 0-2.2ZM12.4 5.5h3a1.2 1.2 0 0 1 .6 2.3 1.25 1.25 0 0 1-.6 2.7h-3Zm1 .9v1.1h1.8a.55.55 0 0 0 0-1.1Zm0 2v1.2h1.9a.6.6 0 0 0 0-1.2Z" fill="#fff"/>',
    bank: '<rect width="24" height="16" rx="2" fill="#EBEEF1"/><path d="m12 3.5 5 2.3H7Zm-4 3.3h1.2v4H8Zm3.4 0h1.2v4h-1.2Zm3.4 0H16v4h-1.2ZM7 11.7h10v1H7Z" fill="#596171"/>',
    apple_pay: '<rect width="24" height="16" rx="2" fill="#000"/><path d="M7.4 5.6a1 1 0 0 0 .3-.8 1 1 0 0 0-.7.4 1 1 0 0 0-.3.7.9.9 0 0 0 .7-.3Zm.3.4c-.4 0-.7.2-.9.2s-.5-.2-.8-.2a1.2 1.2 0 0 0-1 .6 2.5 2.5 0 0 0 .3 2.6c.2.3.4.5.7.5s.4-.2.7-.2.4.2.8.2.5-.3.7-.5a2.3 2.3 0 0 0 .3-.6 1 1 0 0 1-.1-1.7 1.1 1.1 0 0 0-.9-.5Zm2.3-.6v4.4h.7V8.3h.9a1.4 1.4 0 1 0 0-2.9Zm.7.6h.8a.8.8 0 1 1 0 1.6h-.8Zm3.4 3.9a1.1 1.1 0 0 0 1-.6v.5h.6V7.6c0-.6-.5-1-1.2-1a1.1 1.1 0 0 0-1.2.9h.6a.6.6 0 0 1 .6-.4c.4 0 .6.2.6.5v.2l-.8.1c-.8 0-1.2.4-1.2.9a.9.9 0 0 0 1 .9Zm.2-.5c-.3 0-.6-.2-.6-.4s.2-.4.7-.5l.7-.1v.2a.8.8 0 0 1-.8.8Zm2.4 1.7c.7 0 1-.3 1.3-1.1l1.2-3.4h-.7l-.8 2.6-.8-2.6h-.7l1.2 3.3-.1.2a.5.5 0 0 1-.6.4h-.2v.5Z" fill="#fff"/>',
    google_pay: '<rect width="24" height="16" rx="2" fill="#fff" stroke="#D8DEE4"/><path d="M11.4 8.1v1.6h-.5V5.8h1.3a1.2 1.2 0 0 1 .8.3 1.1 1.1 0 0 1 0 1.6 1.2 1.2 0 0 1-.8.3Zm0-1.8v1.3h.8a.7.7 0 0 0 .5-.2.6.6 0 0 0 0-.9.6.6 0 0 0-.5-.2Z" fill="#3C4043"/><path d="M9.6 7.8a2.4 2.4 0 0 0 0-.4H7.7v.8h1.1a.9.9 0 0 1-.4.6v.5H9a1.7 1.7 0 0 0 .6-1.5Z" fill="#4285F4"/><path d="M7.7 9.8a1.7 1.7 0 0 0 1.2-.4l-.6-.5a1.1 1.1 0 0 1-1.6-.6h-.6v.5a1.8 1.8 0 0 0 1.6 1Z" fill="#34A853"/><path d="M6.7 8.3a1.1 1.1 0 0 1 0-.7v-.5h-.6a1.8 1.8 0 0 0 0 1.7Z" fill="#FBBC04"/><path d="M7.7 6.6a1 1 0 0 1 .7.3l.5-.5a1.8 1.8 0 0 0-2.8.6l.6.5a1.1 1.1 0 0 1 1-.9Z" fill="#EA4335"/>',
    link: '<rect width="24" height="16" rx="2" fill="#00D66F"/><path d="M6 5h1.1v5H6Zm2 1.4h1.1V10H8Zm.55-1.5a.6.6 0 1 1 0 1.2.6.6 0 0 1 0-1.2ZM10 6.4h1v.5a1.3 1.3 0 0 1 1.1-.6c.9 0 1.3.6 1.3 1.5V10h-1.1V8c0-.5-.2-.8-.6-.8s-.7.3-.7.8v2H10ZM14 5h1.1v3l1.3-1.6h1.3l-1.5 1.7L17.8 10h-1.3l-1.4-1.9V10H14Z" fill="#011E0F"/>',
  }[brand];
  return `<svg class="brand" viewBox="0 0 24 16">${b}</svg>`;
}
function methodCell(pm) {
  if (isBank(pm)) return `<span class="pm">${brandIcon("bank")}<span>•••• ${pm.last4}</span></span>`;
  return `<span class="pm">${brandIcon(pm.brand)}<span>•••• ${pm.last4}</span>${pm.wallet ? brandIcon(pm.wallet) : ""}</span>`;
}

// ---------- time ----------

const DAY = 86400000;
const startOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const addDays = (d, n) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n, d.getHours(), d.getMinutes());
const addMonths = (d, n) => new Date(d.getFullYear(), d.getMonth() + n, d.getDate(), d.getHours(), d.getMinutes());
const FIRST_TX = new Date(TXS[TXS.length - 1].created * 1000);
const weekday = (d) => (d.getDay() - S.weekStart + 7) % 7;

const RANGES = {
  today: [() => startOfDay(NOW), "hour"],
  last7: [() => addDays(startOfDay(NOW), -6), "day"],
  last4w: [() => addDays(startOfDay(NOW), -27), "day"],
  last6m: [() => addMonths(startOfDay(NOW), -6), "week"],
  last12m: [() => addMonths(startOfDay(NOW), -12), "month"],
  mtd: [() => new Date(NOW.getFullYear(), NOW.getMonth(), 1), "day"],
  qtd: [() => new Date(NOW.getFullYear(), NOW.getMonth() - (NOW.getMonth() % 3), 1), "week"],
  ytd: [() => new Date(NOW.getFullYear(), 0, 1), "month"],
  all: [() => startOfDay(FIRST_TX), "month"],
};
const allowedIntervals = (from, to) => {
  const days = (to - from) / DAY;
  return ["hour", "day", "week", "month"].filter((k) => (k === "hour" ? days <= 3 : k === "day" ? days <= 120 : k === "week" ? days >= 14 : days >= 45));
};

function floorTo(d, interval) {
  if (interval === "hour") return new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours());
  if (interval === "day") return startOfDay(d);
  if (interval === "week") return addDays(startOfDay(d), -weekday(d));
  return new Date(d.getFullYear(), d.getMonth(), 1);
}
function step(d, interval) {
  if (interval === "hour") return new Date(d.getTime() + 3600000);
  if (interval === "day") return addDays(d, 1);
  if (interval === "week") return addDays(d, 7);
  return addMonths(d, 1);
}
/** bucket edges covering [from, to); first bucket clipped to `from` */
function buckets(from, to, interval) {
  const out = [];
  for (let b = floorTo(from, interval); b < to; b = step(b, interval)) out.push(b < from ? from : b);
  out.push(to);
  return out;
}

// ---------- metrics ----------
// each metric is a sorted list of [ts_ms, value] events plus how to fold a window of them

const sorted = (ev) => ev.sort((a, b) => a[0] - b[0]);
const captured = TXS.filter((t) => CAPTURED.has(t.status));
const sum = (vals) => vals.reduce((a, v) => a + v, 0);
const count = (v) => int.format(v);
const METRICS = {
  gross: { fmt: money, events: sorted(captured.map((t) => [t.created * 1000, t.amount])), fold: sum },
  net: {
    fmt: money,
    events: sorted([
      ...captured.map((t) => [t.created * 1000, t.amount - t.fee]),
      ...TXS.filter((t) => t.refunded_at).map((t) => [t.refunded_at * 1000, -t.amount_refunded]),
      ...TXS.filter((t) => t.dispute && t.dispute.status !== "won").map((t) => [t.dispute.created * 1000, -t.amount - t.dispute.fee]),
    ]),
    fold: sum,
  },
  successful: { fmt: count, events: sorted(captured.map((t) => [t.created * 1000, 1])), fold: sum },
  failed: { fmt: count, events: sorted(TXS.filter((t) => t.status === "failed").map((t) => [t.created * 1000, 1])), fold: sum },
  customers: { fmt: count, events: sorted(data.customers.map((c) => [c.created * 1000, 1])), fold: sum },
  spend: {
    fmt: money,
    events: sorted(captured.map((t) => [t.created * 1000, [t.customer, t.amount]])),
    fold: (vals) => (vals.length ? sum(vals.map((v) => v[1])) / new Set(vals.map((v) => v[0])).size : 0),
  },
};
function lowerBound(ev, ms) {
  let lo = 0, hi = ev.length;
  while (lo < hi) {
    const m = (lo + hi) >> 1;
    if (ev[m][0] < ms) lo = m + 1;
    else hi = m;
  }
  return lo;
}
const windowVals = (m, a, b) => m.events.slice(lowerBound(m.events, +a), lowerBound(m.events, +b)).map((e) => e[1]);
const total = (m, a, b) => m.fold(windowVals(m, a, b));
const series = (m, edges) => edges.slice(0, -1).map((a, i) => m.fold(windowVals(m, a, edges[i + 1])));

// ---------- charts ----------

const charts = new Map();
let chartSeq = 0;

/** ~3 evenly spaced nice ticks from 0, like Stripe's $0/$500/$1.0K/$1.5K */
function niceTicks(v) {
  if (v <= 0) return [0, 0.5, 1];
  const raw = v / 3;
  const p = 10 ** Math.floor(Math.log10(raw));
  const stepV = [1, 2, 2.5, 5, 10].map((m) => m * p).find((s) => s >= raw);
  const n = Math.ceil(v / stepV - 1e-9);
  return Array.from({ length: n + 1 }, (_, i) => i * stepV);
}
const shortMoney = (c) => (c >= 100000 ? compactMoney.format(c / 100) : moneyFmt0.format(c / 100));
const shortNum = (v) => (v >= 1e3 ? compactNum.format(v) : int.format(+v.toFixed(2)));

/**
 * cfg: { lines: [{values, color, dashed}], n, fmt, yFmt?, tipLabel(i, lineIdx), axis: [left, right], height, vgrid?, endDot? }
 * a line may be shorter than n (today's line stops at now)
 */
function lineChart(cfg) {
  const id = `c${chartSeq++}`;
  const W = 1000, H = cfg.height;
  const n = cfg.n;
  const ticks = niceTicks(Math.max(...cfg.lines.flatMap((l) => l.values), 0));
  const max = ticks.at(-1);
  const x = (i) => (n === 1 ? W / 2 : (i / (n - 1)) * W);
  const y = (v) => (1 - v / max) * H;
  const path = (vals) => vals.map((v, i) => `${i ? "L" : "M"}${x(i).toFixed(1)},${y(v).toFixed(1)}`).join("");
  charts.set(id, { ...cfg, x, y, W, H });
  const hgrid = cfg.yFmt ? ticks.map((t) => `<line x1="0" x2="${W}" y1="${y(t)}" y2="${y(t)}" class="${t ? "grid" : "base"}"/>`).join("") : `<line x1="0" x2="${W}" y1="${H}" y2="${H}" class="base"/>`;
  const vgrid = cfg.vgrid ? Array.from({ length: n }, (_, i) => `<line x1="${x(i)}" x2="${x(i)}" y1="0" y2="${H}" class="vgrid"/>`).join("") : "";
  const yticks = cfg.yFmt ? `<div class="yticks" style="height:${H}px">${ticks.map((t) => `<span style="top:${(y(t) / H) * 100}%">${cfg.yFmt(t)}</span>`).join("")}</div>` : "";
  const end = cfg.endDot && cfg.lines.at(-1);
  const endDot = end ? `<span class="end-dot" style="left:${(x(end.values.length - 1) / W) * 100}%;top:${y(end.values.at(-1))}px;background:${end.color}"></span>` : "";
  return `<div class="chart" data-chart="${id}">
    ${yticks}
    <div class="plot">
      <svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" style="height:${H}px">
        ${vgrid}${hgrid}
        ${cfg.lines.map((l) => `<path d="${path(l.values)}" class="line ${l.dashed ? "dashed" : ""}" style="stroke:${l.color}" vector-effect="non-scaling-stroke"/>`).join("")}
        <line class="guide" x1="0" x2="0" y1="0" y2="${H}" vector-effect="non-scaling-stroke" visibility="hidden"/>
      </svg>
      ${endDot}
      ${cfg.lines.map((l, i) => `<span class="dot" data-dot="${i}" style="background:${l.color}" hidden></span>`).join("")}
      <div class="axis"><span>${cfg.axis[0]}</span><span>${cfg.axis[1]}</span></div>
    </div>
  </div>`;
}

document.addEventListener("mousemove", (e) => {
  const el = e.target.closest?.("[data-chart]");
  document.querySelectorAll(".chart.hover").forEach((c) => c !== el && clearHover(c));
  if (!el) return (tooltip.hidden = true);
  const c = charts.get(el.dataset.chart);
  const svg = el.querySelector("svg");
  const r = svg.getBoundingClientRect();
  const i = Math.max(0, Math.min(c.n - 1, Math.round(((e.clientX - r.left) / r.width) * (c.n - 1))));
  const px = (c.x(i) / c.W) * r.width;
  el.classList.add("hover");
  const guide = svg.querySelector(".guide");
  guide.setAttribute("x1", c.x(i));
  guide.setAttribute("x2", c.x(i));
  guide.setAttribute("visibility", "visible");
  c.lines.forEach((l, li) => {
    const dot = el.querySelector(`[data-dot="${li}"]`);
    dot.hidden = i >= l.values.length;
    if (!dot.hidden) {
      dot.style.left = `${px}px`;
      dot.style.top = `${(c.y(l.values[i]) / c.H) * r.height}px`;
    }
  });
  tooltip.innerHTML = c.lines
    .map((l, li) => (i < l.values.length ? `<div class="tip-row"><span class="tip-key" style="background:${l.color}"></span><span class="tip-label">${c.tipLabel(i, li)}</span><span class="tip-val">${c.fmt(l.values[i])}</span></div>` : ""))
    .reverse()
    .join("");
  tooltip.hidden = false;
  const tw = tooltip.offsetWidth;
  const left = r.left + px + 16 + tw > window.innerWidth - 8 ? r.left + px - tw - 16 : r.left + px + 16;
  tooltip.style.left = `${left + window.scrollX}px`;
  tooltip.style.top = `${r.top + window.scrollY}px`;
});
function clearHover(el) {
  el.classList.remove("hover");
  el.querySelector(".guide").setAttribute("visibility", "hidden");
  el.querySelectorAll(".dot").forEach((d) => (d.hidden = true));
}

// ---------- popovers ----------

let openPop = null;
function closePop() {
  openPop?.remove();
  openPop = null;
}
function popover(anchor, html, onMount) {
  closePop();
  const p = document.createElement("div");
  p.className = "popover";
  p.innerHTML = html;
  document.body.appendChild(p);
  const r = anchor.getBoundingClientRect();
  p.style.top = `${r.bottom + window.scrollY + 6}px`;
  p.style.left = `${Math.min(r.left, window.innerWidth - p.offsetWidth - 16) + window.scrollX}px`;
  openPop = p;
  onMount(p);
  p.querySelector("input:not([type=checkbox]), select")?.focus();
}
document.addEventListener("mousedown", (e) => {
  if (openPop && !openPop.contains(e.target) && !e.target.closest("[data-pop]")) closePop();
});
document.addEventListener("keydown", (e) => e.key === "Escape" && closePop());
const caret = '<svg class="caret" viewBox="0 0 16 16"><path d="M4.5 6l3.5 3.5L11.5 6" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>';
function menu(anchor, options, current, onPick) {
  popover(anchor, `<div class="menu">${options.map(([k, label]) => `<button type="button" data-k="${k}" class="${k === current ? "on" : ""}">${label}${k === current ? '<span class="check-dot"><svg viewBox="0 0 16 16"><path d="m3.5 8.5 3 3 6-7" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg></span>' : ""}</button>`).join("")}</div>`, (p) =>
    p.querySelectorAll("button").forEach((b) =>
      b.addEventListener("click", () => {
        closePop();
        onPick(b.dataset.k);
      }),
    ),
  );
}

// ---------- routing ----------

function parseHash() {
  const [path, q] = location.hash.slice(1).split("?");
  return { parts: (path || "/").split("/").filter(Boolean), q: new URLSearchParams(q) };
}
function go(path, q) {
  const s = q && [...q].length ? `?${q}` : "";
  location.hash = `${path}${s}`;
}
function route() {
  closePop();
  tooltip.hidden = true;
  charts.clear();
  const { parts, q } = parseHash();
  const page = parts[0] ?? "home";
  document.querySelectorAll("[data-nav]").forEach((a) => a.classList.toggle("active", a.dataset.nav === page));
  if (page === "home") home(q);
  else if (page === "payments" && parts[1]) payment(parts[1]);
  else if (page === "payments") payments(q);
  else placeholder(document.querySelector(`[data-nav="${page}"]`)?.textContent ?? page);
  window.scrollTo(0, 0);
}
window.addEventListener("hashchange", route);

document.getElementById("search").addEventListener("keydown", (e) => {
  if (e.key !== "Enter") return;
  const v = e.target.value.trim();
  if (TX_BY_ID.has(v)) return go(`/payments/${v}`);
  go("/payments", new URLSearchParams(v ? { q: v } : {}));
});

function placeholder(title) {
  view.innerHTML = `<h1 class="page-title">${esc(title)}</h1><div class="empty"><p>${S.placeholder}</p><a href="#/payments">${S.toTransactions}</a></div>`;
}

// ---------- home ----------

const PURPLE = "#635bff";
const GRAY = "#c0c8d2";
const homeState = { range: "last7", from: null, to: null, interval: "day", compare: "previous" };
const infoIcon = '<svg class="info" viewBox="0 0 16 16"><rect x="2.25" y="2.25" width="11.5" height="11.5" rx="2.5" fill="none" stroke="currentColor" stroke-width="1.3"/><path d="M8 7.25v4" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/><circle cx="8" cy="5.1" r=".85" fill="currentColor"/></svg>';
const xIcon = '<svg class="x" viewBox="0 0 16 16"><circle cx="8" cy="8" r="6" fill="none" stroke="currentColor" stroke-width="1.3"/><path d="m5.9 5.9 4.2 4.2m0-4.2-4.2 4.2" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/></svg>';
const plusCircle = '<svg class="x" viewBox="0 0 16 16"><circle cx="8" cy="8" r="6" fill="none" stroke="currentColor" stroke-width="1.3"/><path d="M8 5.2v5.6M5.2 8h5.6" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/></svg>';
const plus = '<svg class="i" viewBox="0 0 16 16"><path d="M8 3v10M3 8h10" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"/></svg>';
const gear = '<svg class="i" viewBox="0 0 16 16"><circle cx="8" cy="8" r="2" fill="none" stroke="currentColor" stroke-width="1.5"/><path d="M8 1.75v1.5m0 9.5v1.5M1.75 8h1.5m9.5 0h1.5M3.6 3.6l1.05 1.05m6.7 6.7 1.05 1.05m0-8.8-1.05 1.05m-6.7 6.7L3.6 12.4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>';

const homeRange = () => (homeState.range === "custom" ? [homeState.from, homeState.to] : [RANGES[homeState.range][0](), NOW]);
const rangeText = () => {
  if (homeState.range !== "custom") return S.ranges[homeState.range];
  const y = homeState.from.getFullYear() !== NOW.getFullYear();
  return `${fmtDay(homeState.from, y)} – ${fmtDay(addDays(homeState.to, -1), y)}`;
};

function home() {
  const today0 = startOfDay(NOW);
  const tomorrow0 = addDays(today0, 1);
  const cum = (vals) => vals.reduce((acc, v) => (acc.push((acc.at(-1) ?? 0) + v), acc), [0]);
  const nowIdx = NOW.getHours() + 1; // points: midnight, end of each hour
  const todayHours = buckets(today0, tomorrow0, "hour");
  todayHours[nowIdx] = NOW;
  const todayVals = cum(series(METRICS.gross, todayHours.slice(0, nowIdx + 1)));
  const yVals = cum(series(METRICS.gross, buckets(addDays(today0, -1), today0, "hour")));
  // payouts settle on a 2-day rolling schedule
  const balance = total(METRICS.net, addDays(today0, -1), NOW);
  const payout = total(METRICS.net, addDays(today0, -2), addDays(today0, -1));
  const endOfDay = fmtTime(new Date(+tomorrow0 - 60000));
  const hourLabel = (i) => (i === 24 ? endOfDay : fmtTime(new Date(+today0 + i * 3600000)));
  const todayChart = lineChart({
    lines: [
      { values: yVals, color: GRAY },
      { values: todayVals, color: PURPLE },
    ],
    n: 25,
    fmt: money,
    tipLabel: (i, li) => `${li ? S.today : S.yesterday}, ${hourLabel(i)}`,
    axis: [fmtTime(today0), endOfDay],
    height: 172,
    vgrid: true,
    endDot: true,
  });

  view.innerHTML = `
    <h1 class="page-title home-title">${S.today}</h1>
    <section class="today">
      <div class="today-main">
        <div class="today-stats">
          <div><button class="stat-label" type="button">${S.grossVolume} ${caret}</button><div class="stat-big">${money(todayVals.at(-1))}</div><div class="stat-sub">${fmtTime(NOW)}</div></div>
          <div><button class="stat-label" type="button">${S.yesterday} ${caret}</button><div class="stat-big muted">${money(yVals.at(-1))}</div></div>
        </div>
        ${todayChart}
      </div>
      <div class="today-side">
        <div class="side-item"><div class="side-head"><span class="stat-label">${S.balance(CUR)}</span><a href="#/balances">${S.view}</a></div><div class="side-big">${money(balance)}</div><div class="stat-sub">${S.futurePayouts}</div></div>
        <div class="side-item"><div class="side-head"><span class="stat-label">${S.payouts}</span><a href="#/balances">${S.view}</a></div><div class="side-big">${money(payout)}</div><div class="stat-sub">${S.expected(fmtDay(tomorrow0))}</div></div>
      </div>
    </section>
    <section class="overview">
      <h2>${S.overview}</h2>
      <div class="overview-controls">
        <button class="pill" data-pop="range" type="button">${S.dateRange}<span class="pill-sep"></span><span class="pill-v">${rangeText()}</span>${caret}</button>
        <button class="pill" data-pop="interval" type="button"><span class="pill-v">${S.intervals[homeState.interval]}</span>${caret}</button>
        ${
          homeState.compare
            ? `<span class="pill"><button type="button" data-k="nocompare" title="${S.removeCompare}">${xIcon}</button><button type="button" data-pop="compare" class="pill-body">${S.compare}<span class="pill-sep"></span><span class="pill-v">${S.compares[homeState.compare]}</span>${caret}</button></span>`
            : `<button class="pill" type="button" data-pop="compare">${plusCircle}${S.compare}</button>`
        }
        <span class="spacer"></span>
        <button class="btn" type="button">${plus}${S.add}</button><button class="btn" type="button">${gear}${S.edit}</button>
      </div>
      <div class="cards-tray"><div class="cards" id="cards"></div></div>
    </section>`;

  view.querySelector('[data-pop="range"]').addEventListener("click", (e) => rangePicker(e.currentTarget));
  view.querySelector('[data-pop="interval"]').addEventListener("click", (e) => {
    const [from, to] = homeRange();
    menu(e.currentTarget, allowedIntervals(from, to).map((k) => [k, S.intervals[k]]), homeState.interval, (k) => {
      homeState.interval = k;
      home();
    });
  });
  view.querySelector('[data-pop="compare"]').addEventListener("click", (e) =>
    menu(e.currentTarget, Object.entries(S.compares), homeState.compare, (k) => {
      homeState.compare = k;
      home();
    }),
  );
  view.querySelector('[data-k="nocompare"]')?.addEventListener("click", () => {
    homeState.compare = null;
    home();
  });
  renderCards();
}

function rangePicker(anchor) {
  let [a, b] = homeRange();
  a = startOfDay(a);
  b = startOfDay(addDays(b, homeState.range === "custom" ? -1 : 0)); // inclusive end day
  let pickingEnd = false;
  let view0 = new Date(b.getFullYear(), b.getMonth() - 1, 1);
  const iso = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  const today0 = startOfDay(NOW);
  const month = (m0) => {
    const first = new Date(m0.getFullYear(), m0.getMonth(), 1);
    const days = new Date(m0.getFullYear(), m0.getMonth() + 1, 0).getDate();
    const cells = Array.from({ length: weekday(first) }, () => "<span></span>");
    for (let d = 1; d <= days; d++) {
      const day = new Date(m0.getFullYear(), m0.getMonth(), d);
      const cls = +day === +a || +day === +b ? "edge" : day > a && day < b ? "in" : "";
      cells.push(`<button type="button" data-d="${iso(day)}" class="${cls}" ${day > today0 ? "disabled" : ""}>${d}</button>`);
    }
    const title = m0.toLocaleDateString(LOCALE, { month: "long", year: "numeric" });
    return `<div class="drp-month"><div class="drp-mhead">${title[0].toUpperCase()}${title.slice(1)}</div><div class="drp-grid">${S.dow.map((d) => `<span class="dow">${d}</span>`).join("")}${cells.join("")}</div></div>`;
  };
  popover(anchor, `<div class="drp"></div>`, (p) => {
    const root = p.querySelector(".drp");
    const draw = () => {
      root.innerHTML = `
        <div class="drp-quick">${Object.keys(RANGES).map((k) => `<button type="button" data-r="${k}" class="${k === homeState.range ? "on" : ""}">${S.ranges[k]}</button>`).join("")}</div>
        <div>
          <div class="drp-io">${S.start} <input type="date" data-a value="${iso(a)}" max="${iso(today0)}"><span class="gap"></span>${S.end} <input type="date" data-b value="${iso(b)}" max="${iso(today0)}"></div>
          <div class="drp-months" style="position:relative">
            <div class="drp-mhead" style="position:absolute;inset:0 0 auto 0;pointer-events:none"><button type="button" class="prev" style="pointer-events:auto">‹</button><button type="button" class="next" style="pointer-events:auto">›</button></div>
            ${month(view0)}${month(new Date(view0.getFullYear(), view0.getMonth() + 1, 1))}
          </div>
          <div class="pop-foot"><button type="button" class="btn sm" data-clear>${S.clear}</button><button type="button" class="btn primary sm" data-apply>${S.apply}</button></div>
        </div>`;
      root.querySelectorAll("[data-r]").forEach((btn) =>
        btn.addEventListener("click", () => {
          closePop();
          homeState.range = btn.dataset.r;
          homeState.interval = RANGES[btn.dataset.r][1];
          home();
        }),
      );
      root.querySelectorAll("[data-d]").forEach((btn) =>
        btn.addEventListener("click", () => {
          const d = new Date(`${btn.dataset.d}T00:00`);
          if (!pickingEnd) [a, b, pickingEnd] = [d, d, true];
          else [a, b, pickingEnd] = d < a ? [d, a, false] : [a, d, false];
          draw();
        }),
      );
      root.querySelector(".prev").addEventListener("click", () => ((view0 = new Date(view0.getFullYear(), view0.getMonth() - 1, 1)), draw()));
      root.querySelector(".next").addEventListener("click", () => ((view0 = new Date(view0.getFullYear(), view0.getMonth() + 1, 1)), draw()));
      root.querySelector("[data-a]").addEventListener("change", (e) => e.target.value && ((a = new Date(`${e.target.value}T00:00`)), b < a && (b = a), draw()));
      root.querySelector("[data-b]").addEventListener("change", (e) => e.target.value && ((b = new Date(`${e.target.value}T00:00`)), b < a && (a = b), draw()));
      root.querySelector("[data-clear]").addEventListener("click", () => {
        closePop();
        Object.assign(homeState, { range: "last7", interval: "day" });
        home();
      });
      root.querySelector("[data-apply]").addEventListener("click", () => {
        closePop();
        const to = addDays(b, 1) > NOW ? NOW : addDays(b, 1);
        Object.assign(homeState, { range: "custom", from: a, to });
        if (!allowedIntervals(a, to).includes(homeState.interval)) homeState.interval = allowedIntervals(a, to)[0];
        home();
      });
    };
    draw();
  });
}

function renderCards() {
  const [from, to] = homeRange();
  const { interval, compare } = homeState;
  const shift = { previous: (d) => new Date(d - (to - from)), week: (d) => addDays(d, -7), month: (d) => addMonths(d, -1), year: (d) => addMonths(d, -12) }[compare];
  const edges = buckets(from, to, interval);
  const n = edges.length - 1;
  const year = from.getFullYear() !== to.getFullYear() || from.getFullYear() !== NOW.getFullYear();
  const lbl = (d) => (interval === "hour" ? fmtTime(d) : interval === "month" ? d.toLocaleDateString(LOCALE, { month: "short", year: "numeric" }) : fmtDay(d, year));
  const tip = (es, i) => {
    if (interval === "hour") return `${fmtDay(es[i])}, ${fmtTime(es[i])}`;
    if (interval === "week") return `${fmtDay(es[i])} – ${fmtDay(addDays(es[i + 1], -1))}`;
    return lbl(es[i]);
  };
  const axis = [lbl(edges[0]), lbl(n > 1 ? edges[n - 1] : edges[0])];
  const updated = S.updated(fmtTime(NOW));
  const pEdges = shift && edges.map(shift);
  const created = new URLSearchParams({ date: `range:${Math.floor(from / 1000)}:${Math.ceil(to / 1000)}` });

  const card = (key) => {
    const m = METRICS[key];
    const cur = total(m, from, to);
    const lines = [];
    let prevLine = "";
    if (shift) {
      prevLine = `<div class="card-prev">${S.previousPeriodValue(m.fmt(total(m, shift(from), shift(to))))}</div>`;
      lines.push({ values: series(m, pEdges), color: GRAY, dashed: true });
    }
    lines.push({ values: series(m, edges), color: PURPLE });
    const chart = lineChart({
      lines,
      n,
      fmt: m.fmt,
      yFmt: m.fmt === money ? shortMoney : shortNum,
      tipLabel: (i, li) => (shift && li === 0 ? tip(pEdges, i) : tip(edges, i)),
      axis,
      height: 150,
    });
    return `<div class="card"><div class="card-head"><span class="card-title">${S.metrics[key]}</span>${infoIcon}</div><div class="card-value">${m.fmt(cur)}</div>${prevLine}${chart}<div class="card-foot"><span>${updated}</span><a href="#/payments?${created}">${S.viewMore}</a></div></div>`;
  };

  const inRange = TXS.filter((t) => t.created * 1000 >= +from && t.created * 1000 < +to);
  const counts = { succeeded: 0, uncaptured: 0, refunded: 0, failed: 0 };
  for (const t of inRange) {
    if (t.status === "succeeded" || t.status === "disputed") counts.succeeded++;
    else if (t.status === "uncaptured") counts.uncaptured++;
    else if (t.status === "refunded" || t.status === "partially_refunded") counts.refunded++;
    else if (t.status === "failed") counts.failed++;
  }
  const totalCount = sum(Object.values(counts)) || 1;
  const colors = { succeeded: PURPLE, uncaptured: "#c2b9ff", refunded: "#a3acba", failed: "#df1b41" };
  const paymentsCard = `<div class="card"><div class="card-head"><span class="card-title">${S.metrics.payments}</span>${infoIcon}</div>
    <div class="card-value">${int.format(inRange.length)}</div><div class="card-prev">${S.totalAttempts}</div>
    <div class="stack-bar">${Object.entries(counts).filter(([, v]) => v).map(([k, v]) => `<span style="flex:${v / totalCount};background:${colors[k]}"></span>`).join("")}</div>
    <div class="breakdown">${Object.entries(counts).map(([k, v]) => `<a href="#/payments?${new URLSearchParams({ status: k, ...Object.fromEntries(created) })}"><span class="key" style="background:${colors[k]}"></span><span>${S.breakdown[k]}</span><span class="bd-val">${int.format(v)}</span></a>`).join("")}</div>
    <div class="card-foot"><span>${updated}</span><a href="#/payments?${created}">${S.viewMore}</a></div></div>`;

  const spend = new Map();
  for (const t of inRange) if (CAPTURED.has(t.status)) spend.set(t.customer, (spend.get(t.customer) ?? 0) + t.amount);
  const top = [...spend].sort((x, y) => y[1] - x[1]).slice(0, 6);
  const topCard = `<div class="card"><div class="card-head"><span class="card-title">${S.metrics.top}</span>${infoIcon}</div>
    <div class="top-list" style="margin-top:12px">${top.length ? top.map(([id, v]) => `<a href="#/payments?q=${encodeURIComponent(CUSTOMERS.get(id).email)}"><span class="ellip">${esc(CUSTOMERS.get(id).name)}</span><span class="bd-val">${money(v)}</span></a>`).join("") : `<div class="muted small">${S.noData}</div>`}</div>
    <div class="card-foot"><span>${updated}</span><a href="#/customers">${S.viewMore}</a></div></div>`;

  const [gross, net, failed, customers, successful, spendCard] = ["gross", "net", "failed", "customers", "successful", "spend"].map(card);
  document.getElementById("cards").innerHTML = [paymentsCard, gross, net, failed, customers, topCard, successful, spendCard].join("");
}

// ---------- payments list ----------

const TABS = [
  ["all", () => true],
  ["succeeded", (t) => t.status === "succeeded" || t.status === "partially_refunded"],
  ["refunded", (t) => t.status === "refunded" || t.status === "partially_refunded"],
  ["disputed", (t) => t.status === "disputed"],
  ["failed", (t) => t.status === "failed"],
  ["uncaptured", (t) => t.status === "uncaptured"],
];
const COLUMNS = ["amount", "method", "description", "customer", "date", "refunded", "decline"];
const hiddenCols = new Set();
const PAGE = 20;
const methodKey = (pm) => (isBank(pm) ? [pm.type] : [pm.brand, pm.wallet].filter(Boolean));
// only offer what this dataset actually contains, in a fixed display order
const METHOD_OPTS = (() => {
  const seen = new Set(TXS.flatMap((t) => methodKey(t.payment_method)));
  const names = { ...BRAND_NAMES, ...WALLET_NAMES, ...S.banks };
  return Object.keys(names).filter((k) => seen.has(k)).map((k) => [k, names[k]]);
})();
const STATUS_OPTS = Object.entries(S.statusOpts);
const selected = new Set();

/** date filter encodings: last:N:unit | range:a:b | gte:a | lte:b | on:a (unix seconds) */
function dateFilter(v) {
  const [kind, a, b] = v.split(":");
  if (kind === "last") {
    const from = b === "months" ? addMonths(startOfDay(NOW), -a) : addDays(startOfDay(NOW), -(+a - 1));
    return [from / 1000, Infinity, S.dateChip.last(a, b === "months" ? S.months : S.days)];
  }
  const da = new Date(a * 1000);
  if (kind === "range") return [+a, +b, `${fmtDay(da, true)} – ${fmtDay(new Date(b * 1000 - 1), true)}`];
  if (kind === "gte") return [+a, Infinity, S.dateChip.gte(fmtDay(da, true))];
  if (kind === "lte") return [-Infinity, +a + 86400, S.dateChip.lte(fmtDay(da, true))];
  if (kind === "on") return [+a, +a + 86400, S.dateChip.on(fmtDay(da, true))];
  throw new Error(`bad date filter ${v}`);
}
/** amount filter: eq:x | between:x:y | gt:x | lt:x (major units) */
function amountFilter(v) {
  const [kind, a, b] = v.split(":");
  const A = Math.round(a * 100), B = Math.round(b * 100);
  return {
    eq: [(c) => c === A, S.amountChip.eq(money(A))],
    between: [(c) => c >= A && c <= B, S.amountChip.between(money(A), money(B))],
    gt: [(c) => c > A, S.amountChip.gt(money(A))],
    lt: [(c) => c < A, S.amountChip.lt(money(A))],
  }[kind];
}

function applyFilters(q) {
  const preds = [];
  if (q.get("date")) {
    const [a, b] = dateFilter(q.get("date"));
    preds.push((t) => t.created >= a && t.created < b);
  }
  if (q.get("amount")) {
    const [f] = amountFilter(q.get("amount"));
    preds.push((t) => f(t.amount));
  }
  if (q.get("method")) {
    const set = new Set(q.get("method").split(","));
    preds.push((t) => methodKey(t.payment_method).some((k) => set.has(k)));
  }
  if (q.get("st")) {
    const set = new Set(q.get("st").split(","));
    preds.push((t) => set.has(t.status === "failed" && t.decline_code === "highest_risk_level" ? "blocked" : t.status));
  }
  if (q.get("q")) {
    const s = q.get("q").toLowerCase();
    // "1 234,50 €", "$1,234.50" and "1234.5" all mean the same amount
    const num = s.replace(/[^\d.,]/g, "");
    const asAmount = num ? +(data.lang === "fr" ? num.replace(/\./g, "").replace(",", ".") : num.replace(/,/g, "")) : NaN;
    preds.push((t) => {
      const c = CUSTOMERS.get(t.customer);
      return t.id.toLowerCase().includes(s) || c.email.includes(s) || c.name.toLowerCase().includes(s) || (t.description ?? "").toLowerCase().includes(s) || t.payment_method.last4 === s || Math.round(asAmount * 100) === t.amount;
    });
  }
  return TXS.filter((t) => preds.every((p) => p(t)));
}

function payments(q) {
  const tab = q.get("status") ?? "all";
  const base = applyFilters(q);
  const tabPred = TABS.find((t) => t[0] === tab)[1];
  const rows = base.filter(tabPred);
  const pages = Math.max(1, Math.ceil(rows.length / PAGE));
  const page = Math.min(pages, Math.max(1, +(q.get("page") ?? 1)));
  const shown = rows.slice((page - 1) * PAGE, page * PAGE);
  const withQ = (patch) => {
    const n = new URLSearchParams(q);
    for (const [k, v] of Object.entries(patch)) v == null ? n.delete(k) : n.set(k, v);
    return `#/payments${[...n].length ? `?${n}` : ""}`;
  };
  const cols = COLUMNS.filter((k) => !hiddenCols.has(k));
  const chip = (key, valueText) =>
    valueText
      ? `<span class="chip active" data-pop="${key}"><a class="chip-x" href="${withQ({ [key]: null, page: null })}" title="${S.remove}"><svg viewBox="0 0 16 16"><circle cx="8" cy="8" r="6.5" fill="currentColor"/><path d="m5.6 5.6 4.8 4.8m0-4.8-4.8 4.8" stroke="#fff" stroke-width="1.5" stroke-linecap="round"/></svg></a><button type="button" class="chip-body" data-chip="${key}">${S.filters[key]}<span class="chip-sep"></span><span class="chip-val">${esc(valueText)}</span>${caret}</button></span>`
      : `<button type="button" class="chip" data-chip="${key}" data-pop="${key}"><svg viewBox="0 0 16 16"><circle cx="8" cy="8" r="6.25" fill="none" stroke="currentColor" stroke-width="1.25" stroke-dasharray="2 1.6"/><path d="M8 5.25v5.5M5.25 8h5.5" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/></svg>${S.filters[key]}</button>`;
  const listText = (v, opts) => {
    const names = v.split(",").map((k) => opts.find((o) => o[0] === k)[1]);
    return names.length > 2 ? `${names[0]}, ${names[1]} +${names.length - 2}` : names.join(", ");
  };
  const anyFilter = ["date", "amount", "method", "st", "q", "cur"].some((k) => q.get(k));

  const cell = (k, t) => {
    const c = CUSTOMERS.get(t.customer);
    switch (k) {
      case "amount":
        return `<td class="c-amt">${money(t.amount)}</td><td class="c-cur">${CUR}</td><td class="c-badge">${badge(statusKey(t))}</td>`;
      case "method":
        return `<td>${methodCell(t.payment_method)}</td>`;
      case "description":
        return `<td class="c-desc"><span class="ellip ${t.description ? "" : "mono"}">${esc(t.description ?? t.id)}</span></td>`;
      case "customer":
        return `<td class="c-cust"><span class="ellip">${esc(c.email)}</span></td>`;
      case "date":
        return `<td class="c-date">${fmtDateTime(t.created)}</td>`;
      case "refunded":
        return `<td class="c-date">${t.refunded_at ? fmtDateTime(t.refunded_at) : "—"}</td>`;
      case "decline":
        return `<td class="c-decline">${t.decline_code ? S.declines[t.decline_code] : "—"}</td>`;
    }
    throw new Error(k);
  };

  view.innerHTML = `
    <div class="title-row"><h1 class="page-title">${S.transactions}</h1><button class="btn primary" type="button">${plus}${S.createPayment}</button></div>
    <div class="tabs">${["#/payments", "#/collected-fees", "#/transfers", "#/all-activity"].map((h, i) => `<a class="${i ? "" : "on"}" href="${h}">${S.subtabs[i]}</a>`).join("")}</div>
    <div class="status-tabs">${TABS.map(([k, p]) => `<a class="stab ${k === tab ? "on" : ""}" href="${withQ({ status: k === "all" ? null : k, page: null })}"><span class="stab-label">${S.tabs[k]}</span><span class="stab-count">${int.format(base.filter(p).length)}</span></a>`).join("")}</div>
    <div class="filter-row">
      <div class="chips">
        ${chip("date", q.get("date") && dateFilter(q.get("date"))[2])}
        ${chip("amount", q.get("amount") && amountFilter(q.get("amount"))[1])}
        ${chip("cur", q.get("cur") && CUR)}
        ${chip("st", q.get("st") && listText(q.get("st"), STATUS_OPTS))}
        ${chip("method", q.get("method") && listText(q.get("method"), METHOD_OPTS))}
        ${q.get("q") ? chip("q", q.get("q")) : ""}
        ${chip("more")}
        ${anyFilter ? `<a class="clear" href="${withQ({ date: null, amount: null, method: null, st: null, q: null, cur: null, page: null })}">${S.clearFilters}</a>` : ""}
      </div>
      <div class="filter-actions">
        <button class="btn" type="button" id="export"><svg class="i" viewBox="0 0 16 16"><path d="M8 2.5v7m0 0L5 6.5m3 3 3-3M2.75 10.5v2.25h10.5V10.5" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>${S.export}</button>
        <button class="btn" type="button" data-pop="cols" id="cols"><svg class="i" viewBox="0 0 16 16"><path d="M2.5 4.5h11M2.5 8h11M2.5 11.5h11" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/><circle cx="5.5" cy="4.5" r="1.5" fill="#fff" stroke="currentColor" stroke-width="1.5"/><circle cx="10.5" cy="8" r="1.5" fill="#fff" stroke="currentColor" stroke-width="1.5"/><circle cx="6.5" cy="11.5" r="1.5" fill="#fff" stroke="currentColor" stroke-width="1.5"/></svg>${S.editColumns}</button>
      </div>
    </div>
    <div class="table-wrap">
    <table class="tx">
      <thead><tr><th class="c-check"><input type="checkbox" id="check-all" ${shown.length && shown.every((t) => selected.has(t.id)) ? "checked" : ""}></th>${cols.map((k) => `<th class="h-${k}" ${k === "amount" ? 'colspan="3"' : ""}>${S.columns[k]}</th>`).join("")}<th class="c-more"></th></tr></thead>
      <tbody>${
        shown.length
          ? shown.map((t) => `<tr data-id="${t.id}" class="${selected.has(t.id) ? "sel" : ""}"><td class="c-check"><input type="checkbox" ${selected.has(t.id) ? "checked" : ""}></td>${cols.map((k) => cell(k, t)).join("")}<td class="c-more"><button type="button" class="more"><svg viewBox="0 0 16 16"><circle cx="3.5" cy="8" r="1.25" fill="currentColor"/><circle cx="8" cy="8" r="1.25" fill="currentColor"/><circle cx="12.5" cy="8" r="1.25" fill="currentColor"/></svg></button></td></tr>`).join("")
          : `<tr class="no-rows"><td colspan="${cols.length + 4}"><div class="empty-table"><strong>${S.noResults}</strong><span>${S.noResultsSub}</span></div></td></tr>`
      }</tbody>
    </table>
    </div>
    <div class="pager">
      <span class="muted">${selected.size ? S.selected(int.format(selected.size)) : ""}${rows.length ? S.viewing(int.format((page - 1) * PAGE + 1), int.format((page - 1) * PAGE + shown.length), int.format(rows.length)) : S.zeroResults}</span>
      <div class="pager-btns"><a class="btn ${page <= 1 ? "disabled" : ""}" href="${withQ({ page: page - 1 > 1 ? page - 1 : null })}">${S.previous}</a><a class="btn ${page >= pages ? "disabled" : ""}" href="${withQ({ page: page + 1 })}">${S.next}</a></div>
    </div>`;

  view.querySelectorAll("tbody tr[data-id]").forEach((tr) =>
    tr.addEventListener("click", (e) => {
      if (e.target.closest(".c-check")) {
        const id = tr.dataset.id;
        if (e.target.tagName !== "INPUT") return;
        selected.has(id) ? selected.delete(id) : selected.add(id);
        return payments(q);
      }
      if (e.target.closest(".more")) return rowMenu(e.target.closest(".more"), TX_BY_ID.get(tr.dataset.id));
      go(`/payments/${tr.dataset.id}`);
    }),
  );
  view.querySelector("#check-all").addEventListener("change", (e) => {
    shown.forEach((t) => (e.target.checked ? selected.add(t.id) : selected.delete(t.id)));
    payments(q);
  });
  view.querySelector("#export").addEventListener("click", () => exportCsv(rows));
  view.querySelector("#cols").addEventListener("click", (e) =>
    popover(e.currentTarget, `<div class="pop-title">${S.editColumns}</div><div class="checks">${COLUMNS.map((k) => `<label><input type="checkbox" value="${k}" ${hiddenCols.has(k) ? "" : "checked"} ${k === "amount" ? "disabled" : ""}>${S.columns[k]}</label>`).join("")}</div>`, (p) =>
      p.querySelectorAll("input").forEach((i) =>
        i.addEventListener("change", () => {
          i.checked ? hiddenCols.delete(i.value) : hiddenCols.add(i.value);
          const keep = openPop;
          openPop = null;
          payments(q);
          openPop = keep;
        }),
      ),
    ),
  );
  view.querySelectorAll("[data-chip]").forEach((b) => b.addEventListener("click", () => filterPop(b, b.dataset.chip, q, withQ)));
}

function rowMenu(anchor, t) {
  const opts = ["view", "customer", "copy"];
  if (CAPTURED.has(t.status) && t.status !== "refunded") opts.splice(1, 0, "refund");
  menu(anchor, opts.map((k) => [k, S.rowMenu[k]]), null, (k) => {
    if (k === "view" || k === "refund") go(`/payments/${t.id}`);
    if (k === "customer") go("/payments", new URLSearchParams({ q: CUSTOMERS.get(t.customer).email }));
    if (k === "copy") navigator.clipboard.writeText(t.id);
  });
}

function filterPop(anchor, key, q, withQ) {
  const apply = (v) => {
    closePop();
    location.hash = withQ({ [key]: v, page: null });
  };
  const footer = `<div class="pop-foot"><button type="button" class="btn primary sm" data-apply>${S.apply}</button></div>`;
  const toUnix = (s) => Math.floor(new Date(`${s}T00:00`) / 1000);
  const iso = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  const options = (ops, cur) => Object.entries(ops).map(([k, l]) => `<option value="${k}" ${k === cur ? "selected" : ""}>${l}</option>`).join("");
  if (key === "date") {
    const [kind, a, b] = (q.get("date") ?? "last:7:days").split(":");
    popover(anchor, `<div class="pop-title">${S.filterBy(S.filters.date)}</div><select data-kind>${options(S.dateOps, kind)}</select><div data-body></div>${footer}`, (p) => {
      const body = p.querySelector("[data-body]");
      const kindSel = p.querySelector("[data-kind]");
      const draw = () => {
        const k = kindSel.value;
        const d0 = iso(a && kind !== "last" ? new Date(a * 1000) : addDays(NOW, -7));
        const d1 = iso(b && kind === "range" ? new Date(b * 1000 - 1) : NOW);
        body.innerHTML =
          k === "last"
            ? `<div class="pop-line"><span class="arrow">↳</span><input type="number" min="1" value="${kind === "last" ? a : 7}" data-n><select data-unit><option value="days" ${b !== "months" ? "selected" : ""}>${S.days}</option><option value="months" ${b === "months" ? "selected" : ""}>${S.months}</option></select></div>`
            : k === "range"
              ? `<div class="pop-line"><span class="arrow">↳</span><input type="date" value="${d0}" data-a></div><div class="pop-line"><span class="and">${S.and}</span><input type="date" value="${d1}" data-b></div>`
              : `<div class="pop-line"><span class="arrow">↳</span><input type="date" value="${d0}" data-a></div>`;
      };
      kindSel.addEventListener("change", draw);
      draw();
      p.querySelector("[data-apply]").addEventListener("click", () => {
        const k = kindSel.value;
        if (k === "last") return apply(`last:${Math.max(1, +p.querySelector("[data-n]").value)}:${p.querySelector("[data-unit]").value}`);
        const A = toUnix(p.querySelector("[data-a]").value);
        if (k === "range") return apply(`range:${A}:${toUnix(p.querySelector("[data-b]").value) + 86400}`);
        apply(`${k}:${A}`);
      });
    });
  } else if (key === "amount") {
    const [kind, a, b] = (q.get("amount") ?? "eq::").split(":");
    popover(anchor, `<div class="pop-title">${S.filterBy(S.filters.amount)}</div><select data-kind>${options(S.amountOps, kind)}</select><div data-body></div>${footer}`, (p) => {
      const body = p.querySelector("[data-body]");
      const kindSel = p.querySelector("[data-kind]");
      const field = (attr, v) => `<span class="money-in"><span>${CUR_SYMBOL}</span><input type="number" step="0.01" min="0" ${attr} value="${v ?? ""}" placeholder="0.00"></span>`;
      const draw = () => {
        body.innerHTML = kindSel.value === "between" ? `<div class="pop-line"><span class="arrow">↳</span>${field("data-a", a)}</div><div class="pop-line"><span class="and">${S.and}</span>${field("data-b", b)}</div>` : `<div class="pop-line"><span class="arrow">↳</span>${field("data-a", a)}</div>`;
      };
      kindSel.addEventListener("change", draw);
      draw();
      p.querySelector("[data-apply]").addEventListener("click", () => {
        const A = p.querySelector("[data-a]").value;
        if (A === "") return;
        if (kindSel.value === "between") {
          const B = p.querySelector("[data-b]").value;
          if (B === "") return;
          return apply(`between:${A}:${B}`);
        }
        apply(`${kindSel.value}:${A}`);
      });
    });
  } else if (key === "st" || key === "method" || key === "cur") {
    const opts = key === "st" ? STATUS_OPTS : key === "method" ? METHOD_OPTS : [[data.currency, S.currencyNames[data.currency]]];
    const cur = new Set((q.get(key) ?? "").split(",").filter(Boolean));
    popover(anchor, `<div class="pop-title">${S.filterBy(S.filters[key])}</div><div class="checks">${opts.map(([k, l]) => `<label><input type="checkbox" value="${k}" ${cur.has(k) ? "checked" : ""}>${l}</label>`).join("")}</div>${footer}`, (p) =>
      p.querySelector("[data-apply]").addEventListener("click", () => {
        const v = [...p.querySelectorAll("input:checked")].map((i) => i.value).join(",");
        apply(v || null);
      }),
    );
  } else if (key === "q") {
    popover(anchor, `<div class="pop-title">${S.filterBy(S.filters.q)}</div><input type="text" data-a value="${esc(q.get("q") ?? "")}">${footer}`, (p) => p.querySelector("[data-apply]").addEventListener("click", () => apply(p.querySelector("[data-a]").value.trim() || null)));
  } else if (key === "more") {
    menu(anchor, Object.entries(S.moreFilters), null, () => filterPop(anchor, "q", q, withQ));
  }
}

// Stripe's own exports keep English headers and raw codes regardless of dashboard language
function exportCsv(rows) {
  const head = ["id", "Created date (UTC)", "Amount", "Amount Refunded", "Currency", "Status", "Description", "Fee", "Customer ID", "Customer Email", "Card Brand", "Card Last4", "Decline Code"];
  const q = (v) => (v == null ? "" : /[",\n]/.test(String(v)) ? `"${String(v).replace(/"/g, '""')}"` : v);
  const lines = rows.map((t) => {
    const c = CUSTOMERS.get(t.customer);
    return [t.id, new Date(t.created * 1000).toISOString().replace("T", " ").slice(0, 19), (t.amount / 100).toFixed(2), ((t.amount_refunded ?? 0) / 100).toFixed(2), t.currency, statusKey(t), t.description, (t.fee / 100).toFixed(2), c.id, c.email, t.payment_method.brand ?? "", t.payment_method.last4, t.decline_code].map(q).join(",");
  });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(new Blob([[head.join(","), ...lines].join("\n")], { type: "text/csv" }));
  a.download = "unified_payments.csv";
  a.click();
  URL.revokeObjectURL(a.href);
}

// ---------- payment detail ----------

function payment(id) {
  const t = TX_BY_ID.get(id);
  if (!t) return placeholder(S.notFound);
  const c = CUSTOMERS.get(t.customer);
  const pm = t.payment_method;
  const key = statusKey(t);
  const isCaptured = CAPTURED.has(t.status);
  // deterministic per payment so reloads agree
  const h = [...t.id].reduce((a, ch) => (a * 31 + ch.charCodeAt(0)) >>> 0, 7);
  const risk = key === "blocked" ? 82 + (h % 15) : t.status === "disputed" ? 38 + (h % 30) : 4 + (h % 38);
  const riskLevel = risk >= 75 ? "highest" : risk >= 65 ? "elevated" : "normal";
  const withCur = (c) => `${money(c)} ${CUR}`;

  // [ts, title, sub, dot color]
  const timeline = [[t.created, S.tl.started, "", ""]];
  if (t.status === "failed") timeline.push([t.created + 2, S.tl.failed, S.declines[t.decline_code], "red"]);
  else if (t.status === "uncaptured") timeline.push([t.created + 2, S.tl.authorizedFor(money(t.amount)), S.tl.captureBefore(fmtFull(t.created + 7 * 86400)), "green"]);
  else if (t.status === "canceled") timeline.push([t.created + 2, S.tl.authorized, "", "green"], [t.created + 6 * 86400, S.tl.canceled, t.cancellation_reason === "automatic" ? S.tl.expired : S.tl.canceledByYou, "orange"]);
  else timeline.push([t.created + 2, S.tl.succeeded, "", "green"]);
  if (t.refunded_at) timeline.push([t.refunded_at, S.tl.refunded(withCur(t.amount_refunded)), S.reasons[t.refund_reason], "orange"]);
  if (t.dispute) timeline.push([t.dispute.created, S.tl.disputed, `${S.reasons[t.dispute.reason]} · ${S.status[t.dispute.status]}`, "red"]);
  timeline.sort((a, b) => b[0] - a[0]);

  const others = TXS.filter((x) => x.customer === t.customer).slice(0, 6);
  const row = (k, v) => `<div class="kv"><dt>${k}</dt><dd>${v}</dd></div>`;
  const lostDispute = t.dispute && t.dispute.status !== "won";
  const net = t.amount - t.fee - (t.amount_refunded ?? 0) - (lostDispute ? t.amount + t.dispute.fee : 0);

  view.innerHTML = `
    <a class="crumb" href="#/payments">${S.nav["payments-shortcut"]}</a>
    <div class="detail-head">
      <div>
        <div class="detail-kicker"><svg viewBox="0 0 16 16"><rect x="1.75" y="3.5" width="12.5" height="9" rx="1.5" fill="none" stroke="currentColor" stroke-width="1.5"/><path d="M1.75 6.5h12.5" stroke="currentColor" stroke-width="1.5"/></svg>${S.payment}</div>
        <div class="detail-title"><span class="detail-amt">${money(t.amount)}</span><span class="cur big">${CUR}</span>${badge(key)}</div>
      </div>
      <div class="detail-actions">${isCaptured && t.status !== "refunded" ? `<button class="btn" type="button"><svg class="i" viewBox="0 0 16 16">${ICONS.refund}</svg>${S.refund}</button>` : ""}${t.status === "uncaptured" ? `<button class="btn primary" type="button">${S.capture}</button>` : ""}<button class="btn icon" type="button"><svg viewBox="0 0 16 16"><circle cx="3.5" cy="8" r="1.25" fill="currentColor"/><circle cx="8" cy="8" r="1.25" fill="currentColor"/><circle cx="12.5" cy="8" r="1.25" fill="currentColor"/></svg></button></div>
    </div>
    <div class="summary">
      <div><span>${S.lastUpdate}</span><strong>${fmtDateTime(timeline[0][0])}</strong></div>
      <div><span>${S.customer}</span><a href="#/payments?q=${encodeURIComponent(c.email)}">${esc(c.email)}</a></div>
      <div><span>${S.paymentMethod}</span><strong>${methodCell(pm)}</strong></div>
      <div><span>${S.risk}</span><strong><span class="risk risk-${riskLevel}">${risk}</span>${S.riskLevels[riskLevel]}</strong></div>
    </div>
    <div class="detail-grid">
      <div class="detail-main">
        <section class="dsec"><h3>${S.timeline}</h3>
          <ol class="timeline">${timeline.map(([ts, title, sub, color]) => `<li><span class="tl-dot ${color}"></span><div><strong>${esc(title)}</strong>${sub ? `<div class="muted small">${esc(sub)}</div>` : ""}<div class="muted small">${fmtFull(ts)}</div></div></li>`).join("")}</ol>
        </section>
        ${
          isCaptured
            ? `<section class="dsec"><h3>${S.paymentBreakdown}</h3><dl class="breakdown-table">
          ${row(S.paymentAmount, withCur(t.amount))}
          ${row(S.processingFees, `−${withCur(t.fee)}`)}
          ${t.amount_refunded ? row(S.refunds, `−${withCur(t.amount_refunded)}`) : ""}
          ${lostDispute ? row(S.dispute, `−${withCur(t.amount + t.dispute.fee)}`) : ""}
          <div class="kv total"><dt>${S.netAmount}</dt><dd>${withCur(net)}</dd></div>
        </dl></section>`
            : ""
        }
        <section class="dsec"><h3>${S.paymentDetails}</h3><dl>
          ${row(S.statement, esc(data.business.statement))}
          ${row(S.amount, withCur(t.amount))}
          ${isCaptured ? row(S.fee, withCur(t.fee)) : ""}
          ${isCaptured ? row(S.net, withCur(t.amount - t.fee)) : ""}
          ${row(S.statusLabel, badge(key))}
          ${row(S.description, esc(t.description ?? "—"))}
          ${t.decline_code ? row(S.declineReason, `${S.declines[t.decline_code]} <span class="mono muted">${t.decline_code}</span>`) : ""}
          ${row("ID", `<span class="mono">${t.id}</span>`)}
        </dl></section>
        <section class="dsec"><h3>${S.paymentMethod}</h3><dl>
          ${
            isBank(pm)
              ? `${row(S.type, S.banks[pm.type])}${row(S.bank, esc(pm.bank))}${row(S.account, `•••• ${pm.last4}`)}${row(S.accountType, S.checking)}`
              : `${row("ID", `<span class="mono">pm_1${t.id.slice(4, 27)}</span>`)}${row(S.number, `•••• ${pm.last4}`)}${row(S.fingerprint, `<span class="mono">${t.customer.slice(4, 20)}</span>`)}${row(S.expires, pm.exp)}${row(S.type, S.cardType(BRAND_NAMES[pm.brand], pm.funding))}${pm.wallet ? row(S.wallet, WALLET_NAMES[pm.wallet]) : ""}${row(S.issuer, S.issuers[pm.brand])}${row(S.origin, S.country)}${row(S.cvcCheck, t.decline_code === "incorrect_cvc" ? S.failedCheck : S.passed)}${row(S.zipCheck, S.passed)}`
          }
        </dl></section>
      </div>
      <aside class="detail-side">
        <section class="dsec"><h3>${S.customer}</h3><dl>${row(S.name, esc(c.name))}${row(S.email, esc(c.email))}${row("ID", `<span class="mono">${c.id}</span>`)}${row(S.customerSince, fmtDay(new Date(c.created * 1000), true))}</dl></section>
        <section class="dsec"><h3>${S.recentPayments}</h3><div class="mini-list">${others.map((o) => `<a href="#/payments/${o.id}" class="${o.id === t.id ? "cur-row" : ""}"><span>${money(o.amount)}</span>${badge(statusKey(o))}<span class="muted small">${fmtDateTime(o.created)}</span></a>`).join("")}</div></section>
      </aside>
    </div>`;
}

route();
