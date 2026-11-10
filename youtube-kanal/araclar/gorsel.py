#!/usr/bin/env python3
"""Wikimedia Commons'tan sahne görseli bulur/indirir (yalnızca serbest lisanslı).

Kullanım:
    python3 araclar/gorsel.py ara "Death of Socrates David"
    python3 araclar/gorsel.py indir "File:David - The Death of Socrates.jpg"

İndirilenler gorseller/ klasörüne, kaynak ve lisans bilgisi gorseller/kaynaklar.json'a yazılır.
Video açıklamasına atıf satırları otomatik eklenir.
"""
import hashlib
import json
import os
import re
import sys
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "gorseller")
DB = os.path.join(DIR, "kaynaklar.json")
API = "https://commons.wikimedia.org/w/api.php"
UA = "StoryVideoBot/1.0 (educational video renderer)"
OK_LICENSES = ("public domain", "pd", "cc0", "cc by", "cc-by")


def _get(url, tries=6):
    import time
    import urllib.error
    for k in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code != 429 or k == tries - 1:
                raise
            time.sleep(3 * 2 ** k)


def _api(**params):
    params.update(format="json")
    return json.loads(_get(API + "?" + urllib.parse.urlencode(params)))


def _clean(html):
    return re.sub(r"<[^>]+>", "", html or "").strip()


def _info(pages):
    out = []
    for p in pages.values():
        if "imageinfo" not in p or p["title"].lower().endswith((".pdf", ".djvu", ".webm", ".ogv", ".tif", ".tiff")):
            continue
        ii = p["imageinfo"][0]
        m = ii.get("extmetadata", {})
        out.append(dict(title=p["title"], width=ii.get("width"), height=ii.get("height"),
                        license=_clean(m.get("LicenseShortName", {}).get("value")),
                        artist=_clean(m.get("Artist", {}).get("value"))[:120],
                        url=(ii.get("thumburl") or ii.get("url")).replace("://thumb.wikimedia.org/", "://upload.wikimedia.org/"),
                        page=ii.get("descriptionurl")))
    return out


def licensed(info):
    lic = (info.get("license") or "").lower()
    return any(k in lic for k in OK_LICENSES) and "nc" not in lic and "nd" not in lic


def search(query, n=10):
    d = _api(action="query", generator="search", gsrsearch=query, gsrnamespace=6, gsrlimit=n, prop="imageinfo",
             iiprop="url|extmetadata|size", iiurlwidth=1920)
    return _info(d.get("query", {}).get("pages", {}))


def _db():
    if os.path.exists(DB):
        with open(DB, encoding="utf-8") as f:
            return json.load(f)
    return {}


def fetch(title):
    """Görseli indirir (önbellekli), yerel yolu döndürür."""
    os.makedirs(DIR, exist_ok=True)
    db = _db()
    if title in db and os.path.exists(os.path.join(DIR, db[title]["file"])):
        return os.path.join(DIR, db[title]["file"]), db[title]
    d = _api(action="query", titles=title, prop="imageinfo", iiprop="url|extmetadata|size", iiurlwidth=1920)
    infos = _info(d.get("query", {}).get("pages", {}))
    if not infos:
        raise SystemExit(f"Görsel bulunamadı: {title}")
    info = infos[0]
    if not licensed(info):
        raise SystemExit(f"Lisans uygun değil ({info['license']}): {title}")
    ext = os.path.splitext(urllib.parse.urlparse(info["url"]).path)[1].lower() or ".jpg"
    if ext in (".pdf", ".tif", ".tiff", ".svg"):
        ext = ".jpg"
    name = re.sub(r"[^a-zA-Z0-9]+", "_", title[5:])[:60] + "_" + hashlib.md5(title.encode()).hexdigest()[:6] + ext
    data = _get(info["url"])
    with open(os.path.join(DIR, name), "wb") as f:
        f.write(data)
    info["file"] = name
    db[title] = info
    with open(DB, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)
    return os.path.join(DIR, name), info


def credit_line(info):
    artist = info.get("artist") or "Unknown"
    return f"{info['title'][5:]} — {artist} — {info.get('license')} — {info.get('page')}"


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    cmd, arg = sys.argv[1], " ".join(sys.argv[2:])
    if cmd == "ara":
        for i in search(arg):
            mark = "✔" if licensed(i) else "✘"
            print(f"{mark} {i['title']}  [{i['width']}x{i['height']}]  {i['license']}  — {i['artist'][:50]}")
    elif cmd == "indir":
        path, info = fetch(arg)
        print(path, "|", credit_line(info))
