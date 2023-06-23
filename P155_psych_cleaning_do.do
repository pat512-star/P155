*cleaning .do file started for P155_psych 3rd October 2022 P A Tiffin
clear all
capture log using "C:\P155_psych\work\P155_psych_cleaning_log.smcl", replace

version 17.0

set more off, perm 
set maxvar 10000
set linesize 80
macro drop _all
clear all
window manage prefs load "classic"
sysdir set PLUS "C:\P155_psych\work\ado\plus\"

use "C:\P155_psych\work\data\source\P155_94_MASTER_PERSON_CPT_SUCCESS.dta", clear

*study id was originally not recognised as numeric
rename STUDY_ID id
destring id, replace
format %12.0g id

save "C:\P155_psych\work\data\derived\P155_psych_success.dta", replace

*Manage and Link in the correct ORIEL_INTERVIEW_SCOREs
*These are the Selection Centre scores 

*for successful applicants
import excel "C:\P155_psych\work\data\source\p155_94_master_person_cpt_success_ois.xlsx", firstrow clear
rename STUDY_ID id
destring id, replace
format %12.0g id

/* foreach var of varlist * {
  rename `var' `=strlower("`var'")'
    }
	
*/
*pulling out the clinical scores and the portfolio scores separately
gen clin_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="Clinical Scenario Total Score"
replace clin_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="OIS_CLINICAL_SCEN_TOTAL_7"
replace clin_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="OIS_CLINICAL_SCEN_TOTAL_8"
gen port_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="OIS_PORTFOLIO_TOTAL_SCORE_27"
replace port_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="OIS_PORTFOLIO_TOTAL_SCORE_28"
replace port_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="Portfolio Total Score"

*reshape into wide format, but by filling in 'missing' SC scores so that that every id has an Oriel year, a clinical SC score and a portfolio SC scores
drop ORIEL_INTERVIEW_SCORE_NAME ORIEL_INTERVIEW_SCORE  
*Fill in missing portfolio scores on same row as the clinical scores
bysort id: replace port_sc= port_sc[_n+1] if port_sc==.
keep if clin_sc!=.
gen tot_sc= clin_sc +port_sc
label variable tot_sc "Total Selection centre score"
save C:\P155_psych\work\data\derived\p155_correct_sc_scores_psych_success.dta, replace

*merge with correct SC scores 
merge 1:1 id ORIEL_DATA_YEAR using "C:\P155_psych\work\data\derived\P155_psych_success.dta"
rename _merge merge_sc_success
save "C:\P155_psych\work\data\derived\P155_psych_success.dta", replace

* We now repeat this with the dataset for those who applied but were unsucessful at getting into psychiatry training training. This means we can later do some multiple imputation as a sensitivity analysis later 

use "C:\P155_psych\work\data\source\P155_94_MASTER_PERSON_CPT_NO_SUCCESS.dta", clear
*study id was originally not recognised as numeric
rename STUDY_ID id
destring id, replace
drop ORIEL_INTERVIEW_SCORE
save "C:\P155_psych\work\data\derived\P155_psych_no_success.dta", replace

*for unsuccessful applicants 
import excel "C:\P155_psych\work\data\source\p155_94_master_person_cpt_no_success_ois.xlsx", firstrow clear
destring STUDY_ID, replace
rename STUDY_ID id
format %12.0g id
/*foreach var of varlist * {
  rename `var' `=strlower("`var'")'
}

*/
*drop ORIEL_INTERVIEW_SCORE_NAME
drop if ORIEL_INTERVIEW_SCORE==.

*pulling out the clinical scores and the portfolio scores separately
gen clin_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="Clinical Scenario Total Score"
replace clin_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="OIS_CLINICAL_SCEN_TOTAL_7"
replace clin_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="OIS_CLINICAL_SCEN_TOTAL_8"
gen port_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="OIS_PORTFOLIO_TOTAL_SCORE_27"
replace port_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="OIS_PORTFOLIO_TOTAL_SCORE_28"
replace port_sc= ORIEL_INTERVIEW_SCORE if ORIEL_INTERVIEW_SCORE_NAME=="Portfolio Total Score"

gen type=1 if clin_sc!=.
replace type=2 if port_sc!=.

*Identify duplicates which resat in same year
duplicates tag id type,gen(dup)

*removes the first sitting for duplicates- 127 duplicated observations - retains only the latest sitting
drop if regexm(ORIEL_PROG_ID, "R1A"$) == 1 & dup>0
drop dup

*removes 2 pairs of further duplicates where round 1 and round 2 are both listed retaining round 2
duplicates tag id type,gen(dup)
drop if regexm(ORIEL_PROG_ID, "R1R"$) == 1 & dup>0

*reshape into wide format, but by filling in 'missing' SC scores so that that every id has an Oriel year, a clinical SC score and a portfolio SC scores
drop ORIEL_INTERVIEW_SCORE ORIEL_INTERVIEW_SCORE_NAME 
*Fill in missing portfolio scores on same row as the clinical scores
bysort id: replace port_sc= port_sc[_n+1] if port_sc==.
keep if clin_sc!=.
gen tot_sc= clin_sc +port_sc
label variable tot_sc "Total Selection centre score"
save C:\P155_psych\work\data\derived\p155_correct_sc_scores_psych_no_success.dta, replace

*merge with correct SC scores 
merge 1:1 id ORIEL_DATA_YEAR using "C:\P155_psych\work\data\derived\P155_psych_no_success.dta"
save "C:\P155_psych\work\data\derived\P155_psych_no_success.dta", replace
rename _merge merge_sc_no_success

* merge datasets for successful and unsuccessful applicants

merge 1:1 id using "C:\P155_psych\work\data\derived\P155_psych_success.dta"

save "C:\P155_psych\work\data\derived\P155_psych_MASTER.dta", replace

foreach var of varlist * {
rename `var' `=strlower("`var'")'
    }
	

*some compact syntax to change variable names to lower case

foreach var of varlist * {
  rename `var' `=strlower("`var'")'
}

*/

*destring birth_month, replace 
*destring birth_year, replace 


*generate variable for male sex
gen male=1 if gender=="Man"
replace male=0 if gender=="Woman"

*drop unnecssary gender variable
drop gender_int 


*Coding demographics according to Primary Medical Qualification
rename primary_pmq_year pmq_year
label variable pmq_year "year primary medical qualification awarded"
rename primary_pmq_world_region pmq_region
encode pmq_region, gen(pmq_region_num)
tab pmq_region_num
recode pmq_region_num (3=0) (2=2) (1=1)
label variable pmq_region_num "world region 0=uk, 1=EEA, 2=IMG"

*defines region labels
label define region 0 uk 1 eea 2 img
*assigns region labels to pmq_region_num
label values pmq_region_num region
*shortend for convenience
rename pmq_region_num pmq


gen img=1 if pmq==2
replace img=0 if pmq==0
label variable img "IMG vs UKG only"

gen nationality_deidentified= nationality

*treat those with dual UK citizenship as UK nationals
replace  nationality_deidentified="British" if nationality2=="British"

/*Rename nationality deidentified to match gdp data+ PATs corrections for a few countries*/
replace  nationality_deidentified="Albania" if nationality_deidentified=="Albanian" 
replace  nationality_deidentified="Austria" if nationality_deidentified=="Austrian"
replace  nationality_deidentified="Belarus" if nationality_deidentified=="Byelorussian"
replace  nationality_deidentified="Belarus" if nationality_deidentified=="Belarian"
replace  nationality_deidentified="Belarus" if nationality_deidentified=="Belarusian"
replace  nationality_deidentified="Belgium" if nationality_deidentified=="Belgian"
replace  nationality_deidentified="Bosnia And Herzegovina" if nationality_deidentified=="Bosnian"
replace  nationality_deidentified="Bulgaria" if nationality_deidentified=="Bulgarian"
replace  nationality_deidentified="Croatia" if nationality_deidentified=="Croatian"
replace  nationality_deidentified="Czech Republic" if nationality_deidentified=="Czech"
replace  nationality_deidentified="Denmark" if nationality_deidentified=="Danish"
replace  nationality_deidentified="Estonia" if nationality_deidentified=="Estonian"
replace  nationality_deidentified="Finland" if nationality_deidentified=="Finnish"
replace  nationality_deidentified="France" if nationality_deidentified=="French"
replace  nationality_deidentified="Germany" if nationality_deidentified=="German"
replace  nationality_deidentified="Greece" if nationality_deidentified=="Greek"
replace  nationality_deidentified="Hungary" if nationality_deidentified=="Hungarian"
replace  nationality_deidentified="Iceland" if nationality_deidentified=="Icelandic"
replace  nationality_deidentified="Ireland" if nationality_deidentified=="Irish"
replace  nationality_deidentified="Italy" if nationality_deidentified=="Italian"
replace  nationality_deidentified="Latvia" if nationality_deidentified=="Latvian"
replace  nationality_deidentified="Lithuania" if nationality_deidentified=="Lithuanian"
replace  nationality_deidentified="Macedonia" if nationality_deidentified=="Macedonian"
replace  nationality_deidentified="Malta" if nationality_deidentified=="Maltese"
replace  nationality_deidentified="Moldova, Republic Of" if nationality_deidentified=="Moldavian"
replace  nationality_deidentified="Netherlands" if nationality_deidentified=="Dutch"
replace  nationality_deidentified="Norway" if nationality_deidentified=="Norwegian"
replace  nationality_deidentified="Poland" if nationality_deidentified=="Polish"
replace  nationality_deidentified="Portugal" if nationality_deidentified=="Portuguese"
replace  nationality_deidentified="Romania" if nationality_deidentified=="Romanian"
replace  nationality_deidentified="Russian Federation" if nationality_deidentified=="Russian"
replace  nationality_deidentified="Serbia" if nationality_deidentified=="Serbian"
replace  nationality_deidentified="Slovakia" if nationality_deidentified=="Slovakian"
replace  nationality_deidentified="Slovenia" if nationality_deidentified=="Slovenian"
replace  nationality_deidentified="Spain" if nationality_deidentified=="Spanish"
replace  nationality_deidentified="Sweden" if nationality_deidentified=="Swedish"
replace  nationality_deidentified="Switzerland" if nationality_deidentified=="Swiss"
replace  nationality_deidentified="Turkey" if nationality_deidentified=="Turkish"
replace  nationality_deidentified="Ukraine" if nationality_deidentified=="Ukrainian"
replace nationality_deidentified="Algeria" if nationality_deidentified=="Algerian"
replace nationality_deidentified="Burundi" if nationality_deidentified=="Burundian"
replace nationality_deidentified="Cameroon" if nationality_deidentified=="Cameroonian"
replace nationality_deidentified="Congo, The Dem Republic of The" if nationality_deidentified=="Congolese"
replace nationality_deidentified="Egypt" if nationality_deidentified=="Egyptian"
replace nationality_deidentified="Ethiopia" if nationality_deidentified=="Ethiopian"
replace nationality_deidentified="Guinea" if nationality_deidentified=="Guinean"
replace nationality_deidentified="Ghana" if nationality_deidentified=="Ghanaian"
replace nationality_deidentified="Kenya" if nationality_deidentified=="Kenyan"
replace nationality_deidentified="Liberia" if nationality_deidentified=="Liberian"
replace nationality_deidentified="Libyan Arab Jamahiriya" if nationality_deidentified=="Libyan"
replace nationality_deidentified="Malawi" if nationality_deidentified=="Malawian"
replace nationality_deidentified="Mauritius" if nationality_deidentified=="Mauritian"
replace nationality_deidentified="Morocco" if nationality_deidentified=="Moroccan"
replace nationality_deidentified="Morocco" if nationality_deidentified=="Moroccon"
replace nationality_deidentified="Nigeria" if nationality_deidentified=="Nigerian"
replace nationality_deidentified="Senegal" if nationality_deidentified=="Senegalese"
replace nationality_deidentified="Sierra Leone" if nationality_deidentified=="Sierra Leonean"
replace nationality_deidentified="Sierra Leone" if nationality_deidentified=="Sierra Leonnian"
replace nationality_deidentified="South Africa" if nationality_deidentified=="South African"
replace nationality_deidentified="Sudan" if nationality_deidentified=="Sudanese"
replace nationality_deidentified="Tanzania, United Republic Of" if nationality_deidentified=="Tanzanian"
replace nationality_deidentified="Togo" if nationality_deidentified=="Togolese"
replace nationality_deidentified="Tunisia" if nationality_deidentified=="Tunisian"
replace nationality_deidentified="Uganda" if nationality_deidentified=="Ugandan"
replace nationality_deidentified="Zambia" if nationality_deidentified=="Zambian"
replace nationality_deidentified="Zimbabwe" if nationality_deidentified=="Zimbabwean"
replace nationality_deidentified="Afghanistan" if nationality_deidentified=="Afghan"
replace nationality_deidentified="Armenia" if nationality_deidentified=="Armenian"
replace nationality_deidentified="Azerbaijan" if nationality_deidentified=="Azerbaijani"
replace nationality_deidentified="Bahrain" if nationality_deidentified=="Bahraini"
replace nationality_deidentified="Bangladesh" if nationality_deidentified=="Bangladeshi"
replace nationality_deidentified="China" if nationality_deidentified=="Chinese"
replace nationality_deidentified="Georgia" if nationality_deidentified=="Georgian"
replace nationality_deidentified="Hong Kong" if nationality_deidentified=="Hong Kong"
replace nationality_deidentified="India" if nationality_deidentified=="Indian"
replace nationality_deidentified="Iran, Islamic Republic Of" if nationality_deidentified=="Iranian"
replace nationality_deidentified="Iraq" if nationality_deidentified=="Iraqi"
replace nationality_deidentified="Israel" if nationality_deidentified=="Israeli"
replace nationality_deidentified="Japan" if nationality_deidentified=="Japanese"
replace nationality_deidentified="Jordan" if nationality_deidentified=="Jordanian"
replace nationality_deidentified="Kazakhstan" if nationality_deidentified=="Kazakhstani"
replace nationality_deidentified="Korea, Republic Of" if nationality_deidentified=="Korean"
replace nationality_deidentified="Kuwait" if nationality_deidentified=="Kuwaiti"
replace nationality_deidentified="Kyrgyzstan" if nationality_deidentified=="Kyrgyzstani"
replace nationality_deidentified="Lebanon" if nationality_deidentified=="Lebanese"
replace nationality_deidentified="Malaysia" if nationality_deidentified=="Malaysian"
replace nationality_deidentified="Mongolia" if nationality_deidentified=="Mongolian"
replace nationality_deidentified="Myanmar" if nationality_deidentified=="Burmese"
replace nationality_deidentified="Nepal" if nationality_deidentified=="Nepalese"
replace nationality_deidentified="Oman" if nationality_deidentified=="Omani"
replace nationality_deidentified="Pakistan" if nationality_deidentified=="Pakistani"
replace nationality_deidentified="Palestinian Territories" if nationality_deidentified=="Palestinian"
replace nationality_deidentified="Philippines" if nationality_deidentified=="Philippino"
replace nationality_deidentified="Philippines" if nationality_deidentified=="Filipino"
replace nationality_deidentified="Saudi Arabia" if nationality_deidentified=="Saudi Arabian"
replace nationality_deidentified="Singapore" if nationality_deidentified=="Singaporean"
replace nationality_deidentified="Sri Lanka" if nationality_deidentified=="Sri Lankan"
replace nationality_deidentified="Syrian Arab Republic" if nationality_deidentified=="Syrian"
replace nationality_deidentified="Taiwan, Province Of China" if nationality_deidentified=="Taiwanese"
replace nationality_deidentified="Tajikistan" if nationality_deidentified=="Tajikistani"
replace nationality_deidentified="Thailand" if nationality_deidentified=="Thai"
replace nationality_deidentified="Turkmenistan" if nationality_deidentified=="Turkmens"
replace nationality_deidentified="United Arab Emirates" if nationality_deidentified=="Emirian"
replace nationality_deidentified="United Arab Emirates" if nationality_deidentified=="Emirati"
replace nationality_deidentified="Uzbekistan" if nationality_deidentified=="Uzbekistani"
replace nationality_deidentified="Viet Nam" if nationality_deidentified=="Vietnamese"
replace nationality_deidentified="Yemen" if nationality_deidentified=="Yemeni"
replace nationality_deidentified="Australia" if nationality_deidentified=="Australian"
replace nationality_deidentified="Cook Islands" if nationality_deidentified=="Cook Islander"
replace nationality_deidentified="New Zealand" if nationality_deidentified=="New Zealander"
replace nationality_deidentified="Papua New Guinea" if nationality_deidentified=="Papuan"
replace nationality_deidentified="Barbados" if nationality_deidentified=="Barbadian"
replace nationality_deidentified="Belize" if nationality_deidentified=="Belizean"
replace nationality_deidentified="Canada" if nationality_deidentified=="Canadian"
replace nationality_deidentified="Cayman Islands" if nationality_deidentified=="Caymanian"
replace nationality_deidentified="Cuba" if nationality_deidentified=="Cuban"
replace nationality_deidentified="Dominican Republic" if nationality_deidentified=="Dominican"
replace nationality_deidentified="Grenada" if nationality_deidentified=="Grenadian"
replace nationality_deidentified="Haiti" if nationality_deidentified=="Haitian"
replace nationality_deidentified="Jamaica" if nationality_deidentified=="Jamaican"
replace nationality_deidentified="Mexico" if nationality_deidentified=="Mexican"
replace nationality_deidentified="Montserrat" if nationality_deidentified=="Montserratian"
replace nationality_deidentified="Nicaragua" if nationality_deidentified=="Nicaraguan"
replace nationality_deidentified="Panama" if nationality_deidentified=="Panamanian"
replace nationality_deidentified="Saba" if nationality_deidentified=="Saba Dutch"
replace nationality_deidentified="Saint Kitts And Nevis" if nationality_deidentified=="Nevisian"
replace nationality_deidentified="Saint Lucia" if nationality_deidentified=="Saint Lucian"
replace nationality_deidentified="Sint Maarten" if nationality_deidentified=="Sint Maarten"
replace nationality_deidentified="Trinidad And Tobago" if nationality_deidentified=="Trinidad"
replace nationality_deidentified="Trinidad And Tobago" if nationality_deidentified=="Tobagan"
replace nationality_deidentified="United States" if nationality_deidentified=="American"
replace nationality_deidentified="Argentina" if nationality_deidentified=="Argentinian"
replace nationality_deidentified="Bolivia" if nationality_deidentified=="Bolivian"
replace nationality_deidentified="Brazil" if nationality_deidentified=="Brazilian"
replace nationality_deidentified="Chile" if nationality_deidentified=="Chilean"
replace nationality_deidentified="Colombia" if nationality_deidentified=="Colombian"
replace nationality_deidentified="Ecuador" if nationality_deidentified=="Ecuadorian"
replace nationality_deidentified="Guyana" if nationality_deidentified=="Guyanese"
replace nationality_deidentified="Peru" if nationality_deidentified=="Peruvian"
replace nationality_deidentified="Uruguay" if nationality_deidentified=="Uruguyan"
replace nationality_deidentified="Venezuela" if nationality_deidentified=="Venezuelan"
replace nationality_deidentified= "Antigua and Barbuda" if nationality_deidentified=="Antiguan"
replace nationality_deidentified= "Bahamas" if nationality_deidentified=="Bahamian"
replace nationality_deidentified= "Antigua and Barbuda" if nationality_deidentified=="Barbudan"
replace nationality_deidentified= "Bhutan" if nationality_deidentified=="Bhutanes"
replace nationality_deidentified= "Botswana" if nationality_deidentified=="Botswanian"
replace nationality_deidentified= "United Kingdom" if nationality_deidentified=="British"
replace nationality_deidentified= "British Virgin Islands" if nationality_deidentified=="British Virgin Islander"
replace nationality_deidentified= "Brunei" if nationality_deidentified=="Bruneian"
replace nationality_deidentified= "Cyprus" if nationality_deidentified=="Cypriot"
replace nationality_deidentified= "Eritrea" if nationality_deidentified=="Eritrean"
replace nationality_deidentified= "Fiji" if nationality_deidentified=="Fijian"
replace nationality_deidentified= "Luxembourg" if nationality_deidentified=="Luxembourger"
replace nationality_deidentified= "Maldives" if nationality_deidentified=="Maldivian"
replace nationality_deidentified= "Nauru" if nationality_deidentified=="Nauruan"
replace nationality_deidentified= "Qatar" if nationality_deidentified=="Qatari"
replace nationality_deidentified= "Rwanda" if nationality_deidentified=="Rwandan"
replace nationality_deidentified= "Seychelles" if nationality_deidentified=="Seychellois"
replace nationality_deidentified= "Somalia" if nationality_deidentified=="Somali"
replace nationality_deidentified= "Swaziland" if nationality_deidentified=="Swazi"
replace nationality_deidentified= "Trinidad And Tobago" if nationality_deidentified=="Trinidadian"
replace nationality_deidentified= "Saint Vincent and the Grenadines" if nationality_deidentified=="Vincentian"
replace nationality_deidentified= "Angola" if nationality_deidentified=="Angolan"
replace nationality_deidentified= "Indonesia" if nationality_deidentified=="Indonesian"
replace nationality_deidentified= "Gambia" if nationality_deidentified=="Gambian"
clonevar nationality_new = nationality_deidentified
replace nationality_new = "" if nationality_deidentified =="West Indian"
replace nationality_new = "" if nationality_deidentified =="Yugoslavian"
drop nationality
rename nationality_new nationality

*coding ethncicity
gen bame=1 if bme=="BME"
replace bame=0 if bme=="White"
drop bme
rename bame bme
label variable bme "self reported BME ethnicity"

*lowses - not lowses is 1 if lower supervisory and technical prfessional background or below
destring sec_int, replace
replace sec_int=. if sec_int==99
gen lowses=1 if (sec_int>3 & sec_int!=.)
replace lowses=0 if sec_int<4

***school type attended*************************

*note: can only differentiate between state and private- selective not reliably recorded (v low N)

gen scl=.
label variable scl "state school attended is '1' private '0'"
replace scl=1 if school_type=="A state run or state funded school - selective on academic, faith or other grounds"
replace scl=1 if school_type=="A state run or state funded school - non selective"
replace scl=1 if school_type=="State-funded school or college"
replace scl=0 if school_type=="Independent or fee paying school"
replace scl=0 if school_type=="Privately funded school"


************PLAB***************************************************************

*using the most recent (last) PLAB results:
 
gen plab1_rtp_last= test_score_plab1_last- test_pass_mark_plab1_last
gen plab2_rtp_last= test_score_plab2_last- test_pass_mark_plab2_last
label variable plab1_rtp_last "plab1 score RTP on most recent attempt"
label variable plab2_rtp_last "plab2 score RTP on most recent attempt"

*One plab1 RTP is down as -30 all the others are >=0 as expected

*This observation is deleted

replace plab1_rtp_last=. if plab1_rtp_last==-30


*Several (n=3)  plab2 RTP  scores are less than zero= these are deleted
replace plab2_rtp_last=. if plab2_rtp_last<0

*using the first PLAB results:
 
gen plab1_rtp_first= test_score_plab1_first- test_pass_mark_plab1_first
gen plab2_rtp_first= test_score_plab2_first- test_pass_mark_plab2_first
label variable plab1_rtp_first "plab1 score RTP on first attempt"
label variable plab2_rtp_first "plab2 score RTP on first attempt"


*managing MRCPsych exam data
*this creates the year that the result of the written part of the Part 1 MRCPsych was known for the candidate at first attempt

*this creates an approximate age of the dr at the time the results for the first attempt of pape1 were released
gen year_paper1_att1=substr(rcpsych_a_d1_exam_dateresult,1, 4)
destring year_paper1_att1, replace
label variable year_paper1_att1 "year of first attempt at paper 1" 
gen age_paper1_att1=year_paper1_att1-birth_year
label variable age_paper1_att  "age of first attempt at paper 1" 


**this creates an approximate age of the dr at the time the results for the first attempt of CASC were released

gen year_casc_att1=substr(rcpsych_casc_d1_exam_dateresult,1, 4)
destring year_casc_att1, replace
label variable year_casc_att1 "year of first attempt at CASC" 
gen age_casc_att1=year_casc_att1-birth_year
label variable age_casc_att  "age of first attempt at CASC" 

rename var333 papera_rtp
label variable papera_rtp "Paper A performance relative to pass mark at first attempt"
rename var338 paperb_rtp
label variable paperb_rtp "Paper B performance relative to pass mark at first attempt"

*NOTE: there are no RTP marks for papers 1, 2 and 3 at present
gen casc_rtp= rcpsych_casc_d1_exam_totalmark- rcpsych_casc_d1_exam_passmark
label variable casc_rtp "CASC score relative to the passmark at first sitting"

rename rcpsych_casc_d1_exam_passfail casc_pass
label variable casc_pass "CASC pass at first attempt?"

*Taking the equated Clinical Problem solving score for the last sitting 
gen cps= cps40_a1 if cps40_a2==.
replace  cps= cps40_a2 if cps40_a2!=. &   cps40_a3==.
replace  cps= cps40_a3 if cps40_a3!=.

*Taking the equated MSRA SJT  score for the last sitting 
gen sjt= sjt40_a1 if sjt40_a2==.
replace  sjt= sjt40_a2 if sjt40_a2!=. &   sjt40_a3==.
replace  sjt= sjt40_a3 if sjt40_a3!=.

*for use later in identifying "bypass cohorts" use the original msra_src_a1 to identify diet


*Extracting year of MSRA sitting using a regular expression
gen msra_year_a1 = regexs(0) if(regexm( msra_src_a1 , "[0-9][0-9][0-9][0-9]"))
gen msra_year_a2 = regexs(0) if(regexm( msra_src_a2 , "[0-9][0-9][0-9][0-9]"))
gen msra_year_a3 = regexs(0) if(regexm( msra_src_a3 , "[0-9][0-9][0-9][0-9]"))


*Destring years to numeric
destring msra_year_a1, replace
destring msra_year_a2, replace
destring msra_year_a3, replace

*Generating year of most recent sitting 
gen msra_year_last= msra_year_a1 if msra_year_a2==.
replace  msra_year_last= msra_year_a2 if msra_year_a2!=. &   msra_year_a3==.
replace  msra_year_last= msra_year_a3 if msra_year_a3!=.


*convert string dates to stata dates
generate casc_full_date=substr(rcpsych_casc_d1_exam_dateresult, 1, 10) 
generate casc_date_hr = date(casc_full_date, "YMD") 
*NOTE HR==human readable
format %td casc_date_hr
gen casc_date=casc_date_hr
format %9.0g casc_date

generate paper1_full_date=substr(rcpsych_1_d1_exam_dateresult, 1, 10) 
generate paper1_date = date(paper1_full_date, "YMD")
format %td paper1_date

generate paper2_full_date=substr(rcpsych_2_d1_exam_dateresult, 1, 10) 
generate paper2_date = date(paper2_full_date, "YMD")
format %td paper2_date

generate paper3_full_date=substr(rcpsych_3_d1_exam_dateresult, 1, 10) 
generate paper3_date = date(paper3_full_date, "YMD")
format %td paper3_date

generate papera_full_date=substr(rcpsych_a_d1_exam_dateresult, 1, 10) 
generate papera_date = date(papera_full_date, "YMD")
format %td papera_date

generate paperb_full_date=substr(rcpsych_b_d1_exam_dateresult, 1, 10) 
generate paperb_date = date(paperb_full_date, "YMD")
format %td paperb_date


*/
*If appointed to a psychiatry scheme
gen appointed=1 if _merge==2
replace appointed=0 if _merge==1

*standardise oriel selection centre scores 
*this needs to be standardised by diet- not year

*cleaning up the diet free text errors
replace msra_src_a1="MSRA Jan 2021 Final Scores (Round 1).xlsx" if msra_src_a1=="MSRA Jan 2021 Final Scores (Round 1).xlsx;MSRA Jan 2021 Final Scores (Round 1).xlsx"

*Cleaning up interview scores- some seem to have zero - out of range score 


replace oriel_interview_score=. if oriel_data_year==2013 & oriel_interview_score==0
replace oriel_interview_score=. if oriel_data_year==2014 & oriel_interview_score==0
replace oriel_interview_score=. if oriel_data_year==2015 & oriel_interview_score==0
replace oriel_interview_score=. if oriel_data_year==2016 & oriel_interview_score==0
replace oriel_interview_score=. if oriel_data_year==2017 & oriel_interview_score==0
replace oriel_interview_score=. if oriel_data_year==2018 & oriel_interview_score>3 & oriel_interview_score!=.
replace oriel_interview_score=. if oriel_data_year==2019 & oriel_interview_score>3 & oriel_interview_score!=.
replace oriel_interview_score=. if oriel_data_year==2020 & oriel_interview_score>3 & oriel_interview_score!=.



*drop if SC is a psych selection centre
replace oriel_interview_score=. if msra_src_a1=="MSRA_R1R_COVID_2020_CPT;MSRA_R1R_COVID_2020_GP"
replace oriel_interview_score=. if msra_src_a1=="MSRA_R1R_COVID_2020_GP"
replace oriel_interview_score=. if msra_src_a1=="SRA_STG_2015_R2GP"

*No interviews for 2020R1R or 2021
replace oriel_interview_score=. if msra_src_a1=="MSRA_R1R_COVID_2020_CPT" 
replace oriel_interview_score=. if msra_src_a1==" MSRA_R2R_SEPT_2020" 
replace oriel_interview_score=. if oriel_data_year==2021

gen msra=cps+sjt if sjt!=. & cps!=.



*keep the origibnal scores to compare

gen sc_orig= oriel_interview_score

* replacing bypass scores which are aribtraily given a '3': NOte a range of scores at SC were observed in 2019 for those msra > 540 - so treated as a non-bypass year; need to query
replace oriel_interview_score=. if msra>540 & oriel_data_year==2018 
*Need to query 2019
replace oriel_interview_score=. if msra>540 & oriel_data_year==2020 





encode msra_src_a1, gen(diet)

gen z_oriel_iv=.

forvalues i=2015/2021 {
	summ  oriel_interview_score if oriel_data_year==`i'
	replace z_oriel_iv=(oriel_interview_score-r(mean))/r(sd) if oriel_data_year==`i'
	}

rename _merge merge_casc
merge m:m casc_date using "C:\P155_psych\work\data\derived\P155_psych_casc_zscores_clean.dta"
*merge with casc mean and sd data

*standardise CASC scores Too much pass mark RTP missing to standardise accoring to RTP 
gen z_casc=.
foreach i of numlist 20361	20503	20698	20820	21067	21200	21438	21439	21440	21441	21564	21565	21566	21567	21802	21803	21804	21805	21935	21936	21937	21938	22165	22166	22167	22168	22169	22172	22173	22174	22175	22176	22207	22208	22209	22210	22211	22291	22292	22293	22294	22295	22298	22299	22300	22301	22302	22343	22418	22419	22420 {
replace z_casc=((rcpsych_casc_d1_exam_totalmark-casc_mean`i')/casc_sd`i') if casc_date==`i'
}

*NOTE cannot standardise paper 1 2 and 3 according to RTP as not pass marks provided


*standardise paper 1 scores
rename _merge merge_paper1
merge m:m paper1_date using "C:\P155_psych\work\data\derived\P155_psych_paper1_zscores_clean.dta"
*merge with paper 1 mean and sd data

*standardise paper 1 scores NOTE: Pass mark not available in many cases so will have to just standardise on raw mark
*NOTE: The internal standard setting process seems more effective than cohort standardising as evidenced by the stroinger relationship between say z_oriel scores and raw, rather than restandardised MRCPsych exam scores
gen z_paper1=.
foreach i of numlist  19702 19912 {
replace z_paper1=((rcpsych_a_d1_exam_totalmark - paper1_mean`i')/paper1_sd`i') if paper1_date==`i'
}

*standardise paper 2 scores
rename _merge merge_paper2
merge m:m paper2_date using "C:\P155_psych\work\data\derived\P155_psych_paper2_zscores_clean.dta"
*merge with paper 2 mean and sd data

*standardise paper 2 scores NOTE: Pass mark not available in many cases so will have to just standardise on raw mark
*NOTE: The internal standard setting process seems more effective than cohort standardising as evidenced by the stroinger relationship between say z_oriel scores and raw, rather than restandardised MRCPsych exam scores
gen z_paper2=.
foreach i of numlist 19639 19821 {
replace z_paper2=((rcpsych_a_d1_exam_totalmark - paper2_mean`i')/paper2_sd`i') if paper2_date==`i'
}


*standardise paper 3 scores
rename _merge merge_paper3
merge m:m paper3_date using "C:\P155_psych\work\data\derived\P155_psych_paper3_zscores_clean.dta"
*merge with paper 3 mean and sd data

*standardise paper 3 scores NOTE: Pass mark not available in many cases so will have to just standardise on raw mark
*NOTE: The internal standard setting process seems more effective than cohort standardising as evidenced by the stroinger relationship between say z_oriel scores and raw, rather than restandardised MRCPsych exam scores
gen z_paper3=.
foreach i of numlist 19639 19821 {
replace z_paper3=((rcpsych_a_d1_exam_totalmark - paper3_mean`i')/paper3_sd`i') if paper3_date==`i'
}



*standardise paper A scores
rename _merge merge_papera
merge m:m papera_date using "C:\P155_psych\work\data\derived\P155_psych_papera_zscores_clean.dta"
*merge with paper A mean and sd data

*standardise paper A scores NOTE: Pass mark not available in many cases so will have to just standardise on raw mark
*NOTE: The internal standard setting process seems more effective than cohort standardising as evidenced by the stroinger relationship between say z_oriel scores and raw, rather than restandardised MRCPsych exam scores
gen z_papera=.
foreach i of numlist 20423 20654 20789 20971 21158 21354 21522 21718 21886 22250 22264 22320 22453 {
replace z_papera=((rcpsych_a_d1_exam_totalmark - papera_mean`i')/papera_sd`i') if papera_date==`i'
}


*standardise paper B scores
rename _merge merge_paperb
merge m:m paperb_date using "C:\P155_psych\work\data\derived\P155_psych_paperb_zscores_clean.dta"
*merge with paper B mean and sd data

*standardise paper B scores NOTE: Pass mark not available in many cases so will have to just standardise on raw mark
*NOTE: The internal standard setting process seems more effective than cohort standardising as evidenced by the stroinger relationship between say z_oriel scores and raw, rather than restandardised MRCPsych exam scores
gen z_paperb=.
foreach i of numlist 20394 20587 20728 20910 21102 21284 21466 21648 21830 22195 22238 22264 22363 22399 {
replace z_paperb=((rcpsych_a_d1_exam_totalmark - paperb_mean`i')/paperb_sd`i') if paperb_date==`i'
}

egen z_written=rowmean(z_paper1 z_paper2 z_paper3 z_papera z_paperb)

rename rcpsych_a_d1_exam_totalmark papera_raw
label variable papera_raw "raw total score for paper A"
rename rcpsych_casc_d1_exam_totalmark casc_raw 
label variable casc_raw "raw total score for CASC"
rename rcpsych_b_d1_exam_totalmark paperb_raw
label variable papera_raw "raw total score for paper B"
rename rcpsych_1_d1_exam_totalmark paper1_raw 
rename rcpsych_2_d1_exam_totalmark paper2_raw 
rename rcpsych_3_d1_exam_totalmark paper3_raw 
label variable paper1_raw "raw total score for paper 1"
label variable paper2_raw "raw total score for paper 2"
label variable paper3_raw "raw total score for paper 3"

egen mean_written=rowmean(paper1_raw paper2_raw paper3_raw papera_raw paperb_raw)


*Drop interim variables for calculating standardised MRCPsych scores

drop papera_mean* papera_sd* casc_mean* casc_sd*
rename epm_score_first epm
label variable epm "EPM score at first attempt"
rename sjt_equated_first fp_sjt
label variable fp_sjt "Foundation Programme SJT score at first attempt"
destring arcp_outcome_ordered_max, replace

keep id casc_rtp msra msra_src_a1 clin_sc z_written port_sc oriel_interview_score diet primary_pmq_world_region_int hesa_tariff sec_int wp_index sjt cps epm fp_sjt lowses male mean_written plab1_rtp_first plab1_rtp_last plab2_rtp_first plab2_rtp_last z_oriel_iv casc_pass age_casc_att1 z_casc casc_raw appointed arcp_outcome_ordered_max bme msra_year_last oriel_data_year sc_orig
drop if id==.


*creating shorter names for Mplus friendliness
rename primary_pmq_world_region_in pmq
rename plab1_rtp_first plab1_1st
rename plab1_rtp_last plab1_l
rename plab2_rtp_first plab2_1st
rename plab2_rtp_last plab2_l
rename hesa_tariff a_tarif
rename mean_written written
rename z_oriel_iv sc
rename age_casc_att1 age_casc
rename appointed appoint
rename arcp_outcome_ordered_max arcp_max

order id casc_raw casc_pass sjt cps sc written
drop if id==.
*set  the standardised sc ratings for GP selection  on roughly the same metric to prevent out of range values- not a problem with psychiatry selection where numbers were reasonable - re-normalising degrades the relationship with outcomes of interest 
/*

forvalues i=2012/2020   {
	summ sc if oriel_data_year==`i'
	replace sc=(sc-r(min))/(r(max)-r(min)) if oriel_data_year==`i'
}


*/

*Note: ARCP outcomes are not fully included - only the max outcome so multilevel modelling not possible
*Would have to get more ARCP data to model this properly and include whether the outcome was related to exam failure

*Only those with complete MSRA data included 
drop if sjt==. | cps==.
gen tot_sc= (clin_sc + port_sc) if clin_sc!=. & port_sc!=.
label variable tot_sc "Non-imputed SC total score Clin + port- see also tot_sc_i for passively imputed version"

label variable sc "old, faulty SC scores"
label variable clin_sc "Clinical Scenario Score for SC"
label variable port_sc "Portfolio station score for SC"
save "C:\P155_psych\work\data\derived\P155_psych_MASTER.dta", replace
drop z_written
stata2mplus using  "C:\P155_psych\work\data\derived\P155_psych_MASTER_4Mplus", replace
*******IMPUTATION*********************************


*Imputation for stata
use "C:\P155_psych\work\data\derived\P155_psych_MASTER.dta", clear
*z scores for written exams not imputed or used in the analysis 
drop z_written
mi set wide

*Describes missing patterns
*mi misstable patterns, frequency
*NOte you add the "noisily" option to impute to see what is going on
set seed 1234

mi register imputed a_tarif sec_int wp_index sjt cps epm fp_sjt lowses male written plab1_1st plab1_l plab2_1st plab2_l sc casc_pass age_casc casc_rtp appoint arcp_max bme clin_sc port_sc
mi impute chained (regress) casc_rtp sc sjt cps fp_sjt epm a_tarif plab1_1st plab2_1st age_casc written wp_index arcp_max clin_sc port_sc (ologit) sec_int (logit, augment) casc_pass bme = pmq male appoint, add(10) orderasis nomonotone force noisily 
mi passive: generate msra_i=cps + sjt
mi passive: generate tot_sc_i=clin_sc + port_sc
mi passive: generate pmq_i=pmq 
 
*mi passive: generate casc_pi=1 if casc_rtp>=0 & casc_rtp!=.
*mi reset casc_pi if casc_rtp<0
*mi passive: replace casc_pi=0 if casc_rtp<0
drop if id==.

**Note: Imputing CASC pass passively from CASC_RTP does not quite work- that is because you can score ABOVE the pass mark and still fail he you flunk more than the allowed number of stations!

save "C:\P155_psych\work\data\derived\P155_psych_MASTER_imputed_casc.dta", replace


*****IMPUTATION FOR MPLUS path

use "C:\P155_psych\work\data\derived\P155_psych_MASTER.dta", clear
drop z_written
order id casc_rtp written sjt cps sc 
cd C:\P155_psych\work\data\derived
mi set flongsep imp_psych
set seed 1234
*NOte lowses has issues being imputed as it is missing for all non-uk graduates
mi register imputed a_tarif sec_int wp_index sjt cps epm fp_sjt lowses male written plab1_1st plab1_l plab2_1st plab2_l sc casc_pass age_casc casc_rtp appoint arcp_max bme clin_sc port_sc
mi impute chained (regress) casc_rtp sc sjt cps fp_sjt epm a_tarif plab1_1st plab2_1st age_casc written wp_index arcp_max clin_sc port_sc (ologit) sec_int (logit, augment) casc_pass bme = pmq male appoint, add(10) orderasis nomonotone force noisily 
mi passive: generate msra_i=cps + sjt
mi passive: generate tot_sc_i=clin_sc + port_sc
mi passive: generate pmq_i=pmq 
drop if id==.


*saving Mplus datasets:

cd C:\P155_psych\work\data\derived\
sysdir set PLUS "C:\P155_psych\work\ado\plus\"
forvalues i=1/10 {
	use _`i'_imp_psych.dta, clear
	drop _mi_id
	stata2mplus using _`i'_imp_psych.dta, replace 

}

save "C:\P155_psych\work\data\derived\P155_psych_MASTER_imputed_LONG_casc.dta", replace

erase "C:\P155_psych\work\data\derived\imp_psych.dta"
use "C:\P155_psych\work\data\derived\P155_psych_MASTER.dta", clear


*/
*End of doing the do...