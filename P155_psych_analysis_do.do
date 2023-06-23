*analysis .do file started for P155_psych 10th November 2022 P A Tiffin
clear all
capture log using "C:\P155_psych\work\P155_psych_analysis_log.smcl", replace

version 17.0
set more off, perm 
set maxvar 10000
set linesize 80
macro drop _all
clear all
window manage prefs load "classic"

sysdir set PLUS "C:\P155_psych\work\ado\plus\"

di "$S_DATE"
di "$S_TIME"



*setting format of coefficents and p values in regressions
set cformat %9.2f
set pformat %5.4f
 

**Note, the order roughly follows the way the results appear in they appear in the draft report


*Figure 1 - flow of data therough the study
use "C:\P155_psych\work\data\derived\P155_psych_MASTER_imputed_casc.dta", clear
*Number of applicants with complete SJT and CPS scores for the MSRA in study time frame (2015 to 2021)
codebook id if msra!=.

*Proportion with SC scores
codebook id if tot_sc!=.

*Number appointed to scheme etc
tab appoint if msra!=.

*Proportion with some written exam scores, for those appointed

codebook id if written!=. & appoint==1


*Proportion with some CASC exam scores, for those appointed
codebook id if casc_rtp!=. & appoint==1


*Complete cases for analysis-
codebook id if casc_rtp!=. & appoint==1 & msra!=. & tot_sc!=.



*Table 1 - descriptives
use "C:\P155_psych\work\data\derived\P155_psych_MASTER.dta", clear

*Descriptives for male etc
tab male if appoint==0 & casc_rtp==. 
tab male if appoint==1 & casc_rtp!=. 
tab male
tab male, miss
*formal testing
tab male appoint, chi2 

tab lowses if appoint==0 & casc_rtp==.
tab lowses if appoint==1 & casc_rtp!=.
tab lowses
tab lowses, miss

*formal testing
tab lowses appoint, chi2 



tab bme if appoint==0 & casc_rtp==.
tab bme if appoint==1 & casc_rtp!=.
tab bme
tab bme, miss


tab bme if appoint==0 & casc_rtp==. & pmq==1
tab bme if appoint==1 & casc_rtp!=. & pmq==1
tab bme if pmq==1
tab bme if pmq==1, miss

*formal testing
tab bme appoint, chi2 


tab pmq if appoint==0 & casc_rtp==.
tab pmq if appoint==1 & casc_rtp!=.
tab pmq, miss

*creating dummy variable for UK graduate vs non-uk grad
gen ukg=1 if pmq==1
replace ukg=0 if pmq==2 | pmq==3

*formal testing
tab ukg appoint, chi2 


*Eduational metrics for table 2:
summ cps if   appoint==0  & casc_rtp==.
summ cps if   appoint==1  & casc_rtp!=.
summ cps

summ sjt if   appoint==0  & casc_rtp==.
summ sjt if   appoint==1  & casc_rtp!=.
summ sjt

summ port_sc if   appoint==0  & casc_rtp==.
summ port_sc if   appoint==1  & casc_rtp!=.
summ port_sc
codebook port_sc

summ clin_sc if   appoint==0  & casc_rtp==.
summ clin_sc if   appoint==1  & casc_rtp!=.
summ clin_sc
codebook clin_sc

summ tot_sc if   appoint==0  & casc_rtp==.
summ tot_sc if   appoint==1  & casc_rtp!=.
summ tot_sc
codebook tot_sc

summ msra if   appoint==0  & casc_rtp==.
summ msra if   appoint==1  & casc_rtp!=.
summ msra
codebook msra

summ written if   appoint==0  & casc_rtp==.
summ written if   appoint==1  & casc_rtp!=.
summ written
codebook written

summ casc_rtp if   appoint==0  & casc_rtp==.
summ casc_rtp if   appoint==1  & casc_rtp!=.
summ casc_rtp
codebook casc_rtp

tab casc_pass if   appoint==1  & casc_rtp!=.


*Univariable analysis-

*correlation matrix

spearman cps sjt clin_sc port_sc written casc_rtp



*Univariable analyses ; multiply imputed data
use "C:\P155_psych\work\data\derived\P155_psych_MASTER_imputed_casc.dta", clear

*mi estimate: reg casc_rtp cps
mibeta casc_rtp cps

*mi estimate: reg casc_rtp cps
mibeta casc_rtp sjt

*mi estimate: reg casc_rtp clin_sc
mibeta casc_rtp clin_sc

*mi estimate: reg casc_rtp port_sc
mibeta casc_rtp port_sc

*mi estimate: reg casc_rtp tot_sc
mibeta casc_rtp tot_sc_i


*Non-imputed data

*mi estimate: reg casc_rtp cps
reg casc_rtp cps, beta

*mi estimate: reg casc_rtp cps
reg casc_rtp sjt, beta

*mi estimate: reg casc_rtp clin_sc
reg casc_rtp clin_sc, beta

*mi estimate: reg casc_rtp port_sc
reg casc_rtp port_sc, beta

*mi estimate: reg casc_rtp tot_sc
reg casc_rtp tot_sc, beta






*Testing if tot_sc_is are of any use in subgroups?

use "C:\P155_psych\work\data\derived\P155_psych_MASTER_imputed_casc.dta", clear

*Looking at those below 'hypothetical screening threshold'
mibeta casc_rtp cps sjt tot_sc_i if msra<484


*looking at bottom quartile
*mibeta casc_rtp cps sjt tot_sc_i if msra<454


*As a sensitivity analysis- look at the R^2 from the model excluding the tot_sc_i tot_sc_iores;
*mibeta casc_rtp cps sjt if msra<454


*looking at bottom half
*mibeta casc_rtp cps sjt tot_sc_i if msra<508




*looking at PMQ
mibeta casc_rtp cps sjt tot_sc_i  if pmq!=1


*testing for intergroup differences by demographics

*Looking at SJT by male etc
* First we test for equal variances- the results show we cannot reject the null hypotheses that the variances are equal indeed one can see they are very similar)
* These means we are most appropriate using Cohen's D not (Glass') for the effect size estimate

sdtest sjt, by(male)
esize twosample sjt, by(male) cohen 

sdtest sjt, by(bme)
esize twosample sjt, by(bme) glass

*BME for UKGs
sdtest sjt if pmq==1, by(bme) 
esize twosample sjt if pmq==1, by(bme) glass


sdtest sjt, by(lowses)
esize twosample sjt, by(lowses) cohen

*By PMQ
sdtest sjt if pmq!=3, by(pmq) 
esize twosample sjt if pmq!=3, by(pmq) glass

sdtest sjt if pmq!=2, by(pmq) 
esize twosample sjt if pmq!=2, by(pmq) cohen

sdtest sjt if pmq!=1, by(pmq) 
esize twosample sjt if pmq!=1, by(pmq) glass



*Note by convention usually only the (first listed) control group's effect size is reported

*Thus esize compares first to second level of variable, NOT the otherway round as expected


*Looking at CPS by male

sdtest cps, by(male)
esize twosample cps, by(male) cohen

sdtest cps, by(bme)
esize twosample cps, by(bme) glass

sdtest sjt if pmq==1, by(bme)
esize twosample cps if pmq==1, by(bme) glass

*sdtest cps, by(lowses)
esize twosample cps, by(lowses) glass

sdtest cps if pmq!=3, by(pmq) 
esize twosample cps if pmq!=3, by(pmq) glass

sdtest cps if pmq!=2, by(pmq) 
esize twosample cps if pmq!=2, by(pmq) glass

sdtest cps if pmq!=1, by(pmq) 
esize twosample cps if pmq!=1, by(pmq) glass


*Assesing demographics and tot_sc_i ratings- note we have to use the imputed data here
*THus we use the user written package by P A Tiffin "miesize" to derive a point estimate of effect-size and standard errors, according to Rubin's rules
use "C:\P155_psych\work\data\derived\P155_psych_MASTER_imputed_casc.dta", clear
sysdir set PLUS "C:\P155_psych\work\ado\plus\"

*Male: total selection centre score
sdtest tot_sc ,by(male)
*Use Glass' Delta

miesize tot_sc_i, by(male) glass

*Male: clinical selection centre score
sdtest clin_sc ,by(male)
miesize clin_sc, by(male) glass

*Male: Portfolio selection centre score
sdtest port_sc ,by(male)
miesize port_sc, by(male) glass
*BME GLASS


*BME UKGs: total selection centre score
sdtest tot_sc if pmq==1 ,by(bme)
*Use Cohen' {its: d}
miesize tot_sc_i if pmq==1, by(bme) 

*BME UKGs clinical selection centre score
sdtest clin_sc if pmq==1 ,by(bme)
miesize clin_sc if pmq==1, by(bme) 

*BME UKGs Portfolio selection centre score
sdtest port_sc if pmq==1,by(bme)
miesize port_sc if pmq==1, by(bme) 


*Low SES: total selection centre score
sdtest tot_sc ,by(lowses)
*Use Glass' Delta

**uncomment when new version of miesize uploaded

*miesize tot_sc_i, by(lowses) glass

*Low SES: clinical selection centre score
sdtest clin_sc,by(lowses)
*miesize clin_sc, by(lowses) glass

*Low SES: Portfolio selection centre score
sdtest port_sc,by(lowses)
*miesize port_sc, by(lowses) 


*Note: PMQ did not have missing data so a passive variable pmq_i is used so that the current version of miesize still works 
*pmq: UK vs IMG
sdtest tot_sc if pmq!=2, by(pmq_i)
miesize tot_sc_i if pmq!=2, by(pmq_i) glass


*pmq: UK vs IMG clinical selection centre score
sdtest clin_sc if pmq!=2 ,by(pmq_i)
miesize clin_sc if pmq!=2, by(pmq_i) glass

*pmq: UK vs IMG Portfolio selection centre score
sdtest port_sc if pmq!=2,by(pmq_i)
miesize port_sc if pmq!=2, by(pmq_i) glass



*Note: PMQ did not have missing data so a passive variable pmq_i is used so that the current version of miesize still works 
*pmq: UK vs EEA
sdtest tot_sc if pmq!=3, by(pmq_i)
miesize tot_sc_i if pmq!=3, by(pmq_i) glass


*pmq: UK vs EEA clinical selection centre score
sdtest clin_sc if pmq!=3 ,by(pmq_i)
miesize clin_sc if pmq!=3, by(pmq_i) glass

*pmq: UK vs EEA Portfolio selection centre score
sdtest port_sc if pmq!=3,by(pmq_i)
miesize port_sc if pmq!=3, by(pmq_i) glass

*Note: PMQ did not have missing data so a passive variable pmq_i is used so that the current version of miesize still works 
*pmq: EEA vs IMG
sdtest tot_sc if pmq!=1, by(pmq_i)
miesize tot_sc_i if pmq!=1, by(pmq_i) glass


*pmq: EEA vs IMGclinical selection centre score
sdtest clin_sc if pmq!=1 ,by(pmq_i)
miesize clin_sc if pmq!=1, by(pmq_i) glass

*pmq: EEA vs IMG Portfolio selection centre score
sdtest port_sc if pmq!=1,by(pmq_i)
miesize port_sc if pmq!=1, by(pmq_i) glass



*Multivariable results

putexcel set C:\P155_psych\work\data\derived\psych_analysis_imputed_results.xls, sheet("psych_imp_results") replace

*Imputed results
mi estimate: reg casc_rtp cps sjt tot_sc_i
return list
matrix list r(table)
matrix dir
*convert the r(table) to a proper matrix
matrix A=r(table)

*transpose the matrix to make the results conform to my preferred presentation style 
matrix B=A'

*Now we can output the elements of the matrix A to excel using putexcel:
putexcel A1 = matrix(B), names nformat(number_d2) hcenter
putexcel A1:E1 A10:E10, border(bottom) 
putexcel A1:A10, right border(right) 
putexcel A1:E1, top border(top)
*putexcel B1 = "tot_sc_i"
*putexcel C1 = "CPS"
*putexcel D1 = "SJT"

mibeta casc_rtp cps sjt tot_sc_i
*return list



*Non-imputed data

use "C:\P155_psych\work\data\derived\P155_psych_MASTER.dta", clear

putexcel set C:\P155_psych\work\data\derived\psych_analysis_non_imputed_results.xls, sheet("psych_non_imp_results") replace

reg casc_rtp cps sjt tot_sc, beta

*To obtain the 95% CIs:
reg casc_rtp  cps sjt tot_sc


reg casc_rtp cps sjt tot_sc, beta
return list
matrix list r(table)
matrix dir
*convert the r(table) to a proper matric
matrix A=r(table)

*transpose the matrix to make the results conform to my preferred presentation style 
matrix B=A'

*Now we can output the elements of the matrix A to excel using putexcel:
putexcel A1 = matrix(B), names nformat(number_d2) hcenter
putexcel A1:E1 A10:E10, border(bottom) 
putexcel A1:A10, right border(right) 
putexcel A1:E1, top border(top)
*putexcel B1 = "CASC"
*putexcel C1 = "CPS"
*putexcel D1 = "SJT"
*putexcel D1 = "SC"



***ROC analysis-

use "C:\P155_psych\work\data\derived\P155_psych_MASTER_imputed_casc.dta", clear
sysdir set PLUS "C:\P155_psych\work\ado\plus\"
cap program drop eroctab
program eroctab, eclass
        version 17.0

        /* Step 1: perform ROC analysis */
        args refvar classvar
        roctab `refvar' `classvar'

        /* Step 2: save estimate and its variance in temporary matrices*/
        tempname b V
        mat `b' = r(area)
        mat `V' = r(se)^2
        local N = r(N)

        /* Step 3: make column names and row names consistent*/
        mat colnames `b' = AUC
        mat colnames `V' = AUC
        mat rownames `V' = AUC

        /*Step 4: post results to e()*/
        ereturn post `b' `V', obs(`N')
        ereturn local cmd "eroctab"
        ereturn local title "ROC area"
end

mi estimate, cmdok: eroctab casc_pass msra_i

*imputation #1 closest to average
rocfit _1_casc_pass msra, continuous(20)
rocplot
roctab _1_casc_pass msra, detail




*End doing the do....




