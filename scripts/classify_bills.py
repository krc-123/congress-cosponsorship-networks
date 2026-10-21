import csv, re, collections, json, sys
bills=list(csv.DictReader(open('parsed/bills.csv',encoding='utf-8')))
subj=collections.defaultdict(set)
for r in csv.DictReader(open('parsed/subjects.csv',encoding='utf-8')): subj[r['bill_id']].add(r['subject'])
PAT={
 'maternal': re.compile(r"\b(maternal|maternity|pregnan\w*|postpartum|midwi\w*|doulas?|obstetric\w*|childbirth|birth centers?|birthing|prenatal|perinatal|lactation|breastfeed\w*|stillbirth\w*|miscarriage\w*|momnibus|neonatal|moms)\b", re.I),
 'deaf_hoh': re.compile(r"\b(deaf\w*|hard of hearing|hearing loss|hearing aids?|hearing health|hearing care|cochlear|sign language|captioning|captioned|audiolog\w*|early hearing|hearing screening|deafblind|hearing impair\w*|hearing devices?)\b", re.I),
 'disability': re.compile(r"\b(americans with disabilities act|ADA\b|special education|individuals with disabilities education|assistive technolog\w*|developmental disabilit\w*|intellectual disabilit\w*|autis\w*|visually impaired|blindness|(?:people|persons|individuals|children|students|adults|workers|americans|youth|veterans) (?:who are blind|with disabilities)|disability rights|wheelchair\w*|home and community.based services|supported decision.making|section 504|disability (?:community|services|employment|inclusion|discrimination|benefits|insurance)|ABLE accounts?|SSI\b|supplemental security income|paralysis|accessible (?:voting|transportation|housing|design|technology|websites?|formats?))\b", re.I),
}
EXCL=re.compile(r"appropriations|national defense authorization|budget resolution|continuing resolution|Equality Act|Safe Schools Improvement|DOC Access|Child Care for Every Community|Association Health Plans|Living Donor Protection|Korematsu|Words Matter|Retired Pay Restoration|FEDVIP|Veterans STAND|AM Radio|Veterans Infertility|Telehealth Coverage Act|Expanded Telehealth Access|Legalizing Premium Health Care|Rural Veterans. Improved Access|Alaska Native Settlement|Public Safety Officers|Recycling Infrastructure|Safe Hydration|Social Security Expansion|Entrepreneurs with Disabilities Reporting", re.I)
VET=re.compile(r"\b(veterans?|servicemembers?|department of veterans affairs|VA|military|armed forces)\b", re.I)
out=[]
for b in bills:
    s=subj[b['bill_id']]; title=b['title']; summ=b['summary']
    topics=[]
    for t,p in PAT.items():
        in_title=bool(p.search(title)); n_sum=len(set(m.group(0).lower() for m in p.finditer(summ)))
        # Title match, or a short focused summary with several distinct hits. Long omnibus-style
        # summaries that merely mention a term do not qualify.
        hit = in_title or (n_sum>=3 and len(summ)<1200)
        if t=='maternal' and s & {"Women's health"} and re.search(r"matern|pregnan|postpartum|birth",summ,re.I): hit=True
        if t=='disability' and s & {"Disability and health-based discrimination","Disability and paralysis"}: hit=True
        if t=='deaf_hoh' and "Hearing, speech, and vision care" in s: hit=True
        if hit: topics.append(t)
    # Abortion policy bills are tagged separately rather than counted as maternal health
    if 'maternal' in topics and re.search(r"\b(abortion\w*|heartbeat|unborn|pregnancy (?:resource |care )?centers?|born.alive|mifepristone|chemical abortion)\b", title+' '+summ, re.I) and not re.search(r"\b(maternal|postpartum|midwi\w*|doula\w*|obstetric\w*|prenatal|perinatal|breastfeed\w*|lactation)\b", title, re.I):
        topics=[t for t in topics if t!='maternal']+['abortion']
    # Manual overrides after reading the bill text: abortion-policy bills whose summaries were
    # missing or ambiguous, and two bills the regexes caught for the wrong reason.
    OVERRIDE={'HR685':['abortion'],'S3697':['abortion'],'S1630':['abortion'],'HR2469':['abortion'],
              'HR1175':['disability'],'HR6444':[],'HR2884':[],'S721':[],'S71':[],'HR248':[],
              # bills whose titles carry no keyword but which are squarely in scope
              'HR9195':['deaf_hoh','disability'],'S4676':['deaf_hoh','disability'],   # Alice Cogswell and Anne Sullivan Macy Act
              'HR2045':['deaf_hoh'],'S939':['deaf_hoh'],                              # Medicare dental, vision and hearing benefit
              'HR3648':['deaf_hoh'],                                                   # Transit Captions Innovations Act
              'S1277':['disability'],'HR2598':['disability'],'HR8465':['disability'],  # IDEA Full Funding; Funding Early Childhood is the Right IDEA
              'HR4116':['disability'],'S5125':['disability'],                          # Disability Access to Transportation; Inclusive Home Design
              'HR1436':['disability'],'S627':['disability'],'HR2392':['disability'],'HR9384':['disability'],  # ABLE account bills
              'HR5769':['disability'],'S3010':['disability']}                          # 21st Century Dyslexia Act
    if b['bill_id'] in OVERRIDE: topics=OVERRIDE[b['bill_id']]
    elif EXCL.search(title): topics=[]
    if topics:
        b2=dict(b); b2['topics']='|'.join(topics); b2['subjects']='|'.join(sorted(s)); b2['veteran_related']='TRUE' if VET.search(title) else 'FALSE'
        out.append(b2)
cnt=collections.Counter(t for b in out for t in b['topics'].split('|'))
print(cnt, len(out), file=sys.stderr)
with open('parsed/topic_bills.csv','w',newline='',encoding='utf-8') as fh:
    w=csv.DictWriter(fh,fieldnames=list(out[0].keys())); w.writeheader(); w.writerows(out)
