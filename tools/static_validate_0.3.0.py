#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import csv, math, re, hashlib, sys

ROOT = Path(__file__).resolve().parents[1]
results=[]

def check(cond,name,detail=''):
    results.append(('PASS' if cond else 'FAIL',name,detail))

def read(p): return p.read_text(encoding='utf-8')

# -----------------------------------------------------------------------------
# 1. Version and package metadata
# -----------------------------------------------------------------------------
D=read(ROOT/'DESCRIPTION')
for field in ['Package: agriGrowthFlow','Version: 0.3.0','License: MIT + file LICENSE','Depends: R (>= 4.2.0)']:
    check(field in D,f'DESCRIPTION contains {field}')
title=next((x.split(': ',1)[1] for x in D.splitlines() if x.startswith('Title: ')),'')
check(len(title)<=65,'DESCRIPTION title length suitable for CRAN-style metadata',f'{len(title)} characters')
for dep in ['minpack.lm','nlme','mgcv','scam','refund','fdapace','knitr','rmarkdown','testthat']:
    check(dep in D and 'Suggests:' in D,f'Optional/recommended dependency declared: {dep}')
check('Version 0.3.0' in read(ROOT/'README.md'),'README identifies version 0.3.0')
check(read(ROOT/'NEWS.md').startswith('# agriGrowthFlow 0.3.0'),'NEWS begins with version 0.3.0')
check('R package version 0.3.0' in read(ROOT/'inst/CITATION'),'CITATION identifies version 0.3.0')
check((ROOT/'REFERENCE_AUDIT_0.3.0.md').exists(),'0.3.0 reference audit present')
check((ROOT/'IMPLEMENTATION_SPEC_0.3.0.md').exists(),'0.3.0 implementation specification present')
check((ROOT/'NAMESPACE_RD_SYNC_0.3.0.md').exists(),'0.3.0 NAMESPACE/Rd synchronization audit present')
rb=read(ROOT/'.Rbuildignore')
for token in ['LOCAL_VALIDATION_0\\.[123]\\.0','IMPLEMENTATION_SPEC_0\\.[123]\\.0','REFERENCE_AUDIT_0\\.[123]\\.0','FREEZE_MANIFEST_0\\.3\\.0','SHA256SUMS_0\\.3\\.0','TREE_0\\.3\\.0']:
    check(token in rb,f'.Rbuildignore covers development artifact: {token}')

check('^NAMESPACE_RD_SYNC_0\\.3\\.0\\.md$' in rb,'Rbuildignore excludes synchronization audit from R-built tarball')

# -----------------------------------------------------------------------------
# 2. Public API, definitions, and S3 synchronization
# -----------------------------------------------------------------------------
ns=read(ROOT/'NAMESPACE')
exports=re.findall(r'^export\(([^)]+)\)',ns,re.M)
rfiles=sorted((ROOT/'R').glob('*.R'))
rtext='\n'.join(read(p) for p in rfiles)
defs=set(re.findall(r'^([A-Za-z.][A-Za-z0-9._]*)\s*<-\s*function\s*\(',rtext,re.M))
check(len(exports)==41,'Public API export count',f'{len(exports)} exports')
check(len(exports)==len(set(exports)),'No duplicate NAMESPACE exports')
new_exports={'growth_mixed','growth_mixed_diagnose','growth_smooth','growth_smooth_predict','growth_derivative','growth_acceleration','growth_smooth_traits','growth_fpca','growth_functional','growth_curve_coefficients','growth_manova'}
check(new_exports.issubset(exports),'All 0.3.0 public functions exported')
for fn in exports: check(fn in defs,f'Exported function defined: {fn}')
s3=re.findall(r'^S3method\(([^,]+),([^)]+)\)',ns,re.M)
check(len(s3)==22,'S3 registration count',f'{len(s3)} S3 methods')
for generic,cls in s3:
    check(f'{generic}.{cls}' in defs,f'S3 method defined: {generic}.{cls}')
for method in ['print.agri_growth_mixed','print.agri_growth_mixed_diagnostics','print.agri_growth_smooth','print.agri_growth_smooth_collection','print.agri_growth_fpca','print.agri_growth_manova']:
    check(method in defs,f'0.3.0 S3 print method defined: {method}')

# -----------------------------------------------------------------------------
# 3. R lexical delimiter balance
# -----------------------------------------------------------------------------
def strip_r(s):
    out=[]; i=0; q=None; esc=False
    while i<len(s):
        c=s[i]
        if q:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c==q: q=None
            out.append(' '); i+=1; continue
        if c in ('"', "'", '`'):
            q=c; out.append(' '); i+=1; continue
        if c=='#':
            while i<len(s) and s[i]!='\n': out.append(' '); i+=1
            continue
        out.append(c); i+=1
    return ''.join(out)
pairs={')':'(',']':'[','}':'{'}
for p in rfiles:
    s=strip_r(read(p)); stack=[]; good=True; detail=''
    for pos,c in enumerate(s):
        if c in '([{': stack.append((c,pos))
        elif c in ')]}':
            if not stack or stack[-1][0]!=pairs[c]: good=False; detail=f'mismatch at {pos}'; break
            stack.pop()
    if good and stack: good=False; detail=f'unclosed {stack[-1][0]} at {stack[-1][1]}'
    check(good,f'R delimiter balance: {p.name}',detail)

# -----------------------------------------------------------------------------
# 4. Manual aliases and NAMESPACE/Rd synchronization
# -----------------------------------------------------------------------------
aliases={}
for p in (ROOT/'man').glob('*.Rd'):
    for a in re.findall(r'\\alias\{([^}]+)\}',read(p)):
        aliases.setdefault(a,[]).append(p.name)
for fn in exports:
    check(fn in aliases,f'Manual alias present: {fn}')
    check(len(aliases.get(fn,[]))==1,f'Manual alias unique: {fn}',', '.join(aliases.get(fn,[])))
fg_rd=read(ROOT/'man/flexible_growth.Rd')
usage_match=re.search(r'growth_smooth\(x,.*?\)\n\ngrowth_smooth_predict', fg_rd, re.S)
check(bool(usage_match and 'unit = NULL' in usage_match.group(0)),
      'growth_smooth Rd usage synchronized with source unit argument')
for fn,manfile in {
    'growth_mixed':'longitudinal_growth.Rd','growth_mixed_diagnose':'longitudinal_growth.Rd',
    'growth_smooth':'flexible_growth.Rd','growth_smooth_predict':'flexible_growth.Rd',
    'growth_derivative':'flexible_growth.Rd','growth_acceleration':'flexible_growth.Rd',
    'growth_smooth_traits':'flexible_growth.Rd','growth_fpca':'functional_growth.Rd',
    'growth_functional':'functional_growth.Rd','growth_curve_coefficients':'growth_manova.Rd','growth_manova':'growth_manova.Rd'
}.items():
    check(manfile in aliases.get(fn,[]),f'0.3.0 function mapped to expected manual: {fn}',manfile)

# -----------------------------------------------------------------------------
# 5. Vignette depth and bibliography integrity
# -----------------------------------------------------------------------------
vigs=sorted((ROOT/'vignettes').glob('v*.Rmd'))
check(len(vigs)==18,'Eighteen vignettes present through version 0.3.0',f'{len(vigs)} found')
thresholds={
    'v06':500,'v07':300,'v08':300,'v09':300,'v10':300,'v11':1000,
    'v12':500,'v13':450,'v14':300,'v15':400,'v16':350,'v17':1000
}
for p in vigs:
    n=len(read(p).splitlines()); threshold=100
    for k,v in thresholds.items():
        if p.name.startswith(k): threshold=v
    check(n>=threshold,f'Vignette instructional depth: {p.name}',f'{n} lines; threshold {threshold}')
check((ROOT/'vignettes/references.bib').exists(),'Vignette bibliography present')
bib=read(ROOT/'vignettes/references.bib')
bibkeys=set(re.findall(r'@[A-Za-z]+\{([^,]+),',bib))
used=set()
for p in vigs: used.update(re.findall(r'@([A-Za-z][A-Za-z0-9_]+)',read(p)))
for key in sorted(used): check(key in bibkeys,f'Vignette citation key present in bibliography: {key}')
check(not (bibkeys-used),'No unused core bibliography keys',', '.join(sorted(bibkeys-used)))
for p in vigs[12:]:
    s=read(p)
    check('bibliography: references.bib' in s or 'bibliography: "references.bib"' in s,
          f'0.3.0 vignette declares shared bibliography: {p.name}')

# -----------------------------------------------------------------------------
# 6. Two-source reference audit
# -----------------------------------------------------------------------------
with (ROOT/'inst/metadata/reference_verification.csv').open(encoding='utf-8',newline='') as f: refs=list(csv.DictReader(f))
check(len(refs)==16,'Sixteen core references have two-source audit records',f'{len(refs)} rows')
check(all(str(r.get('verification_status','')).startswith('MATCH') for r in refs),'All reference verification rows marked MATCH')
check(all(r.get('source_1') and r.get('source_2') and r['source_1']!=r['source_2'] for r in refs),'Every reference row names two distinct verification sources')
newkeys={'PinheiroBates2000','Mirman2014','PyaWood2015','RamsaySilverman2005','WangChiouMuller2016','MischanEtAl2015'}
check(newkeys.issubset({r['key'] for r in refs}),'All 0.3.0 core references appear in verification CSV')
for key in sorted(newkeys): check(key in bibkeys,f'0.3.0 audited reference appears in bibliography: {key}')
audit=read(ROOT/'REFERENCE_AUDIT_0.3.0.md')
for term in ['Pinheiro & Bates','Mirman','Pya & Wood','Ramsay & Silverman','Wang, Chiou & Müller','16 audited core references']:
    check(term in audit,f'0.3.0 reference audit documents: {term}')

# -----------------------------------------------------------------------------
# 7. Teaching datasets and design invariants
# -----------------------------------------------------------------------------
expected={
    'maize_destructive.csv':144,'bean_repeated.csv':192,'soybean_partition.csv':50,
    'sunflower_sigmoid.csv':216,'wheat_expolinear.csv':192,'soybean_irregular.csv':402
}
data={}
for fn,n in expected.items():
    p=ROOT/'inst/extdata'/fn
    check(p.exists(),f'Teaching dataset present: {fn}')
    with p.open(encoding='utf-8',newline='') as f: rows=list(csv.DictReader(f))
    data[fn]=rows
    check(len(rows)==n,f'Teaching dataset row count: {fn}',f'{len(rows)} rows')
check(set(data['bean_repeated.csv'][0])=={'plant_id','block','water_regime','day','height_cm','projected_leaf_area_m2','spad'},'bean_repeated schema matches repeated phenotyping example')
check(set(data['soybean_irregular.csv'][0])=={'plant_id','block','water_regime','day','projected_canopy_area_m2','height_cm'},'soybean_irregular schema matches irregular phenotyping example')
maize=data['maize_destructive.csv']
check(len({r['plot_id'] for r in maize})==12,'Maize destructive data have 12 persistent plots')
check(len({(r['plot_id'],r['day']) for r in maize})==72,'Maize destructive data have 72 plot-time means before aggregation')
check(all(sum(1 for r in maize if r['plot_id']==p and r['day']==t)==2 for p,t in {(r['plot_id'],r['day']) for r in maize}),
      'Maize destructive data have two subsamples per plot-time')
bean=data['bean_repeated.csv']; plants={r['plant_id'] for r in bean}
check(len(plants)==32,'Bean repeated data have 32 persistent plants')
check(all(len({r['day'] for r in bean if r['plant_id']==p})==6 for p in plants),'Every bean plant has six repeated times')
irr=data['soybean_irregular.csv']; ids={r['plant_id'] for r in irr}
counts={i:sum(1 for r in irr if r['plant_id']==i) for i in ids}
check(len(ids)==48,'Soybean irregular data have 48 persistent plants')
check(min(counts.values())>=7 and max(counts.values())<=10,'Soybean irregular plants have 7 to 10 observations',f'{min(counts.values())}-{max(counts.values())}')
check(len({r['water_regime'] for r in irr})==2,'Soybean irregular data have two water regimes')
byid={i:[float(r['day']) for r in irr if r['plant_id']==i] for i in ids}
lo=max(min(v) for v in byid.values()); hi=min(max(v) for v in byid.values())
check(hi>lo,'Soybean irregular trajectories share positive common support',f'{lo} to {hi}')
check(len({r['day'] for r in irr})==11,'Soybean irregular data use 11 potential observation days')
soy=data['soybean_partition.csv']; closures=[]
for r in soy:
    total=float(r['total_mass_g']); comps=sum(float(r[k]) for k in ['leaf_mass_g','root_mass_g','stem_mass_g','reproductive_mass_g']); closures.append(comps/total)
check(max(abs(c-1) for c in closures)<2e-6,'Soybean partition components close to total mass',f'max deviation {max(abs(c-1) for c in closures):.3g}')

# -----------------------------------------------------------------------------
# 8. Mathematical known truths retained from earlier layers
# -----------------------------------------------------------------------------
def logistic(t,A,mid,s): return A/(1+math.exp(-(t-mid)/s))
def gompertz(t,A,mid,s): return A*math.exp(-math.exp(-(t-mid)/s))
def richards(t,A,mid,s,nu): return A*(1+nu*math.exp(-(t-mid)/s))**(-1/nu)
def beta(t,wmax,tm,te):
    if t<=0: return 0.0
    if t>=te: return wmax
    return wmax*(1+(te-t)/(te-tm))*(t/te)**(te/(te-tm))
def log1pexp(z):
    if z>35: return z+math.log1p(math.exp(-z))
    if z<-35: return math.exp(z)
    return math.log1p(math.exp(z))
def expol(t,cm,rm,tb): return cm/rm*log1pexp(rm*(t-tb))
check(math.isclose(logistic(30,100,30,5),50,rel_tol=1e-14),'Logistic midpoint equals half asymptote')
check(math.isclose(gompertz(30,100,30,5),100/math.e,rel_tol=1e-14),'Gompertz inflection response equals A/e')
check(max(abs(richards(t,100,30,5,1)-logistic(t,100,30,5)) for t in range(0,61,3))<1e-12,'Richards shape=1 equals logistic parameterization')
check(beta(0,200,45,80)==0 and beta(80,200,45,80)==200,'Corrected beta growth satisfies W(0)=0 and W(te)=wmax')
sl=(expol(250.1,12,.1,30)-expol(249.9,12,.1,30))/.2
check(abs(sl-12)<1e-6,'Expolinear late finite-difference slope approaches cm',f'{sl:.10f}')
agr=(20-10)/5; rgr=math.log(2)/5; nar=agr*(math.log(.08)-math.log(.05))/(.08-.05)
check(math.isclose(agr,2),'AGR known truth')
check(math.isclose(rgr,math.log(2)/5),'RGR known truth')
check(math.isfinite(nar) and nar>0,'NAR known truth finite and positive')
check('.agf_recycle_numeric' in rtext and rtext.count('.agf_recycle_numeric(')>=7,'Classical functions retain explicit recycling guard')

# -----------------------------------------------------------------------------
# 9. 0.3.0 implementation safeguards and backend contracts
# -----------------------------------------------------------------------------
checks=[
    ('corAR1(form = ~ .t | .unit)','Discrete AR1 is unit-nested'),
    ('corCAR1(form = ~ .t | .unit)','Continuous-time AR1 is unit-nested'),
    ('requires integer-valued time','AR1 integer-time guard implemented'),
    ('varPower(form = ~ fitted(.))','Power residual variance structure implemented'),
    ('varExp(form = ~ fitted(.))','Exponential residual variance structure implemented'),
    ('varIdent(form = ~ 1 | .group)','Group-specific residual variance implemented'),
    ('mean within persistent unit x group x block x time','Destructive longitudinal aggregation is explicitly recorded'),
    ('Equalize the contribution of persistent units','Population smoothing protects equal persistent-unit weighting'),
    ('predict(object$fit, x = time, deriv = order)','Smoothing-spline native derivatives implemented'),
    ('one-sided','placeholder')
]
for token,name in checks[:-1]: check(token in rtext,name)
check('.agf_fd_numeric' in rtext and 'x + 3 * h' in rtext and 'x - 3 * h' in rtext,'Support-aware one-sided second differences implemented')
check('"mpi"' in rtext and '"mpd"' in rtext,'SCAM monotone increasing/decreasing bases implemented')
check('Persistent units do not share a positive common time interval' in rtext,'Grid FPCA rejects non-overlapping support')
check('weighted <- curves * sqrt(dt)' in rtext,'Grid FPCA uses L2 discretization scaling')
check('methodSelectK <- "FVE"' in rtext and 'methodSelectK <- as.integer(npc)' in rtext,'fdapace FVE and fixed-component contracts implemented')
check("data.frame(.id = as.character(d$.unit), .index = d$.t, .value = d$.y)" in rtext,'refund irregular long-form contract implemented')
check('requires the same observed time grid for every persistent unit' in rtext,'Orthogonal coefficient layer rejects mismatched harvest grids')
check('stats::manova' in rtext and 'summary(fit, test = test)' in rtext,'MANOVA layer implements requested multivariate statistic')
for pkg in ['nlme','mgcv','scam','fdapace','refund','minpack.lm']:
    check(f'requireNamespace("{pkg}"' in rtext,f'Optional backend guarded with requireNamespace: {pkg}')
check('install.packages' not in rtext,'Package source does not install dependencies automatically')

# -----------------------------------------------------------------------------
# 10. Test-source coverage
# -----------------------------------------------------------------------------
required_tests={
    'test-classical-rates.R','test-classical-workflow.R','test-data-design.R','test-partition-allometry.R',
    'test-foundation-regressions-020.R','test-parametric-models.R','test-parametric-traits.R',
    'test-longitudinal-mixed.R','test-smooth-growth.R','test-functional-growth.R','test-growth-manova.R'
}
actual={p.name for p in (ROOT/'tests/testthat').glob('*.R')}
check(required_tests==actual,'Expected complete test-source set present',', '.join(sorted(actual)))
for fn in ['growth_mixed','growth_mixed_diagnose','growth_smooth','growth_derivative','growth_acceleration','growth_fpca','growth_curve_coefficients','growth_manova']:
    count=sum(read(p).count(fn+'(') for p in (ROOT/'tests/testthat').glob('*.R'))
    check(count>=1,f'0.3.0 API represented in test sources: {fn}',f'{count} calls')

# -----------------------------------------------------------------------------
# 11. Consolidated public API examples
# -----------------------------------------------------------------------------
api_path=ROOT/'inst/examples/API_EXAMPLES_0.3.0.R'
check(api_path.exists(),'Consolidated 0.3.0 public API examples file present')
api=read(api_path) if api_path.exists() else ''
for fn in exports:
    count=len(re.findall(r'\b'+re.escape(fn)+r'\s*\(',api))
    check(count>=3,f'API examples include at least three calls: {fn}',f'{count} calls')
check('unit = "plant_id"' in api and 'group = "water_regime"' in api,'Flexible 0.3.0 examples identify persistent plant and treatment group')
check('requireNamespace("nlme", quietly = TRUE)' in api,'Mixed-model examples guard optional nlme backend')
check('soybean_irregular' in api,'Irregular soybean teaching data used in consolidated examples')

# -----------------------------------------------------------------------------
# 12. Source-tree hygiene
# -----------------------------------------------------------------------------
bad_em=[]; bad_ui=[]; placeholders=[]
for p in ROOT.rglob('*'):
    if not p.is_file() or p.suffix.lower() not in {'.r','.rmd','.md','.rd','.txt','.csv','.bib'}: continue
    s=p.read_text(encoding='utf-8',errors='ignore')
    if '—' in s: bad_em.append(str(p.relative_to(ROOT)))
    if '' in s or 'filecite' in s: bad_ui.append(str(p.relative_to(ROOT)))
    if 'tools' not in p.parts and not p.name.startswith('LOCAL_VALIDATION') and re.search(r'\b(TODO|FIXME|PLACEHOLDER|TBD)\b',s,re.I): placeholders.append(str(p.relative_to(ROOT)))
check(not bad_em,'No em dash in package prose/source',', '.join(bad_em))
check(not bad_ui,'No ChatGPT/UI citation artifacts in distributed files',', '.join(bad_ui))
check(not placeholders,'No provisional TODO/FIXME/placeholder markers',', '.join(placeholders))
check(not list(ROOT.rglob('__pycache__')),'No Python cache directories in source tree')

# -----------------------------------------------------------------------------
# 13. Teaching-data checksums
# -----------------------------------------------------------------------------
lines=[]
for p in sorted((ROOT/'inst/extdata').glob('*.csv')):
    lines.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  inst/extdata/{p.name}')
(ROOT/'inst/metadata/teaching_data_checksums.sha256').write_text('\n'.join(lines)+'\n',encoding='utf-8')
check(len(lines)==6,'Teaching-data SHA256 manifest refreshed for six datasets','inst/metadata/teaching_data_checksums.sha256')

# -----------------------------------------------------------------------------
# 14. Required version-specific source documents
# -----------------------------------------------------------------------------
spec=read(ROOT/'IMPLEMENTATION_SPEC_0.3.0.md')
for term in ['41 functions','Longitudinal mixed-effects layer','Flexible trajectory layer','Functional growth layer','Orthogonal growth components and MANOVA','frozen source snapshots']:
    check(term in spec,f'0.3.0 implementation specification covers: {term}')
check('200 PASS' in read(ROOT/'FREEZE_MANIFEST_0.2.0.md'),'Historical 0.2.0 freeze manifest retained unchanged in development tree')

# -----------------------------------------------------------------------------
# Report
# -----------------------------------------------------------------------------
passed=sum(s=='PASS' for s,_,_ in results); failed=sum(s=='FAIL' for s,_,_ in results)
print(f'agriGrowthFlow 0.3.0 static validation: {passed} PASS, {failed} FAIL')
for s,n,d in results: print(f'[{s}] {n}'+(f' :: {d}' if d else ''))
report=ROOT/'LOCAL_VALIDATION_0.3.0.md'
lines=['# agriGrowthFlow 0.3.0: Final Static Validation','',
       '## Status','',
       f'- Final static validation in the current build environment: **{passed} PASS, {failed} FAIL**.',
       '- The current environment does not contain an R executable. Therefore this report does not claim that `R CMD build`, `R CMD check --as-cran`, roxygen regeneration, testthat execution, or vignette rendering were executed.',
       '- The frozen artifact is a source snapshot. A true R-built release tarball remains contingent on the local R validation commands below.','',
       '## Checks performed','',
       'The static battery checks 0.3.0 package metadata, the 41-function exported API, S3 registration, R delimiter balance, NAMESPACE/Rd alias synchronization, the corrected `growth_smooth()` manual signature, 18-vignette depth, bibliography resolution, two-source metadata records, six teaching-data schemas and hierarchy, retained mathematical known truths, longitudinal covariance safeguards, equal-unit population smoothing, derivative boundary logic, shape constraints, FPCA support and backend contracts, MANOVA grid safeguards, test-source coverage, consolidated examples, source-tree hygiene, and teaching-data checksums.','',
       '## Results','', '| Status | Check | Detail |','|---|---|---|']
for s,n,d in results: lines.append(f'| {s} | {n.replace("|","/")} | {d.replace("|","/") if d else ""} |')
lines += ['', '## Required local R release gates','',
          'Run from a clean machine with R >= 4.2.0:','', '```r',
          'install.packages(c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown", "ggplot2", "rlang", "minpack.lm", "nlme", "mgcv", "scam", "refund", "fdapace"))',
          'devtools::document("agriGrowthFlow")',
          'devtools::test("agriGrowthFlow")',
          'devtools::install("agriGrowthFlow", build_vignettes = TRUE)',
          'devtools::check("agriGrowthFlow", cran = TRUE, manual = TRUE)',
          '```','',
          'Then build and check the exact immutable tarball:','', '```sh',
          'R CMD build agriGrowthFlow',
          'R CMD check --as-cran agriGrowthFlow_0.3.0.tar.gz',
          '```','',
          '## High-priority numerical and design controls for the local run','',
          '1. Logistic midpoint must equal half asymptote.',
          '2. Gompertz inflection response must equal `A/e`.',
          '3. Richards with `shape = 1` must reproduce the package logistic curve.',
          '4. Corrected beta growth must satisfy `W(0) = 0` and `W(te) = wmax`.',
          '5. Expolinear late finite-difference slope must approach `cm`.',
          '6. Destructive maize data must reduce from 144 rows to 72 plot-time means before mixed modeling.',
          '7. `correlation = "ar1"` must reject noninteger time; `"car1"` must remain available for continuous time.',
          '8. A known linear smooth must return first derivative near its generating slope and second derivative near zero.',
          '9. Grid FPCA must return 32 bean scores or 48 irregular-soybean scores when those complete teaching datasets are used.',
          '10. Grid FPCA must reject persistent units without positive common support.',
          '11. Growth-curve MANOVA must refuse mismatched observed time grids rather than interpolate silently.',
          '12. Ambiguous vector recycling in the classical foundation must continue to raise an error.','',
          '## Interpretation','',
          'A zero-failure static battery establishes internal source coherence at the level tested here. It is not a substitute for parsing, executing, regenerating documentation, rendering vignettes, and checking the package with R. The source snapshot may be frozen and hashed, but it must not be represented as an `R CMD build` artifact until the local R gates succeed.']
report.write_text('\n'.join(lines)+'\n',encoding='utf-8')
sys.exit(1 if failed else 0)
