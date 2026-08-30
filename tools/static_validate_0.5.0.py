#!/usr/bin/env python3
from pathlib import Path
import csv, re, sys, hashlib
ROOT=Path(__file__).resolve().parents[1]
results=[]
def check(cond,name,detail=''): results.append(('PASS' if cond else 'FAIL',name,detail))
def read(p): return p.read_text(encoding='utf-8')

# Metadata
D=read(ROOT/'DESCRIPTION')
for field in ['Package: agriGrowthFlow','Version: 0.5.0','License: MIT + file LICENSE','Depends: R (>= 4.2.0)']:
    check(field in D,f'DESCRIPTION contains {field}')
title=next((x.split(': ',1)[1] for x in D.splitlines() if x.startswith('Title: ')),'')
check(len(title)<=65,'DESCRIPTION title length suitable',f'{len(title)} characters')
for dep in ['minpack.lm','nlme','mgcv','scam','refund','fdapace','brms','posterior','loo','cmdstanr','knitr','rmarkdown','testthat']:
    check(dep in D,f'Dependency declared: {dep}')
check('Version 0.5.0' in read(ROOT/'README.md'),'README identifies version 0.5.0')
check(read(ROOT/'NEWS.md').startswith('# agriGrowthFlow 0.5.0'),'NEWS begins with version 0.5.0')
check('R package version 0.5.0' in read(ROOT/'inst/CITATION'),'CITATION identifies version 0.5.0')
for f in ['REFERENCE_AUDIT_0.5.0.md','IMPLEMENTATION_SPEC_0.5.0.md','NAMESPACE_RD_SYNC_0.5.0.md']:
    check((ROOT/f).exists(),f'0.5.0 artifact present: {f}')

# API and S3
ns=read(ROOT/'NAMESPACE')
exports=re.findall(r'^export\(([^)]+)\)',ns,re.M)
s3=re.findall(r'^S3method\(([^,]+),([^)]+)\)',ns,re.M)
rfiles=sorted((ROOT/'R').glob('*.R'))
rtext='\n'.join(read(p) for p in rfiles)
defs=set(re.findall(r'^([A-Za-z.][A-Za-z0-9._]*)\s*<-\s*function\s*\(',rtext,re.M))
check(len(exports)==69,'Public API export count',f'{len(exports)} exports')
check(len(exports)==len(set(exports)),'No duplicate exports')
new=['growth_multiphase','growth_diphasic','growth_stability','growth_changepoint','growth_event','growth_defoliation','growth_compensation','growth_density','growth_neighbor','growth_competition','growth_threshold','growth_plateau_time','growth_harvest_opt','growth_schedule','growth_design_sim','growth_power']
for fn in exports: check(fn in defs,f'Exported function defined: {fn}')
for fn in new: check(fn in exports,f'0.5.0 function exported: {fn}')
check(len(s3)==38,'S3 registration count',f'{len(s3)} methods')
for g,c in s3: check(f'{g}.{c}' in defs,f'S3 method defined: {g}.{c}')
check(len(rfiles)==21,'R source-file count',f'{len(rfiles)} files')

# R delimiter balance
def strip_r(s):
    out=[];i=0;q=None;esc=False
    while i<len(s):
        c=s[i]
        if q:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c==q: q=None
            out.append(' ');i+=1;continue
        if c in ('"',"'",'`'): q=c;out.append(' ');i+=1;continue
        if c=='#':
            while i<len(s) and s[i]!='\n': out.append(' ');i+=1
            continue
        out.append(c);i+=1
    return ''.join(out)
pairs={')':'(',']':'[','}':'{'}
for p in rfiles:
    st=[];good=True;detail=''
    for pos,c in enumerate(strip_r(read(p))):
        if c in '([{': st.append((c,pos))
        elif c in ')]}':
            if not st or st[-1][0]!=pairs[c]: good=False;detail=f'mismatch at {pos}';break
            st.pop()
    if good and st: good=False;detail=f'unclosed {st[-1][0]}'
    check(good,f'R delimiter balance: {p.name}',detail)

# Manuals and aliases
aliases={}
for p in (ROOT/'man').glob('*.Rd'):
    for a in re.findall(r'\\alias\{([^}]+)\}',read(p)): aliases.setdefault(a,[]).append(p.name)
check(len(list((ROOT/'man').glob('*.Rd')))==23,'Manual file count',f'{len(list((ROOT/"man").glob("*.Rd")))} files')
for fn in exports:
    check(fn in aliases,f'Manual alias present: {fn}')
    check(len(aliases.get(fn,[]))==1,f'Manual alias unique: {fn}',', '.join(aliases.get(fn,[])))
expected_man={
'growth_multiphase':'multiphase_events.Rd','growth_diphasic':'multiphase_events.Rd','growth_stability':'multiphase_events.Rd','growth_changepoint':'multiphase_events.Rd',
'growth_event':'disturbance_growth.Rd','growth_defoliation':'disturbance_growth.Rd','growth_compensation':'disturbance_growth.Rd',
'growth_density':'competition_growth.Rd','growth_neighbor':'competition_growth.Rd','growth_competition':'competition_growth.Rd',
'growth_threshold':'growth_decision_design.Rd','growth_plateau_time':'growth_decision_design.Rd','growth_harvest_opt':'growth_decision_design.Rd','growth_schedule':'growth_decision_design.Rd','growth_design_sim':'growth_decision_design.Rd','growth_power':'growth_decision_design.Rd'}
for fn,m in expected_man.items(): check(m in aliases.get(fn,[]),f'0.5.0 manual mapping: {fn}',m)
check('coffee_diphasic' in read(ROOT/'man/growth_data.Rd'),'growth_data manual includes coffee_diphasic')
check('bean_defoliation' in read(ROOT/'man/growth_data.Rd'),'growth_data manual includes bean_defoliation')
check('maize_density' in read(ROOT/'man/growth_data.Rd'),'growth_data manual includes maize_density')
check('tree_competition' in read(ROOT/'man/growth_data.Rd'),'growth_data manual includes tree_competition')

# Vignettes
vigs=sorted((ROOT/'vignettes').glob('v*.Rmd'))
check(len(vigs)==28,'Twenty-eight vignettes present through 0.5.0',f'{len(vigs)} found')
thresholds={'v06':500,'v11':1000,'v12':500,'v13':450,'v14':300,'v15':400,'v16':350,'v17':1000,'v18':450,'v19':400,'v20':480,'v21':350,'v22':1000,'v23':500,'v24':520,'v25':350,'v26':440,'v27':1500}
for p in vigs:
    n=len(read(p).splitlines()); th=100
    for k,v in thresholds.items():
        if p.name.startswith(k): th=v
    check(n>=th,f'Vignette instructional depth: {p.name}',f'{n} lines; threshold {th}')
    if int(p.name[1:3])>=23: check('bibliography: references.bib' in read(p),f'0.5.0 vignette uses shared bibliography: {p.name}')
bib=read(ROOT/'vignettes/references.bib'); bibkeys=set(re.findall(r'@[A-Za-z]+\{([^,]+),',bib)); used=set()
for p in vigs: used.update(re.findall(r'@([A-Za-z][A-Za-z0-9_]+)',read(p)))
for key in sorted(used): check(key in bibkeys,f'Citation key resolved: {key}')
check(not (bibkeys-used),'No unused bibliography keys',', '.join(sorted(bibkeys-used)))
for k in ['Gates1982','Muggeo2003','Panik2014']:
    check(k in used,f'New 0.5.0 reference cited in vignettes: {k}')

# References
rows=list(csv.DictReader(open(ROOT/'inst/metadata/reference_verification.csv',encoding='utf-8',newline='')))
check(len(rows)==25,'Twenty-five references in double-verification table',f'{len(rows)} rows')
check(all(r['verification_status'].startswith('MATCH') for r in rows),'All reference records marked MATCH')
check(all(r['source_1'] and r['source_2'] and r['source_1']!=r['source_2'] for r in rows),'Each reference names two distinct verification sources')
keys={r['key'] for r in rows}; newkeys={'Gates1982','Muggeo2003','Panik2014'}
check(newkeys.issubset(keys),'All new 0.5.0 references audited')
for k in sorted(newkeys): check(k in bibkeys,f'0.5.0 audited reference in bibliography: {k}')
audit=read(ROOT/'REFERENCE_AUDIT_0.5.0.md')
for term in ['Gates (1982)','Muggeo (2003)','Panik (2014)','Anten & Ackerly (2001)','Mischan et al. (2015)','25 rows']:
    check(term in audit,f'Reference audit documents: {term}')

# Teaching datasets
ext=sorted((ROOT/'inst/extdata').glob('*.csv'))
check(len(ext)==10,'Ten frozen teaching datasets present',f'{len(ext)} datasets')
expected_rows={'coffee_diphasic.csv':208,'bean_defoliation.csv':216,'maize_density.csv':32,'tree_competition.csv':64}
for fn,n in expected_rows.items():
    p=ROOT/'inst/extdata'/fn
    check(p.exists(),f'0.5.0 teaching dataset present: {fn}')
    if p.exists():
        nr=sum(1 for _ in open(p,encoding='utf-8'))-1
        check(nr==n,f'0.5.0 teaching dataset row count: {fn}',f'{nr} rows')
checksums=read(ROOT/'inst/metadata/teaching_data_checksums.sha256').splitlines()
check(len(checksums)==10,'Teaching-data checksum ledger has ten entries',f'{len(checksums)} entries')
for p in ext:
    h=hashlib.sha256(p.read_bytes()).hexdigest()
    check(any(line.startswith(h+'  inst/extdata/'+p.name) for line in checksums),f'Teaching dataset checksum matches: {p.name}')

# Scientific safeguards and implementation tokens
safeguards=[
('mid[j] <- mid[j - 1L] + exp','Ordered phase centers enforced'),
('.agf_num_derivative(object, tt, order = 4L)','Fourth derivative used for stability search'),
('measured inputs','Defoliation losses documented as measured inputs'),
('total_loss','Measured total-loss input implemented'),
('leaf_mass_loss','Measured leaf-mass-loss input implemented'),
('leaf_area_loss','Measured leaf-area-loss input implemented'),
('diag(alpha) <- 0','Competition matrix self-effects excluded'),
('k1 <- .agf_comp_rhs','RK4 competition integration implemented'),
('Fractional thresholds must be between 0 and 1','Fractional threshold guard'),
('rate_fraction = 0.05','Five-percent rate plateau default'),
('response_fraction = 0.95','Ninety-five-percent response plateau default'),
('not an automatic agronomic recommendation','Harvest scope safeguard documented'),
('not a D-optimal design','Schedule heuristic safeguard documented'),
('trait-level Monte Carlo','Power approximation scope documented'),
('r` and `K` must be scalars or have one value per plant','Ambiguous competition parameter recycling rejected')]
source_plus=rtext+'\n'+read(ROOT/'IMPLEMENTATION_SPEC_0.5.0.md')+'\n'+read(ROOT/'README.md')
for token,name in safeguards: check(token in source_plus,name)
check('install.packages' not in rtext,'No automatic dependency installation')

# Tests
actual={p.name for p in (ROOT/'tests/testthat').glob('*.R')}
required={'test-classical-workflow.R','test-data-design.R','test-longitudinal-mixed.R','test-parametric-traits.R','test-foundation-regressions-020.R','test-bayesian-growth.R','test-classical-rates.R','test-functional-growth.R','test-smooth-growth.R','test-parametric-models.R','test-bootstrap-uncertainty.R','test-partition-allometry.R','test-growth-manova.R','test-biological-events-decisions.R'}
check(actual==required,'Expected complete test-source set present',', '.join(sorted(actual)))
for fn in new:
    cnt=sum(read(p).count(fn+'(') for p in (ROOT/'tests/testthat').glob('*.R'))
    check(cnt>=1,f'0.5.0 API represented in test source: {fn}',f'{cnt} calls')

# API examples
api_path=ROOT/'inst/examples/API_EXAMPLES_0.5.0.R'; check(api_path.exists(),'Consolidated 0.5.0 API examples present')
api=read(api_path) if api_path.exists() else ''
for fn in exports:
    cnt=api.count(fn+'(')
    check(cnt>=3,f'API examples include at least three calls: {fn}',f'{cnt} calls')

# Hygiene
text_paths=[q for q in ROOT.glob('*.md') if not q.name.startswith('LOCAL_VALIDATION_')]+rfiles+vigs
all_text='\n'.join(read(p) for p in text_paths if p.exists())
check('—' not in all_text,'No em dash in distributed prose/source')
check('TODO' not in all_text and 'FIXME' not in all_text,'No TODO/FIXME markers')
check('cite' not in all_text and 'sandbox:/' not in all_text,'No ChatGPT citation/UI artifacts in package tree')
check(not any(p.name=='__pycache__' for p in ROOT.rglob('*') if p.is_dir()),'No Python cache directories')

# Spec content
spec=read(ROOT/'IMPLEMENTATION_SPEC_0.5.0.md')
for term in ['69 exported functions','multiphase','defoliation','competition','harvest','28 vignettes','25 records','R CMD check --as-cran']:
    check(term in spec,f'0.5.0 implementation specification covers: {term}')

# Report
npass=sum(x[0]=='PASS' for x in results); nfail=sum(x[0]=='FAIL' for x in results)
lines=['# agriGrowthFlow 0.5.0: Static Validation','',f'**Result: {npass} PASS, {nfail} FAIL.**','',
'This static battery validates source-level contracts without executing R. Runtime testthat, vignette rendering, roxygen2 regeneration, R CMD build, R CMD check --as-cran, and optional Bayesian compilation remain local runtime gates.','']
for st,name,detail in results: lines.append(f'- **{st}** {name}' + (f' :: {detail}' if detail else ''))
lines += ['', '## Mandatory local R validation', '',
'Run these gates on the frozen source tree before calling the package runtime-validated:', '',
'```r',
'install.packages(c("devtools", "roxygen2", "testthat", "rmarkdown", "knitr"))',
'# Install optional analytical backends needed for the workflows you intend to test.',
'roxygen2::roxygenise("agriGrowthFlow")',
'devtools::test("agriGrowthFlow")',
'devtools::build_vignettes("agriGrowthFlow")',
'```', '',
'Then from a system shell:', '',
'```text',
'R CMD build agriGrowthFlow',
'R CMD check --as-cran agriGrowthFlow_0.5.0.tar.gz',
'```', '',
'For the optional Bayesian runtime tests, install `brms`, `posterior`, `loo`, and a working Stan toolchain. If the package test suite uses the environment gate described in the Bayesian tests, set `AGRIGROWTHFLOW_RUN_BAYES_TESTS=true` before running those tests.', '',
'After `roxygenise()`, compare `NAMESPACE` and `man/` against the frozen tree. Any unexpected API or documentation change must be reviewed before release.', '',
'## Numerical controls to inspect locally', '',
'- multiphase centers remain ordered and amplitudes/scales remain positive;',
'- diphasic fits rediscover comparable minima across multiple starts;',
'- fourth-derivative stability points are stable to a denser search grid;',
'- defoliation reconstructions remain positive and respond sensibly to a smaller integration step;',
'- zero competition coefficients reproduce independent logistic-like trajectories;',
'- RK4 results are stable when `dt` is reduced;',
'- logistic 50% thresholds agree with the existing `growth_time_to(..., fraction = 0.5)` result;',
'- schedule and harvest outputs stay within explicitly supplied time intervals;',
'- `growth_power()` Monte Carlo error decreases as `n_sim` increases.', '']
(ROOT/'LOCAL_VALIDATION_0.5.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(f'agriGrowthFlow 0.5.0 static validation: {npass} PASS, {nfail} FAIL')
for st,name,detail in results:
    if st=='FAIL': print(f'[FAIL] {name}' + (f' :: {detail}' if detail else ''))
sys.exit(1 if nfail else 0)
