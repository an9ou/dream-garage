#!/usr/bin/env python3
"""Fetch today's Hong Kong fuel prices and save them next to the website as data/prices.json.

Why this exists: browsers refuse to let a web page read the Consumer Council's price feed
directly, because that server doesn't send the CORS permission header. A script running on a
server (here, GitHub Actions) has no such restriction. It saves a copy on the same website as
the page, and browsers always allow a page to read files from its own site.

Run by .github/workflows/deploy.yml once a day and on every upload. You can also run it
yourself:  python3 scripts/update_prices.py
"""
import datetime
import json
import pathlib
import sys
import urllib.request

SOURCE = "https://www.consumer.org.hk/pricewatch/oilwatch/opendata/oilprice.json"
OUT = pathlib.Path(__file__).resolve().parent.parent / "data" / "prices.json"


def fetch():
    req = urllib.request.Request(SOURCE, headers={"User-Agent": "DreamGarage-price-update/1.0 (GitHub Actions)"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def clean(raw):
    """Keep only what the page uses, and refuse anything that doesn't look like real prices."""
    if not isinstance(raw, list) or not raw:
        raise ValueError("expected a non-empty list of fuel types")
    out = []
    for fuel in raw:
        prices = []
        for p in fuel.get("prices", []):
            price = str(p.get("price", "")).strip()
            float(price)  # raises if the price isn't a number
            prices.append({"vendor": {"en": p["vendor"]["en"], "tc": p["vendor"].get("tc", "")}, "price": price})
        if not prices:
            raise ValueError(f"no prices for {fuel.get('type')}")
        out.append({"type": {"en": fuel["type"]["en"], "tc": fuel["type"].get("tc", "")}, "prices": prices})
    return out


def main():
    try:
        data = clean(fetch())
    except Exception as err:  # keep the previous prices.json untouched
        print(f"Could not update prices: {err}", file=sys.stderr)
        return 1
    OUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "source": SOURCE,
        "fetched_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "data": data,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    summary = ", ".join(f"{f['type']['en']} {min(float(p['price']) for p in f['prices']):.2f}" for f in data)
    print(f"Saved {OUT.relative_to(OUT.parent.parent)} — {summary} (HK$/L)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
