# Who actually cosponsors maternal health, deaf and hard of hearing, and disability bills

Every bill introduced in the 119th Congress (16,522 of them as of 20 October 2026), classified into three policy areas I work in, with the sponsor and every cosponsor of each one. From that: the coalitions behind each bill, the members who sign the most and the ones who sign nothing, the handful of Republicans who bridge the two parties on these issues, and a targeting list with each member's official Instagram and X handles, built on my `congress-social-media-handles` repository.

182 bills, 497 members, 2,657 cosponsorships. Built from the Government Publishing Office's BILLSTATUS bulk data, which needs no API key, so it can be rerun any week.

An interactive version of the network is in `docs/index.html` (serve the `docs` folder, for example with GitHub Pages).

## What the data shows

- **Maternal health is a one-party issue in the House; disability is not.** 62 of the 87 maternal health bills have a Democratic sponsor and only 39 percent have at least one signer from each party. Disability bills split evenly (39 Democratic sponsors, 42 Republican) and 52 percent are bipartisan. The 16 deaf and hard of hearing bills are the most bipartisan of the three at 81 percent, though most of them are small.
- **The largest maternal health coalition has no Republicans at all.** The Momnibus Act (H.R. 7973) has 215 signers, every one a Democrat. Its component bills travel as a bloc: Social Determinants for Moms, Data to Save Moms, the Perinatal Workforce Act, and Justice for Incarcerated Moms share 84 to 91 percent of their signers with each other. One coalition, many bills.
- **The maternal health bills that do cross the aisle are about rural access and postpartum care.** Rural Obstetrics Readiness (34 D, 15 R), Optimizing Postpartum Outcomes (33 D, 9 R), and the Preventing Maternal Deaths Reauthorization (20 D, 5 R). In the Senate the Pregnant Students' Rights Act has 25 Republican signers and no Democrats; the Senate Momnibus has 28 Democrats and no Republicans.
- **Disability bills get bigger bipartisan coalitions than anything in maternal health.** IDEA Full Funding (160 D, 16 R, the second-largest coalition in the dataset), the SSI Savings Penalty Elimination Act (exactly 21 and 21), the Blind Americans Return to Work Act (34 D, 21 R), and the Charlotte Woodward Organ Transplant Discrimination Prevention Act (13 D, 16 R, Republican-led).
- **The Alice Cogswell and Anne Sullivan Macy Act, the main deaf and blind education bill, has 31 House signers (27 D, 4 R) and two in the Senate.** The largest deaf-related coalition is the Medicare Dental, Vision, and Hearing Benefit Act with 132 Democrats. The Medicare Audiology Access Improvement Act is the only hearing bill with a real bipartisan base (22 D, 17 R).
- **Fifty-five members signed none of the 182 bills:** 48 House Republicans, 3 House Democrats, and four senators (King, Schumer, Armstrong, Johnson). They are listed in `output/members_signing_none_of_these_bills.csv`.
- **A small set of Republicans does most of the cross-party work.** Brian Fitzpatrick (PA-1) signed 22 of these bills, 82 percent of them alongside Democrats, and has the highest bridge score of any Republican. Mike Lawler, Ashley Hinson, David Valadao, Glenn Thompson, Juan Ciscomani, and Don Bacon follow. In the Senate it is Lisa Murkowski (7 bills, 69 percent cross-party) and then a steep drop.
- **The most prolific signers are who you would expect.** Eleanor Holmes Norton signed 44 of the 182 bills, then Rashida Tlaib (26), Steve Cohen (24), Adelita Grijalva (23), and Lauren Underwood (22, almost all maternal health). In the Senate: Booker (19), Gillibrand (14), Duckworth (13), Tina Smith (12).

### By topic

| Topic | Bills | House | Senate | Median signers | Bipartisan | D sponsored | R sponsored |
|---|---|---|---|---|---|---|---|
| Maternal health | 87 | 52 | 35 | 6 | 34 (39%) | 62 | 25 |
| Disability | 81 | 56 | 25 | 4 | 42 (52%) | 39 | 42 |
| Deaf and hard of hearing | 16 | 11 | 5 | 8.5 | 13 (81%) | 9 | 6 |

Ten abortion-policy bills (bans, mifepristone restrictions, pregnancy resource center funding) were tagged separately and kept out of the maternal health network. They are a different fight with a different coalition; they are listed in `output/abortion_policy_bills.csv`.

### Largest coalitions

| Bill | Title | Signers | D | R |
|---|---|---|---|---|
| H.R. 7973 | Momnibus Act | 215 | 215 | 0 |
| H.R. 2598 | IDEA Full Funding Act | 176 | 160 | 16 |
| H.R. 2045 | Medicare Dental, Vision, and Hearing Benefit Act | 132 | 132 | 0 |
| H.R. 8055 | Extending WIC for New Moms Act | 91 | 91 | 0 |
| H.R. 8907 | IMPACT to Save Moms Act | 73 | 73 | 0 |
| H.R. 8397 | Protecting Moms and Babies Against Climate Change Act | 72 | 72 | 0 |
| H.R. 8807 | Maternal Health Pandemic Response Act | 69 | 69 | 0 |
| H.R. 8153 | Maternal Vaccination Act | 67 | 67 | 0 |
| H.R. 4664 | Stop Shackling and Detaining Pregnant Women Act | 60 | 60 | 0 |
| H.R. 1175 | Blind Americans Return to Work Act | 55 | 34 | 21 |

More tables (most active members by chamber, bridges, coalition overlap) are in `output/readme_tables.md`.

![Network diagram of House members who signed two or more maternal health bills together. A dense cluster of about 150 Democratic members sits at the center left with the most active members labeled; a separate cluster of about 20 Republicans sits at the lower right, connected to the Democratic core by a single large Republican node and a few thin ties.](figures/fig1_house_maternal_network.png)

![Horizontal stacked bar chart of the 25 largest coalitions, each bar split into Democratic, Independent, and Republican signers. The Momnibus Act leads at 215, all Democratic; IDEA Full Funding follows at 176 with a small Republican segment; most of the remaining maternal health bars are entirely Democratic, while the disability bars show visible Republican segments.](figures/fig4_largest_coalitions.png)

![Lollipop chart of the twenty House members with the highest betweenness in the cosponsorship network. Eleanor Holmes Norton is far ahead; then Josh Gottheimer and Brian Fitzpatrick, followed by Claudia Tenney, Kat Cammack, and Ashley Hinson, with Republicans in red and Democrats in blue.](figures/fig5_house_bridges.png)

## The targeting list

`output/targeting_list.csv` has one row per member who signed any of these bills: chamber, party, state, district, how many bills they signed in each topic, the share of their co-signers who came from the other party, their bridge score, and their official Instagram and X handles. Sort by `cross_party_share` to find the Republicans who are already on record with Democrats on these issues, or filter by state before a Hill Day. 488 of the 497 members matched to a handle; the nine that did not are delegates and resident commissioners, who are not in the handles table, plus two seats that changed hands.

## Method

1. **Bills.** GPO's [BILLSTATUS bulk data](https://www.govinfo.gov/bulkdata/BILLSTATUS/119) for House and Senate bills of the 119th Congress, downloaded 20 October 2026. `scripts/parse_billstatus.py` turns the XML into three tables: bills, cosponsors, and CRS legislative subjects.
2. **Classification.** `scripts/classify_bills.py` tags a bill as maternal health, deaf and hard of hearing, or disability if its title matches a topic pattern, or its CRS summary is short and matches three or more distinct terms, or CRS assigned a relevant subject term. Omnibus and appropriations bills are excluded. A few dozen bills were then reviewed by hand and reclassified or excluded; the pattern list and every manual override are in the script with the reason. Abortion-policy bills are tagged `abortion` and set aside.
3. **Signers.** The sponsor plus every cosponsor who did not withdraw.
4. **Networks.** For each chamber and topic, a member-to-member graph where the edge weight is the number of topic bills both signed. Bridge score is normalized betweenness on that graph, computed with `igraph`. Cross-party share is the proportion of a member's fellow signers, across all their topic bills, who belong to the other major party. Coalition overlap between bills is the Jaccard index of their signer sets.
5. **Handles.** House members joined by state and district; senators by state and surname; from `congress-social-media-handles`.

### Limits

- CRS summaries lag introduction by weeks or months, so recently introduced bills with bare titles can be missed. The title patterns catch most of them; the overrides catch the ones I knew to look for. If you work in one of these areas and see a bill missing, open an issue.
- "Disability" is broad. The set includes special education, ABLE accounts, SSI, accessibility, autism, and the ADA, and excludes veterans' disability compensation bills unless they are also about accessibility. Someone else would draw that line differently; the script makes the line visible.
- Cosponsorship is cheap. A member who signs 20 bills is not necessarily doing more than one who sponsors a single bill and moves it through committee. This is a map of stated positions, not of effort.
- Betweenness on a cosponsorship projection rewards members who sign across many bills (Norton, who signs nearly everything, tops every list). The cross-party share is the better guide to who actually works with the other side.

## Reproducing it

```
# 1. Download the bulk data (about 46 MB)
curl -LO https://www.govinfo.gov/bulkdata/BILLSTATUS/119/hr/BILLSTATUS-119-hr.zip
curl -LO https://www.govinfo.gov/bulkdata/BILLSTATUS/119/s/BILLSTATUS-119-s.zip
mkdir -p raw && unzip -q -o BILLSTATUS-119-hr.zip -d raw && unzip -q -o BILLSTATUS-119-s.zip -d raw

# 2. Parse, classify, build the roster (the roster needs the handles repo's data folder)
python3 scripts/parse_billstatus.py raw parsed
python3 scripts/classify_bills.py            # reads parsed/, writes parsed/topic_bills.csv
python3 scripts/build_roster.py parsed ../congress-social-media-handles/data data/members.csv
cp parsed/topic_bills.csv parsed/topic_cosponsors.csv data/

# 3. Analysis (R)
Rscript analysis.R
```

`analysis.R` needs `tidyverse`, `igraph`, `jsonlite`, and `scales`; it installs any that are missing. It writes `output/`, `figures/`, and `docs/graph.json`. To see the interactive graph, serve `docs/` over HTTP (GitHub Pages: Settings → Pages → Deploy from branch, `main`, `/docs`).

## Files

| Path | What it is |
|---|---|
| `data/topic_bills.csv` | The 192 classified bills (182 in the three topics plus 10 abortion-policy bills): id, title, sponsor, party, introduced date, CRS summary, policy area, subjects, topics, latest action |
| `data/topic_cosponsors.csv` | One row per cosponsorship: bill, member, party, state, district, date, original cosponsor flag, withdrawal date |
| `data/members.csv` | The 497 members with chamber, party, state, district, and handles |
| `output/bill_summary.csv` | Signers per bill by party, bipartisan flag |
| `output/member_summary.csv` | Bills signed per topic, cross-party share, degree, betweenness, PageRank |
| `output/targeting_list.csv` | The advocacy view of member_summary with handles |
| `output/members_signing_none_of_these_bills.csv` | The 55 members who signed nothing in the three topics |
| `output/bill_coalition_overlap.csv` | Jaccard overlap between every pair of bills with five or more signers, by topic |
| `output/abortion_policy_bills.csv` | The ten bills set aside |
| `output/topic_summary.csv`, `output/readme_tables.md`, `output/headline_numbers.txt` | Summary tables |
| `figures/` | The six charts |
| `docs/index.html`, `docs/graph.json` | The interactive network |
| `scripts/` | The three Python build steps |
| `analysis.R` | The analysis |

Code is MIT licensed. The data is derived from U.S. government works and is released under CC0.
