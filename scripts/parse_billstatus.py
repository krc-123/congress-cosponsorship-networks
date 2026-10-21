import xml.etree.ElementTree as ET, glob, csv, json, sys, os
src=sys.argv[1]; out=sys.argv[2]
os.makedirs(out, exist_ok=True)
bills=[]; cos=[]; subj=[]
def tx(e,path):
    x=e.find(path); return (x.text or '').strip() if x is not None and x.text else ''
for f in glob.glob(os.path.join(src,'BILLSTATUS-119*.xml')):
    r=ET.parse(f).getroot().find('bill')
    if r is None: continue
    btype=tx(r,'type'); num=tx(r,'number'); bid=f"{btype}{num}"
    sp=r.find('sponsors/item')
    bills.append({
        'bill_id':bid,'bill_type':btype,'number':num,'title':tx(r,'title'),
        'introduced_date':tx(r,'introducedDate'),'origin_chamber':tx(r,'originChamber'),
        'policy_area':tx(r,'policyArea/name'),
        'sponsor_bioguide':tx(sp,'bioguideId') if sp is not None else '',
        'sponsor_name':tx(sp,'fullName') if sp is not None else '',
        'sponsor_party':tx(sp,'party') if sp is not None else '',
        'sponsor_state':tx(sp,'state') if sp is not None else '',
        'sponsor_district':tx(sp,'district') if sp is not None else '',
        'latest_action_date':tx(r,'latestAction/actionDate'),'latest_action':tx(r,'latestAction/text'),
        'n_cosponsors':len(r.findall('cosponsors/item')),
        'summary':ET.tostring(r.find('summaries/summary/text'),encoding='unicode',method='text').strip()[:2000] if r.find('summaries/summary/text') is not None else '',
        'url':tx(r,'legislationUrl'),
    })
    for c in r.findall('cosponsors/item'):
        cos.append({'bill_id':bid,'bioguide':tx(c,'bioguideId'),'full_name':tx(c,'fullName'),'first_name':tx(c,'firstName'),'last_name':tx(c,'lastName'),
                    'party':tx(c,'party'),'state':tx(c,'state'),'district':tx(c,'district'),'sponsorship_date':tx(c,'sponsorshipDate'),
                    'is_original':tx(c,'isOriginalCosponsor'),'withdrawn_date':tx(c,'sponsorshipWithdrawnDate')})
    for s in r.findall('subjects/legislativeSubjects/item/name'):
        subj.append({'bill_id':bid,'subject':(s.text or '').strip()})
for name,rows in [('bills',bills),('cosponsors',cos),('subjects',subj)]:
    with open(os.path.join(out,name+'.csv'),'w',newline='',encoding='utf-8') as fh:
        w=csv.DictWriter(fh,fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    print(name,len(rows))
