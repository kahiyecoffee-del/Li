#!/usr/bin/env python3
"""Wikimedia Commons'tan sahne görseli bulur/indirir (yalnızca serbest lisanslı).

Kullanım:
    python3 araclar/gorsel.py ara "Death of Socrates David"
    python3 araclar/gorsel.py video-ara "Colosseum Rome"
    python3 araclar/gorsel.py indir "File:David - The Death of Socrates.jpg"   (görsel ya da video)

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
UA = "StoryVideoBot/1.0 (https://github.com/kahiyecoffee-del/Li; educational video renderer) python-urllib"
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


VIDEO_EXT = (".webm", ".ogv", ".mp4", ".mpg", ".mpeg")


def is_video(title):
    return title.lower().endswith(VIDEO_EXT)


def _info(pages, video=None):
    out = []
    for p in pages.values():
        if "imageinfo" not in p or p["title"].lower().endswith((".pdf", ".djvu", ".tif", ".tiff", ".ogg", ".oga", ".mp3",
                                                                ".wav", ".flac", ".mid")):
            continue
        if video is not None and is_video(p["title"]) != video:
            continue
        ii = p["imageinfo"][0]
        m = ii.get("extmetadata", {})
        out.append(dict(title=p["title"], width=ii.get("width"), height=ii.get("height"),
                        license=_clean(m.get("LicenseShortName", {}).get("value")),
                        artist=_clean(m.get("Artist", {}).get("value"))[:120],
                        url=(ii.get("url") if is_video(p["title"]) else (ii.get("thumburl") or ii.get("url"))).replace(
                            "://thumb.wikimedia.org/", "://upload.wikimedia.org/"),
                        duration=ii.get("duration"), page=ii.get("descriptionurl")))
    return out


def licensed(info):
    lic = (info.get("license") or "").lower()
    return any(k in lic for k in OK_LICENSES) and "nc" not in lic and "nd" not in lic


def search(query, n=10, video=False):
    q = ("filetype:video " + query) if video else query
    d = _api(action="query", generator="search", gsrsearch=q, gsrnamespace=6, gsrlimit=n, prop="imageinfo",
             iiprop="url|extmetadata|size", iiurlwidth=1920)
    return _info(d.get("query", {}).get("pages", {}), video=video)


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
    if is_video(title):  # önce 720p/480p dönüştürülmüş kopyayı dene (daha küçük)
        name = os.path.splitext(name)[0] + ".webm"
        orig = info["url"]
        parts = orig.split("/wikipedia/commons/")
        data = None
        if len(parts) == 2:
            fn = parts[1].split("/")[-1]
            for q in ("720p.vp9.webm", "720p.webm", "480p.vp9.webm", "480p.webm"):
                try:
                    data = _get(f"{parts[0]}/wikipedia/commons/transcoded/{parts[1]}/{fn}.{q}", tries=3)
                    break
                except Exception:
                    continue
        if data is None:
            data = _get(orig)
    else:
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
    if cmd in ("ara", "video-ara"):
        for i in search(arg, video=(cmd == "video-ara")):
            mark = "✔" if licensed(i) else "✘"
            dur = f" {i['duration']:.0f}sn" if i.get("duration") else ""
            print(f"{mark} {i['title']}  [{i['width']}x{i['height']}{dur}]  {i['license']}  — {i['artist'][:50]}")
    elif cmd == "indir":
        path, info = fetch(arg)
        print(path, "|", credit_line(info))
