// List prices and the estimate maths, one place (Lager, 2026-10-09). build.js injects PRICES into the price estimator page
// ({{prices}} in prisestimat.html), and the lead brief function (netlify/functions/lead-brief.mjs) uses estimate() for the
// same numbers the visitor saw. The page keeps its own copy of trinn() for the browser: if the band logic changes, change both.
// Prices in kr ex. VAT (Sam, 2026-10-08 and 2026-10-09): pallet in and out 69.70 each (Sam, 2026-10-21, was 59); webshop orders stepped 59 (1–99) / 50
// (100–299) / 47 (300–599) / 42 (600–1,199), each order in its own band; 1,200+ by agreement. Storage per pallet per month
// (Sam, 2026-10-14): 175 with at least 5 orders per pallet per month, 200 with fewer, 220 for plain storage with no orders.
// Cap on the 200 step: never more in total than the same shop would pay at 5 orders per pallet (so one more order never
// makes the month cheaper there). Plain storage (no orders) keeps 220 by Sam's rule, uncapped.
const PRICES = { pallAktiv: 175, pallMellom: 200, pallLager: 220, aktivOrdrePerPall: 5, pallInn: 69.7, pallUt: 69.7, ordreTrinn: [{ fra: 0, pris: 59 }, { fra: 100, pris: 50 }, { fra: 300, pris: 47 }, { fra: 600, pris: 42 }], avtaleFra: 1200 };

// Orders per band, e.g. 400 orders -> [{ antall: 99, pris: 59 }, { 200 at 50 }, { 101 at 47 }].
function trinn(antall) {
  const t = PRICES.ordreTrinn;
  const grense = t.map((b, k) => (k + 1 < t.length ? t[k + 1].fra : PRICES.avtaleFra) - 1);
  return t.map((b, k) => ({ antall: Math.max(0, Math.min(antall, grense[k]) - (k ? grense[k - 1] : 0)), pris: b.pris }))
    .filter(b => b.antall > 0);
}

// Order cost on the bands, or null from avtaleFra up (by agreement).
function ordreKost(ordre) {
  return ordre >= PRICES.avtaleFra ? null : trinn(ordre).reduce((s, b) => s + b.antall * b.pris, 0);
}

// Storage line [detail, kr] by activity. The page keeps its own copy of this: change both.
function lagring(paller, ordre) {
  const terskel = PRICES.aktivOrdrePerPall * paller;
  if (ordre >= terskel) return [`${paller} paller × ${PRICES.pallAktiv} kr (minst ${PRICES.aktivOrdrePerPall} ordre per pall)`, paller * PRICES.pallAktiv];
  if (ordre === 0) return [`${paller} paller × ${PRICES.pallLager} kr (ren lagring, ingen ordre)`, paller * PRICES.pallLager];
  const tekst = `${paller} paller × ${PRICES.pallMellom} kr (under ${PRICES.aktivOrdrePerPall} ordre per pall)`;
  const naa = ordreKost(ordre), ved = ordreKost(terskel), sum = paller * PRICES.pallMellom;
  if (naa === null || ved === null) return [tekst, sum];
  const tak = paller * PRICES.pallAktiv + ved - naa;
  return tak < sum ? [`${tekst}, redusert: aldri dyrere enn med ${PRICES.aktivOrdrePerPall} ordre per pall`, tak] : [tekst, sum];
}

// A price with øre, Norwegian style: 69.7 -> '69,70'.
const ore = x => x.toLocaleString('nb-NO', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

// { paller, ordre, inn, ut } -> lines [label, detail, kr] and the monthly sum; orders from avtaleFra up are left out (by agreement).
function estimate({ paller = 0, ordre = 0, inn = 0, ut = 0 }) {
  const avtale = ordre >= PRICES.avtaleFra, bands = trinn(ordre);
  const ordreSum = avtale ? 0 : bands.reduce((s, b) => s + b.antall * b.pris, 0);
  const lines = [
    ['Lagring', ...lagring(paller, ordre)],
    ['Ordre', avtale ? `${ordre.toLocaleString('nb-NO')} ordre per måned` : bands.map(b => `${b.antall} × ${b.pris} kr`).join(' + ') || '0', ordreSum],
    ['Paller inn', `${inn} × ${ore(PRICES.pallInn)} kr`, inn * PRICES.pallInn],
    ['Paller ut', `${ut} × ${ore(PRICES.pallUt)} kr`, ut * PRICES.pallUt],
  ];
  return { lines, sum: lines.reduce((s, l) => s + l[2], 0), avtale };
}

// Cross-docking and korttidslager, one price list (Sam, 2026-10-14), per pallet, or per m² for goods not on pallets, kr ex. VAT:
// 175 through (unload, up to 48 hours on the floor, load out), then 30 a day from day 3, minimum 350 per delivery (was 125 and no
// minimum; a fee dropped after X days was rejected: staying longer would make it cheaper). The floor: never under what our
// long-term customers pay (69.70 in + 69.70 out). On pallets never more than the month package (450 per pallet per started
// month, handling included); on m² no cap (floor space at 350 per m² excludes handling), so `gulv` flags when floor space is cheaper.
// Extras: handling 127.54 per started quarter hour, waste 50 per pallet. build.js copies krysslast() into /cross-docking/ as text
// ({{krysslast}}), so it must use nothing but XPRICES and Math. Sam's desktop app (Documents/OLH Prisestimat) uses it too.
const XPRICES = { gjennom: 175, inkluderteDager: 2, dagPris: 30, minimum: 350, kvarter: 127.54, avfall: 50, mndPall: 450, mndM2: 350 };

// { enhet: 'pall' | 'm2', antall, dager, minutter, avfall } -> customer lines [label, detail, kr], the sum and the ladder workings.
function krysslast({ enhet = 'pall', antall = 0, dager = 0, minutter = 0, avfall = 0 }) {
  const X = XPRICES, m2 = enhet === 'm2', un = m2 ? 'm²' : 'paller';
  const ekstra = Math.max(0, dager - X.inkluderteDager), stige = X.gjennom + ekstra * X.dagPris;
  const mnd = Math.max(1, Math.ceil(dager / 30)), tak = mnd * X.mndPall, capped = !m2 && tak < stige;
  const kvarter = Math.ceil(minutter / 15);
  const lines = capped
    ? [['Månedspakke', `${antall} paller × ${mnd > 1 ? mnd + ' mnd × ' : ''}${X.mndPall} kr (lossing og lasting inkludert)`, antall * tak]]
    : [['Gjennomgang', `${antall} ${un} × ${X.gjennom} kr (inn, inntil 48 timer, ut)`, antall * X.gjennom]];
  if (!capped && ekstra) lines.push(['Ekstra dager', `${antall} ${un} × ${ekstra} ${ekstra === 1 ? 'dag' : 'dager'} × ${X.dagPris} kr`, antall * ekstra * X.dagPris]);
  // Small deliveries: the pallets or m² part never comes to less than the minimum (handling and waste stay on top).
  const grunn = lines.reduce((s, l) => s + l[2], 0), minstepris = antall > 0 && grunn < X.minimum;
  if (minstepris) lines.push(['Minstepris', `minst ${X.minimum} kr per levering, tillegg`, X.minimum - grunn]);
  if (kvarter) lines.push(['Håndtering', `${minutter} min = ${kvarter} påbegynte kvarter × ${X.kvarter.toLocaleString('nb-NO')} kr`, kvarter * X.kvarter]);
  if (avfall) lines.push(['Avfall', `${avfall} paller × ${X.avfall} kr`, avfall * X.avfall]);
  const gulv = m2 && antall > 0 && mnd * X.mndM2 < stige ? mnd * X.mndM2 : null;
  return { lines, sum: lines.reduce((s, l) => s + l[2], 0), capped, stige, ekstra, mnd, tak, kvarter, gulv, minstepris };
}

module.exports = { PRICES, trinn, lagring, estimate, XPRICES, krysslast };
