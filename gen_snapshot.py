# -*- coding: utf-8 -*-
"""生成脱敏快照:拉私有 VIPvip/state.json → 清空凭据 → 写 VipPanel/Resources/snapshot.json"""
import json
import os
import ssl
import sys
import time
import urllib.request

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE


def get(url, headers=None, tries=5):
    h = {"User-Agent": "snapshot"}
    h.update(headers or {})
    for i in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=60, context=ctx) as r:
                body = r.read()
            if body:
                return json.loads(body)
        except Exception as e:
            print(f"  retry {i+1}: {e}", file=sys.stderr)
        time.sleep(2)
    raise RuntimeError("GET failed: " + url)


def main():
    obj = get("https://api.github.com/repos/shake24342/VIPvip/contents/state.json?ref=main",
              {"Authorization": "Bearer " + os.environ["GH_TOKEN"],
               "Accept": "application/vnd.github.v3+json"})
    st = json.loads(obj["content"].replace("\n", ""))
    snap = {
        "accounts": [],
        "startDate": st.get("startDate", ""),
        "apiDomain": st.get("apiDomain", ""),
        "domainHistory": st.get("domainHistory", []),
        "staggerDate": st.get("staggerDate", ""),
        "lastConfirmDate": st.get("lastConfirmDate", ""),
    }
    for a in st.get("accounts", []):
        snap["accounts"].append({
            "name": a.get("name", ""), "card": "", "pwd": "", "token": "", "id": "",
            "days": a.get("days", 0), "slot": a.get("slot", 0), "delay": a.get("delay", 0),
            "dead": a.get("dead", False), "failCount": a.get("failCount", 0),
            "signedToday": a.get("signedToday", False), "signedYesterday": False,
            "vip7ExpireAt": "", "vipValidDate": a.get("vipValidDate", 0),
            "lastRunDate": a.get("lastRunDate", ""),
        })
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "VipPanel", "Resources", "snapshot.json")
    json.dump(snap, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    leak = [a for a in snap["accounts"] if a["token"] or a["card"] or a["pwd"]]
    print(f"snapshot OK | 账号 {len(snap['accounts'])} | 确认日 {snap['lastConfirmDate']} | 残留: {'FAIL '+str(len(leak)) if leak else '无'}")


if __name__ == "__main__":
    main()
