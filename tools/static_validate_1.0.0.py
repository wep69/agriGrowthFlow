#!/usr/bin/env python3
from pathlib import Path
import csv, re, sys, hashlib
ROOT=Path(__file__).resolve().parents[1]
results=[]
def check(cond,name,detail=''): results.append(('PASS' if cond else 'FAIL',name,detail))
def read(p): return p.read_text(encoding='utf-8')

# Metadata
D=read(ROOT/'DESCRIPTION')
for field in ['Package: agriGrowthFlow','Version: 1.0.0','License: MIT + file LICENSE','Depends: R (>= 4.2.0)']:
    check(field in D,f'DESCRIPTION contains {field}')
title=next((x.split(': ',1)[1] for x in D.splitlines() if x.startswith('Title: ')),'')
check(len(title)<=65,'DESCRIPTION title length suitable',f'{len(title)} characters')
for dep in ['minpack.lm','nlme','mgcv','scam','refund','fdapace','brms','posterior','loo','cmdstanr','knitr','rmarkdown','testthat']:
    check(dep in D,f'Dependency declared: {dep}')
check('Version 1.0.0' in read(ROOT/'README.md'),'README identifies version 1.0.0')
check(read(ROOT/'NEWS.md').startswith('# agriGrowthFlow 1.0.0'),'NEWS begins with version 1.0.0')
check('R package version 1.0.0' in read(ROOT/'inst/CITATION'),'CITATION identifies version 1.0.0')
for f in ['REFERENCE_AUDIT_1.0.0.md','IMPLEMENTATION_SPEC_1.0.0.md','NAMESPACE_RD_SYNC_1.0.0.md']:
    check((ROOT/f).exists(),f'1.0.0 artifact present: {f}')

# API and S3
ns=read(ROOT/'NAMESPACE')
exports=re.findall(r'^export\(([^)]+)\)',ns,re.M)
s3=re.findall(r'^S3method\(([^,]+),([^)]+)\)',ns,re.M)
rfiles=sorted((ROOT/'R').glob('*.R'))
rtext='\n'.join(read(p) for p in rfiles)
defs=set(re.findall(r'^([A-Za-z.][A-Za-z0-9._]*)\s*<-\s*function\s*\(',rtext,re.M))
check(len(exports)==75,'Public API export count',f'{len(exports)} exports')
check(len(exports)==len(set(exports)),'No duplicate exports')
new=['growth_method_guide','growth_workflow','growth_workflow_audit','growth_table','growth_report','growth_export']
for fn in exports: check(fn in defs,f'Exported function defined: {fn}')
for fn in new: check(fn in exports,f'1.0.0 function exported: {fn}')
check(len(s3)==41,'S3 registration count',f'{len(s3)} methods')
for g,c in s3: check(f'{g}.{c}' in defs,f'S3 method defined: {g}.{c}')
check(len(rfiles)==22,'R source-file count',f'{len(rfiles)} files')

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
check(len(list((ROOT/'man').glob('*.Rd')))==24,'Manual file count',f'{len(list((ROOT/"man").glob("*.Rd")))} files')
for fn in exports:
    check(fn in aliases,f'Manual alias present: {fn}')
    check(len(aliases.get(fn,[]))==1,f'Manual alias unique: {fn}',', '.join(aliases.get(fn,[])))
expected_man={
'growth_method_guide':'consolidated_release.Rd','growth_workflow':'consolidated_release.Rd','growth_workflow_audit':'consolidated_release.Rd',
'growth_table':'consolidated_release.Rd','growth_report':'consolidated_release.Rd','growth_export':'consolidated_release.Rd'}
for fn,m in expected_man.items(): check(m in aliases.get(fn,[]),f'1.0.0 manual mapping: {fn}',m)
check('coffee_diphasic' in read(ROOT/'man/growth_data.Rd'),'growth_data manual includes coffee_diphasic')
check('bean_defoliation' in read(ROOT/'man/growth_data.Rd'),'growth_data manual includes bean_defoliation')
check('maize_density' in read(ROOT/'man/growth_data.Rd'),'growth_data manual includes maize_density')
check('tree_competition' in read(ROOT/'man/growth_data.Rd'),'growth_data manual includes tree_competition')

# Vignettes
vigs=sorted((ROOT/'vignettes').glob('v*.Rmd'))
check(len(vigs)==31,'Thirty-one vignettes present through 1.0.0',f'{len(vigs)} found')
thresholds={'v06':500,'v11':1000,'v12':500,'v13':450,'v14':300,'v15':400,'v16':350,'v17':1000,'v18':450,'v19':400,'v20':480,'v21':350,'v22':1000,'v23':500,'v24':520,'v25':350,'v26':440,'v27':1000,'v28':550,'v29':600,'v30':1000}
for p in vigs:
    n=len(read(p).splitlines()); th=100
    for k,v in thresholds.items():
        if p.name.startswith(k): th=v
    check(n>=th,f'Vignette instructional depth: {p.name}',f'{n} lines; threshold {th}')
    if int(p.name[1:3])>=23: check('bibliography: references.bib' in read(p),f'1.0.0 vignette uses shared bibliography: {p.name}')
bib=read(ROOT/'vignettes/references.bib'); bibkeys=set(re.findall(r'@[A-Za-z]+\{([^,]+),',bib)); used=set()
for p in vigs: used.update(re.findall(r'@([A-Za-z][A-Za-z0-9_]+)',read(p)))
for key in sorted(used): check(key in bibkeys,f'Citation key resolved: {key}')
check(not (bibkeys-used),'No unused bibliography keys',', '.join(sorted(bibkeys-used)))
for k in ['Gates1982','Muggeo2003','Panik2014']:
    check(k in used,f'New 1.0.0 reference cited in vignettes: {k}')

# References
rows=list(csv.DictReader(open(ROOT/'inst/metadata/reference_verification.csv',encoding='utf-8',newline='')))
check(len(rows)==25,'Twenty-five references in double-verification table',f'{len(rows)} rows')
check(all(r['verification_status'].startswith('MATCH') for r in rows),'All reference records marked MATCH')
check(all(r['source_1'] and r['source_2'] and r['source_1']!=r['source_2'] for r in rows),'Each reference names two distinct verification sources')
keys={r['key'] for r in rows}; refkeys={'Gates1982','Muggeo2003','Panik2014'}
check(refkeys.issubset(keys),'Event/decision references remain audited')
for k in sorted(refkeys): check(k in bibkeys,f'1.0.0 audited reference in bibliography: {k}')
audit=read(ROOT/'REFERENCE_AUDIT_1.0.0.md')
for term in ['Gates (1982)','Muggeo (2003)','Panik (2014)','Anten & Ackerly (2001)','Mischan et al. (2015)','25 rows']:
    check(term in audit,f'Reference audit documents: {term}')

# Teaching datasets
ext=sorted((ROOT/'inst/extdata').glob('*.csv'))
check(len(ext)==10,'Ten frozen teaching datasets present',f'{len(ext)} datasets')
expected_rows={'coffee_diphasic.csv':208,'bean_defoliation.csv':216,'maize_density.csv':32,'tree_competition.csv':64}
for fn,n in expected_rows.items():
    p=ROOT/'inst/extdata'/fn
    check(p.exists(),f'1.0.0 teaching dataset present: {fn}')
    if p.exists():
        nr=sum(1 for _ in open(p,encoding='utf-8'))-1
        check(nr==n,f'1.0.0 teaching dataset row count: {fn}',f'{nr} rows')
checksums=read(ROOT/'inst/metadata/teaching_data_checksums.sha256').splitlines()
check(len(checksums)==10,'Teaching-data checksum ledger has ten entries',f'{len(checksums)} entries')
for p in ext:
    h=hashlib.sha256(p.read_bytes()).hexdigest()
    check(any(line.startswith(h+'  inst/extdata/'+p.name) for line in checksums),f'Teaching dataset checksum matches: {p.name}')

# Scientific safeguards and implementation tokens
safeguards=[
('priority is a navigation rule', 'Method-guide priority documented as navigation rule'),
('does not assert that the selected method is uniquely correct', 'Automatic strategy safeguard documented'),
('identical prepared observations', 'Same-observation comparison safeguard documented'),
('uncertainty_args', 'Uncertainty arguments isolated from core model arguments'),
('Planning-only workflow', 'Planning-only workflow explicitly marked'),
('No uncertainty engine was executed', 'Uncertainty objective without engine is flagged'),
('RDS is documented as the preferred complete archive', 'RDS complete-archive safeguard documented'),
('does not generate unsupported publication claims', 'Automatic report claim safeguard documented')]
source_plus=rtext+'\n'+read(ROOT/'IMPLEMENTATION_SPEC_1.0.0.md')+'\n'+read(ROOT/'README.md')
for token,name in safeguards: check(token in source_plus,name)
check('install.packages' not in rtext,'No automatic dependency installation')

# Stable API contract
contract_path=ROOT/'inst/metadata/api_contract_1.0.0.csv'
check(contract_path.exists(),'1.0.0 API contract present')
contract=list(csv.DictReader(open(contract_path,encoding='utf-8',newline=''))) if contract_path.exists() else []
check(len(contract)==75,'API contract has one row per public function',f'{len(contract)} rows')
contract_names={r['function'] for r in contract} if contract else set()
check(contract_names==set(exports),'API contract exactly matches NAMESPACE exports')
check(all(r.get('stability')=='stable-1.0.0' for r in contract),'All API contract rows labeled stable-1.0.0')
for fn in new:
    rows=[r for r in contract if r.get('function')==fn]
    check(bool(rows) and rows[0].get('source_file')=='consolidated-release.R',f'Release API source contract: {fn}')

# Tests
actual={p.name for p in (ROOT/'tests/testthat').glob('*.R')}
required={'test-classical-workflow.R','test-data-design.R','test-longitudinal-mixed.R','test-parametric-traits.R','test-foundation-regressions-020.R','test-bayesian-growth.R','test-classical-rates.R','test-functional-growth.R','test-smooth-growth.R','test-parametric-models.R','test-bootstrap-uncertainty.R','test-partition-allometry.R','test-growth-manova.R','test-biological-events-decisions.R','test-consolidated-release.R'}
check(actual==required,'Expected complete test-source set present',', '.join(sorted(actual)))
for fn in new:
    cnt=sum(read(p).count(fn+'(') for p in (ROOT/'tests/testthat').glob('*.R'))
    check(cnt>=1,f'1.0.0 API represented in test source: {fn}',f'{cnt} calls')

# API examples
api_path=ROOT/'inst/examples/API_EXAMPLES_1.0.0.R'; check(api_path.exists(),'Consolidated 1.0.0 API examples present')
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
spec=read(ROOT/'IMPLEMENTATION_SPEC_1.0.0.md')
for term in ['75 exported functions','growth_method_guide','growth_workflow','growth_report','growth_export','31 extensive English vignettes','25 scientific references','R CMD check --as-cran']:
    check(term in spec,f'1.0.0 implementation specification covers: {term}')

# Release metadata and hygiene extras
check('Version 1.0.0' in read(ROOT/'README.md'),'README identifies stable release')
check(read(ROOT/'NEWS.md').startswith('# agriGrowthFlow 1.0.0'),'NEWS begins with stable release')
check('R package version 1.0.0' in read(ROOT/'inst/CITATION'),'CITATION identifies stable release')
check('growth_method_guide' in read(ROOT/'README.md'),'README documents consolidated method guide')
check('growth_workflow' in read(ROOT/'README.md'),'README documents consolidated workflow')
check('growth_export' in read(ROOT/'README.md'),'README documents release export')
for f in ['REFERENCE_AUDIT_1.0.0.md','IMPLEMENTATION_SPEC_1.0.0.md','NAMESPACE_RD_SYNC_1.0.0.md','LOCAL_VALIDATION_GUIDE_1.0.0.md','cran-comments.md']:
    check((ROOT/f).exists(),f'1.0.0 artifact present: {f}')
check((ROOT/'tools/local_validate_1.0.0.R').exists(),'Local R validation helper present')

# Report
npass=sum(x[0]=='PASS' for x in results); nfail=sum(x[0]=='FAIL' for x in results)
lines=['# agriGrowthFlow 1.0.0: Static Validation','',f'**Result: {npass} PASS, {nfail} FAIL.**','',
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
'R CMD check --as-cran agriGrowthFlow_1.0.0.tar.gz',
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
(ROOT/'LOCAL_VALIDATION_1.0.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(f'agriGrowthFlow 1.0.0 static validation: {npass} PASS, {nfail} FAIL')
for st,name,detail in results:
    if st=='FAIL': print(f'[FAIL] {name}' + (f' :: {detail}' if detail else ''))
sys.exit(1 if nfail else 0)
