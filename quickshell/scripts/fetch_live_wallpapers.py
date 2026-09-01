#!/usr/bin/env python3
# fetch clean live wallpaper loops (gifs, animated webp, video loops) without sketchy popups
import sys
import json
import urllib.request
import urllib.parse
from pathlib import Path

# Built-in curated high-res aesthetic live loops
CURATED_LIVE = [
    {
        "id": "pixel-rain",
        "title": "pixel city rain",
        "category": "pixel art",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdWU0MXhnbG05Mm11YWN5a2RmcGlkMGt1dXpnNnRpdDJva24ya3A2ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKTDnUxE6uQja4U/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdWU0MXhnbG05Mm11YWN5a2RmcGlkMGt1dXpnNnRpdDJva24ya3A2ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKTDnUxE6uQja4U/200.gif"
    },
    {
        "id": "lofi-bedroom",
        "title": "lo-fi chill midnight",
        "category": "lo-fi",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHU2MnRhZW03NXpiOG1vd24xaWtvbTllYmg0cW81djE5OTl2YnBkayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/LmNwrBhejkK9EFP504/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHU2MnRhZW03NXpiOG1vd24xaWtvbTllYmg0cW81djE5OTl2YnBkayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/LmNwrBhejkK9EFP504/200.gif"
    },
    {
        "id": "cyberpunk-train",
        "title": "neo tokyo train night",
        "category": "cyberpunk",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmtvaDVqbzZ2dHB1YXZsNWF5dWp2b3hpd2g4ODNsd28xNXc1OTU4NiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3oKIPnAiaMCws8nOsE/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmtvaDVqbzZ2dHB1YXZsNWF5dWp2b3hpd2g4ODNsd28xNXc1OTU4NiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3oKIPnAiaMCws8nOsE/200.gif"
    },
    {
        "id": "space-nebula",
        "title": "cosmic galaxy nebula",
        "category": "space",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTR0NGh0d2R2dWd1dmZobnlvaHQ4MGoxbHRid2M4M21udmVvM3JmZSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYEqEzwMWFCg8rm/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTR0NGh0d2R2dWd1dmZobnlvaHQ4MGoxbHRid2M4M21udmVvM3JmZSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYEqEzwMWFCg8rm/200.gif"
    },
    {
        "id": "anime-sunset",
        "title": "anime sunset clouds",
        "category": "anime",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3ZtNW1jM3pxdTF4d2U3OW1ld3F6Z2xyeHR5ZWU2cXhhNDgxbWV1eiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlBO7eyXzSZkJri/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3ZtNW1jM3pxdTF4d2U3OW1ld3F6Z2xyeHR5ZWU2cXhhNDgxbWV1eiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlBO7eyXzSZkJri/200.gif"
    },
    {
        "id": "vaporwave-drive",
        "title": "outrun retro grid drive",
        "category": "synthwave",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExd2RtaXhmdGtrYm5yazN0NnprcXJtY2o3NXdja3E2cGxtZWNwd2s2ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/4Zo41lhzKt6iZ8xff9/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExd2RtaXhmdGtrYm5yazN0NnprcXJtY2o3NXdja3E2cGxtZWNwd2s2ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/4Zo41lhzKt6iZ8xff9/200.gif"
    }
]

def search_live(query=""):
    query = query.strip()
    out_file = Path("/tmp/qs_live_wallpapers.json")
    
    if not query:
        out_file.write_text(json.dumps(CURATED_LIVE, indent=2))
        return
        
    try:
        # Search via Giphy Public Beta API
        encoded_q = urllib.parse.quote(query + " 1080p wallpaper loop")
        api_url = f"https://api.giphy.com/v1/gifs/search?api_key=dc6zaTOxFJmzC&q={encoded_q}&limit=16&rating=g"
        req = urllib.request.Request(api_url, headers={"User-Agent": "quickshell/1.0"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            for item in data.get("data", []):
                images = item.get("images", {})
                orig = images.get("original", {}).get("url")
                thumb = images.get("fixed_height_small", {}).get("url") or orig
                title = item.get("title", "live wallpaper")
                if orig:
                    results.append({
                        "id": item.get("id"),
                        "title": title,
                        "category": query,
                        "url": orig,
                        "thumb": thumb
                    })
            if results:
                out_file.write_text(json.dumps(results, indent=2))
                return
    except Exception as e:
        pass
        
    # Fallback to filtered curated
    filtered = [w for w in CURATED_LIVE if query.lower() in w["title"].lower() or query.lower() in w["category"].lower()]
    out_file.write_text(json.dumps(filtered if filtered else CURATED_LIVE, indent=2))

if __name__ == "__main__":
    q = sys.argv[1] if len(sys.argv) > 1 else ""
    search_live(q)
