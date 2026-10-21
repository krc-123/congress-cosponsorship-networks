"""Build data/members.csv: every member who sponsored or cosponsored a topic bill,
joined to the official Instagram and X handles published in the
congress-social-media-handles repository.

Usage: python3 build_roster.py <parsed_dir> <handles_data_dir> <out_csv>
"""
import csv, re, sys, collections

parsed, handles, out = sys.argv[1], sys.argv[2], sys.argv[3]
US = {'Alabama':'AL','Alaska':'AK','Arizona':'AZ','Arkansas':'AR','California':'CA','Colorado':'CO','Connecticut':'CT','Delaware':'DE','District of Columbia':'DC','Florida':'FL','Georgia':'GA','Hawaii':'HI','Idaho':'ID','Illinois':'IL','Indiana':'IN','Iowa':'IA','Kansas':'KS','Kentucky':'KY','Louisiana':'LA','Maine':'ME','Maryland':'MD','Massachusetts':'MA','Michigan':'MI','Minnesota':'MN','Mississippi':'MS','Missouri':'MO','Montana':'MT','Nebraska':'NE','Nevada':'NV','New Hampshire':'NH','New Jersey':'NJ','New Mexico':'NM','New York':'NY','North Carolina':'NC','North Dakota':'ND','Ohio':'OH','Oklahoma':'OK','Oregon':'OR','Pennsylvania':'PA','Rhode Island':'RI','South Carolina':'SC','South Dakota':'SD','Tennessee':'TN','Texas':'TX','Utah':'UT','Vermont':'VT','Virginia':'VA','Washington':'WA','West Virginia':'WV','Wisconsin':'WI','Wyoming':'WY'}

def load(f):
    return list(csv.DictReader(open(f"{handles}/{f}", encoding="utf-8")))

def key_h(r):
    d = r["district"].strip()
    d = "0" if d.lower() in ("at-large", "al", "0", "") else d
    return (US.get(r["state"], r["state"]), d)

house = {}
for r in load("house_instagram.csv"):
    house.setdefault(key_h(r), {}).update({"member": r["member"], "instagram": r["instagram_handle"], "instagram_url": r["profile_link"]})
for r in load("house_x.csv"):
    house.setdefault(key_h(r), {}).update({"member": r["member"], "x": r["x_handle"], "x_url": r["profile_link"]})
sen = collections.defaultdict(list)
for r in load("senate_instagram.csv"):
    sen[US.get(r["state"], r["state"])].append({"member": r["member"], "instagram": r["instagram_handle"], "instagram_url": r["profile_link"]})
for r in load("senate_x.csv"):
    for e in sen[US.get(r["state"], r["state"])]:
        if e["member"] == r["member"]:
            e.update({"x": r["x_handle"], "x_url": r["profile_link"]})

mem = {}
for r in csv.DictReader(open(f"{parsed}/topic_bills.csv", encoding="utf-8")):
    if r["sponsor_bioguide"]:
        mem[r["sponsor_bioguide"]] = {"bioguide": r["sponsor_bioguide"], "full_name": r["sponsor_name"], "party": r["sponsor_party"],
                                      "state": r["sponsor_state"], "district": r["sponsor_district"],
                                      "chamber": "House" if r["bill_type"].startswith("H") else "Senate"}
for r in csv.DictReader(open(f"{parsed}/topic_cosponsors.csv", encoding="utf-8")):
    mem.setdefault(r["bioguide"], {"bioguide": r["bioguide"], "full_name": r["full_name"], "party": r["party"], "state": r["state"],
                                   "district": r["district"], "chamber": "House" if r["bill_id"].startswith("H") else "Senate"})

def lastname(full):
    m = re.match(r"(?:Rep\.|Sen\.|Del\.|Rescom\.)\s+(.+?),", full)
    return (m.group(1) if m else full).lower()

rows = []; matched = 0
for m in mem.values():
    m = dict(m); m.update({"instagram": "", "instagram_url": "", "x": "", "x_url": "", "handles_match": ""})
    if m["chamber"] == "House":
        e = house.get((m["state"], m["district"] or "0"))
        if e:
            m.update({k: e.get(k, "") for k in ("instagram", "instagram_url", "x", "x_url")}); m["handles_match"] = "state+district"; matched += 1
    else:
        ln = lastname(m["full_name"]); c = [e for e in sen.get(m["state"], []) if ln in e["member"].lower()]
        if len(c) == 1:
            m.update({k: c[0].get(k, "") for k in ("instagram", "instagram_url", "x", "x_url")}); m["handles_match"] = "state+last name"; matched += 1
    rows.append(m)
rows.sort(key=lambda r: (r["chamber"], r["state"], r["full_name"]))
with open(out, "w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print(f"members {len(rows)}, matched to handles {matched}")
