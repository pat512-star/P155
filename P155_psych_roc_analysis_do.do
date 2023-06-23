*analysis .do file started for P155_psych 2nd Dec 2022 P A Tiffin

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

*Imputed data; these should be the main findings with non-imputed results in an Appendix

use "C:\P155_psych\work\data\derived\P155_psych_MASTER_imputed_casc.dta", clear

*This programme runs multiple roctab analyses on the imputed datasets
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


*end of doing the do