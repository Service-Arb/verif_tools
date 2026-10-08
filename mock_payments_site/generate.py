"""Synthetic Stripe payment history for a small local service business.

usage: generate.py {plumbing,cleaning} NAME [--lang en|fr] [--months N] [--seed N] [--out PATH]
"""

import argparse
import json
import math
import random
import string
import unicodedata
from datetime import date, datetime, timedelta, timezone

DECLINE_CODES = [
    ("insufficient_funds", 38),
    ("generic_decline", 30),
    ("incorrect_cvc", 9),
    ("expired_card", 8),
    ("do_not_honor", 7),
    ("card_velocity_exceeded", 3),
    ("incorrect_number", 2),
    ("lost_card", 1),
    ("fraudulent", 1),
    ("highest_risk_level", 1),  # Radar block
]
REFUND_REASONS = [("requested_by_customer", 70), ("duplicate", 22), ("fraudulent", 8)]
DISPUTE_REASONS = [("fraudulent", 40), ("product_not_received", 15), ("product_unacceptable", 25), ("duplicate", 10), ("general", 10)]
DISPUTE_STATUSES = [("needs_response", 1), ("under_review", 1), ("won", 3), ("lost", 2)]


def us_holiday(d):
    thanksgiving = d.month == 11 and 22 <= d.day <= 28 and d.weekday() == 3
    return (d.month, d.day) in {(1, 1), (7, 4), (12, 24), (12, 25), (12, 31)} or thanksgiving


def easter(y):
    """anonymous Gregorian algorithm"""
    a, b, c = y % 19, y // 100, y % 100
    d, e = b // 4, b % 4
    g = (8 * b + 13) // 25
    h = (19 * a + b - d - g + 15) % 30
    i, k = c // 4, c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 19 * l) // 433
    month = (h + l - 7 * m + 90) // 25
    return date(y, month, (h + l - 7 * m + 33 * month + 19) % 32)


def fr_holiday(d):
    e = easter(d.year)
    movable = {e + timedelta(days=1), e + timedelta(days=39), e + timedelta(days=50)}  # lundi de Pâques, Ascension, Pentecôte
    return (d.month, d.day) in {(1, 1), (5, 1), (5, 8), (7, 14), (8, 15), (11, 1), (11, 11), (12, 25)} or d.date() in movable


# services: (name, weight, (low, high) in major units, emergency-eligible)
LOCALES = {
    "en": {
        "currency": "usd",
        "first": "James Mary Robert Patricia John Jennifer Michael Linda David Elizabeth William Barbara Richard Susan Joseph Jessica Thomas Sarah Charles Karen Christopher Lisa Daniel Nancy Matthew Betty Anthony Sandra Mark Margaret Donald Ashley Steven Kimberly Andrew Emily Paul Donna Joshua Michelle Kenneth Carol Kevin Amanda Brian Melissa George Deborah Timothy Stephanie Ronald Rebecca Jason Laura Edward Sharon Jeffrey Cynthia Ryan Kathleen Jacob Amy Gary Angela Nicholas Shirley Eric Anna Jonathan Brenda Stephen Pamela Larry Emma Justin Nicole Scott Helen Brandon Samantha Benjamin Katherine Samuel Christine Gregory Debra Alexander Rachel Patrick Carolyn Frank Janet Raymond Maria Jack Olivia Dennis Heather Jerry Diane Tyler Julie Aaron Joyce Jose Victoria Adam Ruth Nathan Virginia Henry Lauren Zachary Kelly Douglas Christina Peter Joan Kyle Evelyn Noah Judith Ethan Andrea Jeremy Hannah Walter Megan Christian Cheryl Keith Jacqueline Roger Martha Terry Madison Austin Teresa Sean Gloria Gerald Sara Carl Janice Harold Ann Dylan Kathryn Arthur Abigail Lawrence Sophia Jordan Frances Jesse Jean Bryan Alice Billy Judy Bruce Isabella Gabriel Julia Joe Grace Logan Amber Alan Denise Juan Danielle Albert Marilyn Willie Beverly Elijah Charlotte Wayne Natalie Randy Theresa Vincent Diana Mason Brittany Roy Doris Ralph Kayla Bobby Alexis Russell Lori Bradley Marie Philip Tiffany Eugene Kaitlyn Priya Wei Mateo Aisha Hiroshi Fatima Luis Mei Omar Sofia Diego Chloe".split(),
        "last": "Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson Walker Young Allen King Wright Scott Torres Nguyen Hill Flores Green Adams Nelson Baker Hall Rivera Campbell Mitchell Carter Roberts Gomez Phillips Evans Turner Diaz Parker Cruz Edwards Collins Reyes Stewart Morris Morales Murphy Cook Rogers Gutierrez Ortiz Morgan Cooper Peterson Bailey Reed Kelly Howard Ramos Kim Cox Ward Richardson Watson Brooks Chavez Wood James Bennett Gray Mendoza Ruiz Hughes Price Alvarez Castillo Sanders Patel Myers Long Ross Foster Jimenez Powell Jenkins Perry Russell Sullivan Bell Coleman Butler Henderson Barnes Gonzales Fisher Vasquez Simmons Romero Jordan Patterson Alexander Hamilton Graham Reynolds Griffin Wallace Moreno West Cole Hayes Bryant Herrera Gibson Ellis Tran Medina Aguilar Stevens Murray Ford Castro Marshall Owens Harrison Fernandez McDonald Woods Washington Kennedy Wells Vargas Henry Chen Freeman Webb Tucker Guzman Burns Crawford Olson Simpson Porter Hunter Gordon Mendez Silva Shaw Snyder Mason Dixon Munoz Hunt Hicks Holmes Palmer Wagner Black Robertson Boyd Rose Stone Salazar Fox Warren Mills Meyer Rice Schmidt Garza Daniels Ferguson Nichols Stephens Soto Weaver Ryan Gardner Payne Grant Dunn Kelley Spencer Hawkins Arnold Pierce Hansen Peters Santos Hart Bradley Knight Elliott Cunningham Duncan Armstrong Hudson Carroll Lane Riley Andrews Ray Berry Perkins Hoffman Johnston Matthews Pena Richards Willis Carpenter Lawrence Sandoval".split(),
        "domains": [("gmail.com", 52), ("yahoo.com", 11), ("icloud.com", 12), ("outlook.com", 8), ("hotmail.com", 7), ("aol.com", 3), ("comcast.net", 4), ("att.net", 3)],
        "commercial_tld": "com",
        "commercial_mailbox": ["ap", "billing", "accounts", "office"],
        "brands": [("visa", 52), ("mastercard", 26), ("amex", 14), ("discover", 6), ("jcb", 1), ("diners", 1)],
        "wallets": [(None, 72), ("apple_pay", 21), ("google_pay", 4), ("link", 3)],
        "credit_share": 0.6,
        "bank_type": "us_bank_account",
        "banks": ["Chase", "Bank of America", "Wells Fargo", "Citibank", "US Bank", "PNC Bank"],
        "dispute_fee": 1500,
        "holiday": us_holiday,
        "august": 1.0,
        "invoice": "Payment for Invoice",
        "deposit": "Deposit — {}",
        "emergency": lambda n: f"Emergency {n[0].lower()}{n[1:]}",
        "surcharge": [99, 125, 149, 175],
        "big": 1500,
        "recurring_name": "Standard cleaning — {}",
        "freq": {1: "weekly", 2: "biweekly", 4: "monthly"},
        "recurring_price": {1: (115, 185), 2: (135, 220), 4: (160, 260)},
        "office_monthly": (650, 2400),
        "plumbing": {
            "color": "#0a5fd1",
            "services": [
                ("Drain cleaning", 18, (149, 349), True),
                ("Clogged toilet repair", 10, (125, 245), True),
                ("Leak detection & repair", 12, (195, 650), True),
                ("Faucet replacement", 8, (185, 420), False),
                ("Garbage disposal install", 6, (275, 520), False),
                ("Water heater repair", 7, (225, 690), True),
                ("Water heater replacement", 4, (1350, 3400), True),
                ("Tankless water heater install", 1.5, (2800, 5200), False),
                ("Sewer line camera inspection", 5, (199, 425), False),
                ("Hydro jetting", 3, (450, 950), True),
                ("Sump pump replacement", 2.5, (450, 1150), True),
                ("Burst pipe repair", 3, (350, 1600), True),
                ("Repiping (partial)", 1, (1800, 6500), False),
                ("Sewer line repair", 1.2, (2400, 8900), True),
                ("Gas line repair", 1.5, (300, 1200), True),
                ("Shower valve replacement", 3, (295, 690), False),
                ("Toilet installation", 4, (295, 650), False),
                ("Backflow test & certification", 3, (95, 175), False),
                ("Service call / diagnostic fee", 6, (79, 129), True),
            ],
            "commercial": ["Oakridge Property Management", "Summit Realty Group", "Harbor View Apartments", "Pinecrest HOA", "Maple Street Diner", "Lakeside Dental Group", "Brightway Self Storage"],
            "per_day": 9.0,
            # Jan..Dec: frozen pipes and heater failures in winter, slower late spring
            "season": [1.35, 1.25, 1.05, 0.95, 0.9, 0.88, 0.95, 0.95, 0.92, 1.0, 1.1, 1.3],
            "weekday": [1.12, 1.08, 1.05, 1.05, 1.0, 0.55, 0.3],
        },
        "cleaning": {
            "color": "#1aa57c",
            "services": [
                ("Deep cleaning", 30, (240, 520), False),
                ("Move-out cleaning", 18, (280, 690), False),
                ("Move-in cleaning", 9, (260, 590), False),
                ("Post-construction cleaning", 4, (450, 1400), False),
                ("Carpet shampooing", 9, (120, 360), False),
                ("Window washing (interior)", 8, (110, 290), False),
                ("Oven & fridge add-on", 6, (60, 120), False),
                ("Airbnb turnover", 14, (85, 175), False),
            ],
            "commercial": ["Cornerstone Law Offices", "Northside Pediatrics", "Bluebird Coworking", "Riverbend Yoga Studio", "Apex Insurance Agency", "Greenleaf Montessori"],
            "per_day": 2.6,  # one-off jobs; recurring visits come on top
            "recurring_clients": 38,
            # spring cleaning and summer move season
            "season": [0.85, 0.85, 1.1, 1.25, 1.2, 1.2, 1.1, 1.1, 0.95, 0.95, 0.95, 1.15],
            "weekday": [1.0, 1.05, 1.05, 1.1, 1.15, 0.7, 0.15],
        },
    },
    "fr": {
        "currency": "eur",
        "first": "Jean Marie Pierre Nathalie Michel Isabelle Philippe Sylvie Alain Catherine Nicolas Sophie Christophe Valérie Laurent Christine Stéphane Sandrine Julien Céline Thomas Aurélie Sébastien Émilie David Julie François Camille Antoine Léa Maxime Manon Hugo Chloé Lucas Inès Louis Sarah Mathieu Claire Olivier Anne Patrick Martine Éric Hélène Vincent Caroline Guillaume Pauline Romain Marion Yannick Élodie Karim Fatima Mehdi Amina Mohamed Leïla Thierry Brigitte Benoît Agnès Florian Océane Quentin Mélanie Arnaud Laetitia Jérôme Virginie Damien Charlotte Gilles Monique Bernard Françoise Daniel Jacqueline Rémi Justine Adrien Margaux Alexandre Clémence Théo Jade Gabriel Louise Raphaël Alice Arthur Lina Paul Emma Jules Zoé Yasmine Samir Hervé Dominique Pascal Corinne Cédric Audrey Franck Nadia Gaëlle Loïc".split(),
        "last": "Martin Bernard Thomas Petit Robert Richard Durand Dubois Moreau Laurent Simon Michel Lefebvre Leroy Roux David Bertrand Morel Fournier Girard Bonnet Dupont Lambert Fontaine Rousseau Vincent Muller Lefèvre Faure André Mercier Blanc Guérin Boyer Garnier Chevalier François Legrand Gauthier Garcia Perrin Robin Clément Morin Nicolas Henry Roussel Mathieu Gautier Masson Marchand Duval Denis Dumont Lemaire Noël Meyer Dufour Meunier Brun Blanchard Giraud Joly Rivière Lucas Brunet Gaillard Barbier Arnaud Martinez Gérard Roche Renard Schmitt Roy Leroux Colin Vidal Caron Picard Roger Fabre Aubert Lemoine Renaud Dumas Lacroix Olivier Philippe Bourgeois Benoît Rey Leclerc Payet Rolland Leclercq Guillaume Lecomte Lopez Dupuis Guillot Hubert Berger Carpentier Sanchez Moulin Deschamps Huet Vasseur Perez Boucher Fleury Royer Klein Jacquet Adam Poirier Marty Aubry Guyot Carré Charles Renault Charpentier Ménard Maillard Baron Bertin Bailly Hervé Schneider Fernandez Collet Léger Bouvier Julien Prévost Millet Perrot Cousin Germain Breton Besson Langlois Rémy Pelletier Lévêque Perrier Leblanc Barré Lebrun Marchal Weber Mallet Hamon Boulanger Jacob Monnier Michaud Rodriguez Guichard Gillet Étienne Poulain Tessier Chauvin Bouchet Lemaître Bénard Maréchal Humbert Reynaud Antoine Perret Barthélemy Cordier Pichon Lejeune Gilbert Lamy Delaunay Pasquier Carlier Laporte".split(),
        "domains": [("gmail.com", 40), ("orange.fr", 14), ("hotmail.fr", 9), ("free.fr", 8), ("sfr.fr", 5), ("laposte.net", 5), ("outlook.fr", 5), ("yahoo.fr", 5), ("wanadoo.fr", 4), ("icloud.com", 5)],
        "commercial_tld": "fr",
        "commercial_mailbox": ["compta", "contact", "facturation", "gestion"],
        # CB co-badged cards show as Cartes Bancaires when routed domestically
        "brands": [("visa", 47), ("mastercard", 36), ("cartes_bancaires", 13), ("amex", 4)],
        "wallets": [(None, 74), ("apple_pay", 18), ("google_pay", 5), ("link", 3)],
        "credit_share": 0.3,  # French cards are mostly debit (débit immédiat/différé)
        "bank_type": "sepa_debit",
        "banks": ["BNP Paribas", "Crédit Agricole", "Société Générale", "LCL", "Caisse d'Épargne", "Banque Populaire", "Crédit Mutuel", "La Banque Postale", "Boursorama", "Qonto"],
        "dispute_fee": 2000,
        "holiday": fr_holiday,
        "august": 0.6,  # congés
        "invoice": "Paiement de la facture",
        "deposit": "Acompte — {}",
        "emergency": lambda n: f"Urgence — {n[0].lower()}{n[1:]}",
        "surcharge": [60, 80, 100, 120],
        "big": 1200,
        "recurring_name": "Ménage régulier — {}",
        "freq": {1: "hebdomadaire", 2: "bimensuel", 4: "mensuel"},
        "recurring_price": {1: (60, 110), 2: (70, 130), 4: (90, 160)},
        "office_monthly": (450, 1900),
        "plumbing": {
            "color": "#0a5fd1",
            "services": [
                ("Débouchage canalisation", 18, (90, 250), True),
                ("Débouchage WC", 11, (80, 180), True),
                ("Recherche et réparation de fuite", 12, (150, 450), True),
                ("Remplacement de mitigeur", 8, (120, 320), False),
                ("Installation sanibroyeur", 4, (450, 900), False),
                ("Réparation chauffe-eau", 7, (150, 450), True),
                ("Remplacement chauffe-eau", 4, (900, 2400), True),
                ("Installation chauffe-eau thermodynamique", 1.2, (2200, 4200), False),
                ("Inspection caméra canalisation", 5, (180, 400), False),
                ("Hydrocurage", 3, (300, 700), True),
                ("Remplacement groupe de sécurité", 5, (120, 250), True),
                ("Réparation canalisation gelée", 3, (250, 1200), True),
                ("Remplacement colonne d'eau (partiel)", 1, (1500, 5000), False),
                ("Réparation canalisation enterrée", 1.2, (1800, 6500), True),
                ("Mise en conformité gaz", 1.5, (250, 900), True),
                ("Remplacement mitigeur thermostatique douche", 3, (200, 480), False),
                ("Remplacement WC", 4, (350, 750), False),
                ("Détartrage chauffe-eau", 3, (150, 300), False),
                ("Déplacement et diagnostic", 6, (49, 89), True),
            ],
            "commercial": ["Cabinet Moreau Syndic", "SCI Les Tilleuls", "Résidence Les Acacias", "Boulangerie Lefèvre", "Cabinet dentaire Rousseau", "Hôtel du Parc", "Garde-Meubles Duval"],
            "per_day": 7.0,
            "season": [1.3, 1.2, 1.05, 0.95, 0.9, 0.9, 0.85, 0.95, 1.0, 1.05, 1.1, 1.25],
            "weekday": [1.1, 1.08, 1.05, 1.05, 1.02, 0.45, 0.15],
        },
        "cleaning": {
            "color": "#1aa57c",
            "services": [
                ("Grand ménage de printemps", 26, (150, 380), False),
                ("Ménage de fin de bail", 18, (180, 480), False),
                ("Ménage d'emménagement", 9, (160, 420), False),
                ("Nettoyage après travaux", 4, (300, 1100), False),
                ("Shampoing moquette et tapis", 8, (90, 280), False),
                ("Nettoyage de vitres", 10, (80, 240), False),
                ("Repassage à domicile", 9, (40, 90), False),
                ("Ménage location saisonnière", 14, (55, 130), False),
            ],
            "commercial": ["Cabinet Bernard & Associés", "Crèche Les Petits Loups", "La Ruche Coworking", "Studio Yoga Lumière", "Agence Assurances Fabre", "Pharmacie du Centre"],
            "per_day": 2.2,
            "recurring_clients": 45,
            "season": [0.9, 0.9, 1.1, 1.2, 1.15, 1.15, 1.05, 1.0, 1.1, 1.0, 0.95, 1.05],
            "weekday": [1.0, 1.05, 1.05, 1.1, 1.1, 0.4, 0.05],
        },
    },
}

rng = random.Random()


def pick(pairs):
    return rng.choices([p[0] for p in pairs], weights=[p[-1] for p in pairs])[0]


def sid(prefix, n):
    return prefix + "".join(rng.choices(string.ascii_letters + string.digits, k=n))


def ascii_slug(s):
    return "".join(c for c in unicodedata.normalize("NFKD", s.lower()) if c.isascii() and c.isalnum())


def poisson(lam):
    if lam > 30:
        return max(0, round(rng.gauss(lam, math.sqrt(lam))))
    k, p, l = 0, 1.0, math.exp(-lam)
    while True:
        p *= rng.random()
        if p <= l:
            return k
        k += 1


def price(low, high):
    """skewed toward the low end, rounded the way a contractor rounds"""
    v = low + (high - low) * rng.betavariate(1.6, 3.2)
    return int(round(v / 5) * 5 * 100) if v > 100 else int(round(v) * 100)


class Customers:
    def __init__(self, loc):
        self.loc = loc
        self.all = []
        self.emails = set()

    def new(self, at, commercial=None):
        loc = self.loc
        if commercial:
            words = [ascii_slug(w) for w in commercial.split() if ascii_slug(w)]
            slug = words[0] + "".join(w[0] for w in words[1:]) if len(words) > 2 else "".join(words)
            name = commercial
            email = f"{rng.choice(loc['commercial_mailbox'])}@{slug}.{loc['commercial_tld']}"
        else:
            f, l = rng.choice(loc["first"]), rng.choice(loc["last"])
            name = f"{f} {l}"
            fa, la = ascii_slug(f), ascii_slug(l)
            while True:
                local = rng.choice([f"{fa}.{la}", f"{fa}{la}", f"{fa[0]}{la}", f"{fa}{la}{rng.randint(1, 99)}", f"{fa}_{la}", f"{la}{fa[0]}{rng.randint(70, 2005)}"])
                email = f"{local}@{pick(loc['domains'])}"
                if email not in self.emails:
                    break
        self.emails.add(email)
        c = {
            "id": sid("cus_", 14),
            "name": name,
            "email": email,
            "created": int(at.timestamp()),
            "commercial": bool(commercial),
            "card": new_card(loc),
            "bank_debit": bool(commercial) and rng.random() < 0.6,
        }
        self.all.append(c)
        return c


def new_card(loc):
    funding = "credit" if rng.random() < loc["credit_share"] else "debit"
    return {"brand": pick(loc["brands"]), "last4": f"{rng.randint(0, 9999):04d}", "wallet": pick(loc["wallets"]), "exp": f"{rng.randint(1, 12):02d}/{rng.randint(26, 31)}", "funding": funding}


def fee(amount, method, currency):
    """Stripe standard pricing: US 2.9% + 30¢ (ACH 0.8% capped $5); EEA 1.5% + €0.25, premium 1.9% + €0.25, SEPA €0.35"""
    if method["type"] == "us_bank_account":
        return min(500, round(amount * 0.008))
    if method["type"] == "sepa_debit":
        return 35
    if currency == "eur":
        premium = method["brand"] == "amex" or method["funding"] == "credit"
        return round(amount * (0.019 if premium else 0.015)) + 25
    intl = 0.015 if method["brand"] in ("jcb", "diners") else 0
    return round(amount * (0.029 + intl)) + 30


class Ledger:
    def __init__(self, now, loc):
        self.now = now
        self.loc = loc
        self.txs = []

    def charge(self, at, cust, amount, desc, *, bank=False, uncaptured=False):
        if at > self.now:
            return
        loc = self.loc
        if bank:
            method = {"type": loc["bank_type"], "bank": rng.choice(loc["banks"]), "last4": f"{rng.randint(0, 9999):04d}"}
        else:
            method = {"type": "card", **cust["card"]}
        base = {
            "customer": cust["id"],
            "amount": amount,
            "currency": loc["currency"],
            "description": desc,
            "payment_method": method,
        }
        fail_p = 0.008 if bank else 0.045
        if rng.random() < fail_p:
            self.txs.append({**base, "id": sid("pi_3", 23), "created": int(at.timestamp()), "status": "failed", "decline_code": pick(DECLINE_CODES), "fee": 0})
            if rng.random() < 0.72:  # customer retries, often with another card
                if rng.random() < 0.45:
                    cust["card"] = new_card(loc)
                self.charge(at + timedelta(minutes=rng.randint(2, 90)), cust, amount, desc, bank=bank, uncaptured=uncaptured)
            return
        tx = {**base, "id": sid("pi_3", 23), "created": int(at.timestamp()), "status": "succeeded", "fee": fee(amount, method, loc["currency"]), "amount_refunded": 0}
        age = (self.now - at).days
        if uncaptured and age < 7:
            tx.update(status="uncaptured", fee=0)
        elif uncaptured and rng.random() < 0.15:
            tx.update(status="canceled", fee=0, cancellation_reason=rng.choice(["automatic", "requested_by_customer"]))  # hold expired or job called off
        elif not bank and rng.random() < 0.0035:
            d_at = at + timedelta(days=rng.randint(5, 60))
            if d_at < self.now:
                st = pick(DISPUTE_STATUSES) if (self.now - d_at).days > 21 else rng.choice(["needs_response", "under_review"])
                tx.update(status="disputed", dispute={"reason": pick(DISPUTE_REASONS), "status": st, "created": int(d_at.timestamp()), "fee": loc["dispute_fee"]})
        elif rng.random() < 0.018:
            r_at = at + timedelta(days=min(age, int(rng.expovariate(1 / 4))), hours=rng.randint(0, 8))
            if r_at < self.now:
                full = rng.random() < 0.6
                refunded = amount if full else int(round(amount * rng.choice([0.1, 0.15, 0.2, 0.25, 0.5]) / 100) * 100)
                tx.update(status="refunded" if full else "partially_refunded", amount_refunded=refunded, refunded_at=int(r_at.timestamp()), refund_reason=pick(REFUND_REASONS))
        self.txs.append(tx)


def business_time(day, kind, emergency=False):
    if emergency and rng.random() < 0.45:
        h = rng.choice([*range(0, 7), *range(19, 24)])
    elif kind == "cleaning":
        h = int(rng.triangular(9, 19, 15))
    else:
        h = int(rng.triangular(7, 20, 13))
    return day + timedelta(hours=h, minutes=rng.randint(0, 59), seconds=rng.randint(0, 59))


def growth(frac):
    """business grows ~45% over the window with a soft s-curve"""
    return 0.72 + 0.45 / (1 + math.exp(-6 * (frac - 0.45)))


def generate(kind, company, lang, months, now):
    loc = LOCALES[lang]
    cfg = loc[kind]
    start = (now - timedelta(days=round(months * 30.44))).replace(hour=0, minute=0, second=0, microsecond=0)
    days = (now - start).days + 1
    customers = Customers(loc)
    ledger = Ledger(now, loc)
    services = cfg["services"]
    commercial = {name: None for name in cfg["commercial"]}
    recurring = []  # cleaning: [customer, weekday, every_n_weeks, price, start_week, churn_day]

    for d in range(days):
        day = start + timedelta(days=d)
        frac = d / days
        lam = cfg["per_day"] * growth(frac) * cfg["season"][day.month - 1] * cfg["weekday"][day.weekday()]
        if day.month == 8:
            lam *= loc["august"]
        if loc["holiday"](day):
            lam *= 0.35

        if kind == "cleaning":
            target = int(cfg["recurring_clients"] * growth(frac) * (1.08 if day.month in (3, 4, 5) else 1))
            active = [r for r in recurring if r[5] is None or r[5] > d]
            for _ in range(max(0, target - len(active)) if rng.random() < 0.35 else 0):
                c = customers.new(day + timedelta(hours=rng.randint(8, 20)))
                every = pick([(1, 35), (2, 50), (4, 15)])
                pr = price(*loc["recurring_price"][every])
                churn = d + int(rng.expovariate(1 / 260)) if rng.random() < 0.7 else None
                recurring.append([c, rng.randint(0, 4), every, pr, d // 7, churn])
            skip = 0.06 + (1 - loc["august"]) * 0.6 * (day.month == 8)  # clients away for les congés skip visits
            for c, wd, every, pr, w0, churn in active:
                if day.weekday() == wd and (d // 7 - w0) % every == 0 and rng.random() > skip and not loc["holiday"](day):
                    ledger.charge(day + timedelta(hours=rng.randint(15, 19), minutes=rng.randint(0, 59)), c, pr, loc["recurring_name"].format(loc["freq"][every]))
            if day.day == 1:  # office contracts invoiced monthly
                for name in cfg["commercial"][: max(2, int(len(cfg["commercial"]) * (0.4 + frac * 0.6)))]:
                    c = commercial[name] or customers.new(day, commercial=name)
                    commercial[name] = c
                    c.setdefault("monthly", price(*loc["office_monthly"]))
                    ledger.charge(day + timedelta(hours=rng.randint(6, 10)), c, c["monthly"], loc["invoice"], bank=c["bank_debit"])

        for _ in range(poisson(lam)):
            svc = rng.choices(services, weights=[s[1] for s in services])[0]
            name, (lo, hi), emerg_ok = svc[0], svc[2], svc[3]
            emergency = emerg_ok and rng.random() < 0.22
            at = business_time(day, kind, emergency)
            r = rng.random()
            if r < (0.14 if kind == "plumbing" else 0.08):
                cname = rng.choice(cfg["commercial"])
                cust = commercial[cname] or customers.new(at, commercial=cname)
                commercial[cname] = cust
            elif r < 0.36 and customers.all:
                cust = rng.choice(customers.all[-600:])
            else:
                cust = customers.new(at)
            amount = price(lo, hi)
            desc = name
            if emergency and (at.hour < 7 or at.hour >= 19 or at.weekday() >= 5):
                amount += rng.choice(loc["surcharge"]) * 100
                desc = loc["emergency"](name)
            desc = rng.choices([desc, loc["invoice"], None], weights=[64, 26, 10])[0]
            big = amount >= loc["big"] * 100
            if kind == "plumbing" and big and rng.random() < 0.55:  # deposit up front, balance on completion
                dep = int(round(amount * 0.3 / 1000) * 1000)
                ledger.charge(at - timedelta(days=rng.randint(2, 9)), cust, dep, loc["deposit"].format(name) if desc else desc)
                amount -= dep
            bank = cust["bank_debit"] or (big and rng.random() < 0.12)
            uncaptured = kind == "plumbing" and not bank and rng.random() < 0.06
            ledger.charge(at, cust, amount, desc, bank=bank, uncaptured=uncaptured)

    txs = sorted(ledger.txs, key=lambda t: -t["created"])
    used = {t["customer"] for t in txs}
    return {
        "kind": kind,
        "lang": lang,
        "currency": loc["currency"],
        "generated_at": int(now.timestamp()),
        # Stripe descriptors: Latin letters, digits and spaces only, at most 22 characters
        "business": {"name": company, "statement": "".join(c for c in unicodedata.normalize("NFKD", company.upper()) if c.isascii() and (c.isalnum() or c == " "))[:22].strip(), "color": cfg["color"]},
        "customers": [{k: c[k] for k in ("id", "name", "email", "created", "commercial")} for c in customers.all if c["id"] in used],
        "transactions": txs,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("kind", choices=["plumbing", "cleaning"])
    ap.add_argument("name", help="company name shown on the dashboard")
    ap.add_argument("--lang", choices=sorted(LOCALES), default="en")
    ap.add_argument("--months", type=int, default=25)
    ap.add_argument("--seed", type=int)
    ap.add_argument("--out", default="transactions.json")
    a = ap.parse_args()
    if a.seed is not None:
        rng.seed(a.seed)
    data = generate(a.kind, a.name, a.lang, a.months, datetime.now(timezone.utc).astimezone().replace(microsecond=0))
    with open(a.out, "w") as f:
        json.dump(data, f, separators=(",", ":"), ensure_ascii=False)
    n = len(data["transactions"])
    gross = sum(t["amount"] for t in data["transactions"] if t["status"] in ("succeeded", "refunded", "partially_refunded", "disputed"))
    print(f"{a.out}: {data['business']['name']}, {n} payments, {len(data['customers'])} customers, {gross / 100:,.0f} {data['currency'].upper()} gross over {a.months} months")


if __name__ == "__main__":
    main()
