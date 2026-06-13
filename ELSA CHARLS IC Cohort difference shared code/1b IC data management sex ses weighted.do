**# ELSA	

//use "H_ELSA_IC-2021-10-30.dta", clear
set maxvar 20000
use "D:\OneDrive - UNSW\CHARLS Working\2020 April data update\Harmonized CHARLS\H_ELSA_IC-2021-10-30.dta"
distinct idauniq // 19802, includes people aged 18+; YAFEI: you will need the "distinct" package, type "ssc install distinct" if you don't have it
tab1 inw1-inw9 // obs by wave

//merge 1:1 idauniq using "H_ELSA_IC specific data-2021-12-16.dta", nogen

merge 1:1 idauniq using "D:\OneDrive - UNSW\CHARLS Working\2020 April data update\Harmonized CHARLS\H_ELSA_IC specific data-2021-12-16.dta", nogen
save "D:\OneDrive - UNSW\CHARLS Working\2020 April data update\Harmonized CHARLS\H_ELSA_IC-2021-10-30 working.dta", replace
clear

**
use "D:\OneDrive - UNSW\CHARLS Working\2020 April data update\Harmonized CHARLS\H_ELSA_IC-2021-10-30 working.dta"
rename idauniq ID

keep ///
	ID inw1-inw9 ///
	r*wspeed r*chr5sec r*balance_e /// locomotor: walking speed, chair-stand, balance
	r*gripsum r*fev r6fev_e r*hba /// vitality: grip strength, FEV, haemoglobin
	r*depres r*effort r*sleepr r*whappy r*flone r*fsad r*going r*enlife /// psychological: CESD, not sure about the version used in ELSA, it has 8 items (PSCEDA-PSCEDH); sad instead of bothered by little things, enjoyed life instead of hopeful
	r*mo r*dy r*yr r*dw r*imrc r*dlrc r*ser7 /// cognition: date naming (month, day, year, day of week), immediate recall, delayer recall, serial 7s
	r*hearing r*dsight r*nsight /// sensory: hearing, distant sight, near sight
	rabyear /// birth year
	r*agey  /// age 
	ragender /// gender
	r*mstath /// marital status
	raeducl h*atotf /// education harmonised and wealth
	r4dhea ///  DHEA blood assay
	r*igf /// insulin-like growth factor
	r*verbf /// animal naming test (verbal fluency)
	r*cancellation /// letter cancellation task (attention)
	r*sleepdifficulty /// trouble falling asleep
	r*sleepwake /// wake when asleep
	r*sleeptired /// wake up tired
	r*sleephour /// n of hours of sleep
	r*sleepoverall /// sleep quality overall
	r*lwtresp  /// person-level longitudinal weights
	r*cwtresp /// person-level cross-sectional weights
	r*nwtresp // person-level nurse sample weights

drop r1iwindy r2iwindy r3iwindy r4iwindy r5iwindy r6iwindy r7iwindy r8iwindy r9iwindy r2rxdepres r4rxdepres r8rxdepres r2trdepres r4trdepres r8trdepres r1socyr r2socyr r3socyr r4socyr r5socyr r6socyr r7socyr r8socyr r9socyr r1fagey r2fagey r3fagey r4fagey r5fagey r6fagey r7fagey r8fagey r9fagey

**redefine education variable
tab raeducl
gen edu2=.
replace edu2=0 if raeducl==1
replace edu2=1 if raeducl==2 | raeducl==3
tab edu2

sum raeducl edu2

rename (r1imrc r2imrc r3imrc r4imrc r5imrc r6imrc r7imrc r8imrc r9imrc ///
		r1dlrc r2dlrc r3dlrc r4dlrc r5dlrc r6dlrc r7dlrc r8dlrc r9dlrc ///
		r7ser7 r8ser7 r9ser7 ///
		r1mo r2mo r3mo r4mo r5mo r6mo r7mo r8mo r9mo ///
		r1dy r2dy r3dy r4dy r5dy r6dy r7dy r8dy r9dy ///
		r1yr r2yr r3yr r4yr r5yr r6yr r7yr r8yr r9yr ///
		r1dw r2dw r3dw r4dw r5dw r6dw r7dw r8dw r9dw ///
		r1wspeed r2wspeed r3wspeed r4wspeed r5wspeed r6wspeed r7wspeed r8wspeed r9wspeed ///
		r2gripsum r4gripsum r6gripsum r8gripsum ///
		r2fev r4fev r6fev_e ///
		r2balance_e r4balance_e r6balance_e ///
		r2chr5sec r4chr5sec r6chr5sec ///
		r1depres r2depres r3depres r4depres r5depres r6depres r7depres r8depres r9depres ///
		r1effort r2effort r3effort r4effort r5effort r6effort r7effort r8effort r9effort ///
		r1sleepr r2sleepr r3sleepr r4sleepr r5sleepr r6sleepr r7sleepr r8sleepr r9sleepr ///
		r1whappy r2whappy r3whappy r4whappy r5whappy r6whappy r7whappy r8whappy r9whappy ///
		r1flone r2flone r3flone r4flone r5flone r6flone r7flone r8flone r9flone ///
		r1fsad r2fsad r3fsad r4fsad r5fsad r6fsad r7fsad r8fsad r9fsad ///
		r1going r2going r3going r4going r5going r6going r7going r8going r9going ///
		r1enlife r2enlife r3enlife r4enlife r5enlife r6enlife r7enlife r8enlife r9enlife ///
		r1dsight r2dsight r3dsight r4dsight r5dsight r6dsight r7dsight r8dsight r9dsight ///
		r1nsight r2nsight r3nsight r4nsight r5nsight r6nsight r7nsight r8nsight r9nsight ///
		r1hearing r2hearing r3hearing r4hearing r5hearing r6hearing r7hearing r8hearing r9hearing ///
		r2hba r4hba r6hba r8hba r9hba ///
		r1agey r2agey r3agey r4agey r5agey r6agey r7agey r8agey r9agey ///
		r1mstath r2mstath r3mstath r4mstath r5mstath r6mstath r7mstath r8mstath r9mstath ///
		r4dhea /// 
		r4igf r6igf r8igf r9igf ///
		r1verbf r2verbf r3verbf r4verbf r5verbf r7verbf r8verbf r9verbf ///
		r1cancellation r2cancellation r3cancellation r4cancellation r5cancellation ///
		r4sleepdifficulty r6sleepdifficulty r8sleepdifficulty ///
		r4sleepwake r6sleepwake r8sleepwake ///
		r4sleeptired r6sleeptired r8sleeptired ///
		r4sleephour r6sleephour r8sleephour ///
		r4sleepoverall r6sleepoverall r8sleepoverall ///
		h1atotf h2atotf h3atotf h4atotf h5atotf h6atotf h7atotf h8atotf h9atotf ///
		r2lwtresp r3lwtresp r4lwtresp r5lwtresp r6lwtresp r7lwtresp r8lwtresp r9lwtresp ///
		r1cwtresp r2cwtresp r3cwtresp r4cwtresp r5cwtresp r6cwtresp r7cwtresp r8cwtresp r9cwtresp ///
		r2nwtresp r4nwtresp r6nwtresp r8nwtresp) ///
		///
		(imrc1 imrc2 imrc3 imrc4 imrc5 imrc6 imrc7 imrc8 imrc9 ///
		dlrc1 dlrc2 dlrc3 dlrc4 dlrc5 dlrc6 dlrc7 dlrc8 dlrc9 ///
		series7 series8 series9 ///
		month1 month2 month3 month4 month5 month6 month7 month8 month9 ///
		day1 day2 day3 day4 day5 day6 day7 day8 day9 ///
		year1 year2 year3 year4 year5 year6 year7 year8 year9 ///
		dayweek1 dayweek2 dayweek3 dayweek4 dayweek5 dayweek6 dayweek7 dayweek8 dayweek9 ///
		wspeed1 wspeed2 wspeed3 wspeed4 wspeed5 wspeed6 wspeed7 wspeed8 wspeed9 ///
		grip2 grip4 grip6 grip8 ///
		fev2 fev4 fev6 ///
		balance2 balance4 balance6 ///
		chr5sec2 chr5sec4 chr5sec6 ///
		depres1 depres2 depres3 depres4 depres5 depres6 depres7 depres8 depres9 ///
		effort1 effort2 effort3 effort4 effort5 effort6 effort7 effort8 effort9 ///
		sleep1 sleep2 sleep3 sleep4 sleep5 sleep6 sleep7 sleep8 sleep9 ///
		happy1 happy2 happy3 happy4 happy5 happy6 happy7 happy8 happy9 ///
		lonely1 lonely2 lonely3 lonely4 lonely5 lonely6 lonely7 lonely8 lonely9 ///
		sad1 sad2 sad3 sad4 sad5 sad6 sad7 sad8 sad9 ///
		going1 going2 going3 going4 going5 going6 going7 going8 going9 ///
		enjoy1 enjoy2 enjoy3 enjoy4 enjoy5 enjoy6 enjoy7 enjoy8 enjoy9 ///
		dsight1 dsight2 dsight3 dsight4 dsight5 dsight6 dsight7 dsight8 dsight9 ///
		nsight1 nsight2 nsight3 nsight4 nsight5 nsight6 nsight7 nsight8 nsight9 ///
		hearing1 hearing2 hearing3 hearing4 hearing5 hearing6 hearing7 hearing8 hearing9 ///
		hba2 hba4 hba6 hba8 hba9 ///
		age1 age2 age3 age4 age5 age6 age7 age8 age9 ///
		marital1 marital2 marital3 marital4 marital5 marital6 marital7 marital8 marital9 ///
		dhea4 ///
		igf4 igf6 igf8 igf9 ///
		verbf1 verbf2 verbf3 verbf4 verbf5 verbf7 verbf8 verbf9 ///
		cancellation1 cancellation2 cancellation3 cancellation4 cancellation5 ///
		sleepdifficulty4 sleepdifficulty6 sleepdifficulty8 ///
		sleepwake4 sleepwake6 sleepwake8 ///
		sleeptired4 sleeptired6 sleeptired8 ///
		sleephour4 sleephour6 sleephour8 ///
		sleepoverall4 sleepoverall6 sleepoverall8 ///
		hatotf1 hatotf2 hatotf3 hatotf4 hatotf5 hatotf6 hatotf7 hatotf8 hatotf9 ///
		lwtresp2 lwtresp3 lwtresp4 lwtresp5 lwtresp6 lwtresp7 lwtresp8 lwtresp9 ///
		cwtresp1 cwtresp2 cwtresp3 cwtresp4 cwtresp5 cwtresp6 cwtresp7 cwtresp8 cwtresp9 ///
		nwtresp2 nwtresp4 nwtresp6 nwtresp8)
		

*redefine wealth
xtile wealth1=hatotf1 if inw1==1, nq(2)
xtile wealth2=hatotf2 if inw2==1, nq(2)
xtile wealth3=hatotf3 if inw3==1, nq(2)
xtile wealth4=hatotf4 if inw4==1, nq(2)
xtile wealth5=hatotf5 if inw5==1, nq(2)
xtile wealth6=hatotf6 if inw6==1, nq(2)
xtile wealth7=hatotf7 if inw7==1, nq(2)
xtile wealth8=hatotf8 if inw8==1, nq(2)
xtile wealth9=hatotf9 if inw9==1, nq(2)

gen h_wealth=.
replace h_wealth=wealth1 if inw1==1 & h_wealth==.
replace h_wealth=wealth2 if inw2==1 & h_wealth==.
replace h_wealth=wealth3 if inw3==1 & h_wealth==.
replace h_wealth=wealth4 if inw4==1 & h_wealth==.
replace h_wealth=wealth5 if inw5==1 & h_wealth==.
replace h_wealth=wealth6 if inw6==1 & h_wealth==.
replace h_wealth=wealth7 if inw7==1 & h_wealth==.
replace h_wealth=wealth8 if inw8==1 & h_wealth==.
replace h_wealth=wealth9 if inw9==1 & h_wealth==.
tab h_wealth	//baseline wealth quantile	
		

reshape long inw imrc dlrc series month day year dayweek wspeed grip fev balance chr5sec depres effort sleep happy lonely sad going enjoy dsight nsight hearing hba dhea igf verbf cancellation sleepdifficulty sleepwake sleeptired sleephour sleepoverall age marital hatotf lwtresp cwtresp nwtresp, i(ID) j(wave)

distinct ID // 19802
drop if inw == 0
tab wave

recode wspeed chr5sec (0/1 = .)

reg month day year dayweek
egen memory = rowtotal (month day year dayweek) if e(sample)==1

recode wave (1 = 2002) (2 = 2004) (3 = 2006) (4 = 2008) (5 = 2010) (6 = 2012) (7 = 2014) (8 = 2016) (9 = 2018), gen(wav_year)
gen wav_age = wav_year - rabyear
replace age = wav_age if wav_age > 90 & age == 90

distinct ID
distinct ID if age == .
distinct ID if age>=60 & age != .
keep if age>=60 & age != .
distinct ID // 14715

hist age, by(wave) name(histage, replace)
distinct ID
bysort wave: distinct ID
sort ID wave
by ID: gen nobs = _n
ta nobs
by ID: gen totobs = nobs[_N]
ta totobs if nobs==1 // number of total observations / repeated measures 
ta wave if nobs==1 // number of first observations by wave 

egen sub_psychological = rownonmiss (depres effort sleep happy lonely going)
egen sub_locomotor = rownonmiss (wspeed chr5sec balance)
egen sub_vitality = rownonmiss (grip fev hba)
egen sub_cognition = rownonmiss (imrc dlrc memory)
egen sub_sensory = rownonmiss (hearing nsight dsight)
tab1 sub*

egen availableinfo = rowtotal (sub_psychological sub_locomotor sub_vitality sub_cognition sub_sensory)
ta availableinfo
recode availableinfo (18=1) (else=0), gen(fullinfo)
recode availableinfo (0=0) (else=1), gen(partialinfo)

hist age if fullinfo==1, by(wave) name(fullinfobyage, replace) // by design, no fullinfo in any wave if series is included (e.g., no info on series between waves 1-6, no info on FEV in waves 7-9)
ta age if fullinfo==1 & wave==1
hist age if partialinfo==1, by(wave) name(partialinfobyage, replace)

bysort wave: sum depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight

sort ID wave
by ID: gen gen_baseline = age[1] 
recode gen_baseline(60/64=60) (65/69=65) (70/74=70) (75/79=75) (80/84=80) (85/89=85) (90/max=90)
ta gen_baseline if nobs==1
bysort gen_baseline: sum totobs
bysort gen_baseline: sum totobs if fullinfo==1
bysort gen_baseline: sum totobs if partialinfo==1

recode rabyear (1900/1909 = 1900) (1910/1919 = 1910) (1920/1929 = 1920) (1930/1934 = 1930) (1935/1939 = 1935) (1940/1944 = 1940) (1945/1949 = 1945) (1950/1954 = 1950) (1955/1959 = 1955) (1960/1964 = 1960) (1965/1969 = 1965), gen(byear_decade)
ta byear_decade if nobs==1

preserve
keep if fullinfo == 1
distinct ID
bysort ID: gen nobs_temp = [_n]
ta nobs_temp
ta byear_decade if nobs_temp == 1 
restore

distinct ID if partialinfo
ta gen_baseline if nobs==1 & partialinfo
ta byear_decade if nobs==1 & partialinfo // birth year, partialinfo

distinct ID if availableinfo > 9
ta gen_baseline if nobs==1 & partialinfo

sort ID wave
by ID: egen totobs_partial = sum(partialinfo)
by ID: egen totobs_full = sum(fullinfo)

ta totobs_full if nobs==1
ta totobs_full gen_baseline if nobs==1, col

ta totobs_partial if nobs==1
ta totobs_partial gen_baseline if nobs==1, col

recode balance (1/3=0) (4=1), gen(balance_bin)

distinct ID // 14712

recode depres effort sleep lonely going (0=1) (1=0) // so higher scores are better health / IC
recode dsight nsight hearing (1=5) (2=4) (4=2) (5 6=1)

bysort wave: sum ID depres effort happy lonely going sleep wspeed chr5sec balance_bin grip fev hba imrc dlrc memory hearing nsight dsight

bysort wave: tab1 depres effort sleep happy lonely going imrc dlrc memory hearing nsight dsight balance_bin, mis
bysort wave: sum wspeed chr5sec grip fev hba
bysort wave: mdesc wspeed chr5sec grip fev hba // YAFEI: need the mdesc package; type "ssc install mdesc" if you don't have it

recode grip (60/max = 60) 

replace wspeed = -1*log(wspeed)
sum wspeed
replace wspeed = wspeed - r(min)
	hist wspeed

replace chr5sec = -1*log(chr5sec)
sum chr5sec
replace chr5sec= chr5sec- r(min)
	hist chr5sec

recode ragender (1=0) (2=1), gen(female)



**overall
preserve 
keep if partialinfo==1
tab1 hearing dsight nsight
save elsa_for_fscores, replace // YAFEI: this is a convenience dataset to useful to merge with the factor scores generated in Mplus
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using elsa_for_fscores, nolabel novar replace // YAFEI: this is the dataset you will need to obtain the factor scores in Mplus 
restore


*by gender
preserve 
keep if partialinfo==1 & female == 0
recode memory (0 = 1) // no observations of 0 under condition 2
sort ID wave
save elsa_for_fscores_female0, replace 
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using elsa_for_fscores_female0, nolabel novar replace // YAFEI: this dataset will be useful for attaching the male-specific factor scores
restore

preserve 
keep if partialinfo==1 & female == 1
recode memory (0 = 1) // no observations of 0 under condition 2
sort ID wave
save elsa_for_fscores_female1, replace
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using elsa_for_fscores_female1, nolabel novar replace // YAFEI: this dataset will be useful for attaching the female-specific factor scores
restore


*by education
preserve 
keep if partialinfo==1 & edu2 == 0
recode memory (0 = 1) // no observations of 0 under condition 2
sort ID wave
save elsa_for_fscores_edu20, replace 
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using elsa_for_fscores_edu20, nolabel novar replace // YAFEI: this dataset will be useful for attaching the male-specific factor scores
restore

preserve 
keep if partialinfo==1 & edu2 == 1
recode memory (0 = 1) // no observations of 0 under condition 2
sort ID wave
save elsa_for_fscores_edu21, replace
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using elsa_for_fscores_edu21, nolabel novar replace // YAFEI: this dataset will be useful for attaching the female-specific factor scores
restore


**by wealth
preserve 
keep if partialinfo==1 & h_wealth == 1
recode memory (0 = 1) // no observations of 0 under condition 2
sort ID wave
save elsa_for_fscores_h_wealth1, replace 
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using elsa_for_fscores_h_wealth1, nolabel novar replace // YAFEI: this dataset will be useful for attaching the male-specific factor scores
restore

preserve 
keep if partialinfo==1 & h_wealth == 2
recode memory (0 = 1) // no observations of 0 under condition 2
sort ID wave
save elsa_for_fscores_h_wealth2, replace
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using elsa_for_fscores_h_wealth2, nolabel novar replace // YAFEI: this dataset will be useful for attaching the female-specific factor scores
restore









**# CHARLS
use "D:\OneDrive - UNSW\CHARLS Working\2020 April data update\Harmonized CHARLS\H_CHARLS_IC-2021-10-30", clear
distinct ID // 25586 diff IDs
merge 1:1 ID using "D:\OneDrive - UNSW\CHARLS Working\2020 April data update\Harmonized CHARLS\H_CHARLS_IC specific data-2021-12-16", nogen // CHARLS specific data

distinct ID // 25586 diff IDs
tab1 inw1 inw2 inw3 inw4 // obs by wave
save "D:\OneDrive - UNSW\CHARLS Working\2020 April data update\Harmonized CHARLS\H_CHARLS_IC-2021-10-30 working.dta", replace

*
use "D:\OneDrive - UNSW\CHARLS Working\2020 April data update\Harmonized CHARLS\H_CHARLS_IC-2021-10-30 working.dta"

keep ///
	ID inw1 inw2 inw3 inw4 /// 
	r*wspeed r*chr5sec r*balance /// locomotor: walking speed, chair-stand, balance
	r*gripsum r*puff r*hba /// vitality: grip strength, FEV, haemoglobin
	r*depresl r*effortl r*sleeprl r*whappyl r*flonel r*botherl r*goingl r*mindtsl* r*fhopel r*fearll /// psychological: CESD-R-10 (https://www.brandeis.edu/roybal/docs/CESD-10_website_PDF.pdf)
	r*mo r*dy r*yr r*dw r*imrc r*dlrc r*ser7 /// cognition: date naming (month, day, year, day of week), immediate recall, delayer recall, serial 7s
	r*hearing r*dsight r*nsight /// sensory: hearing, distant sight, near sight
	rabyear /// birth year
	r*agey  /// age 
	ragender /// gender
	r*mstath /// marital status
	raeducl /// education harmonised
	h*rural /// rural dwelling
	edu hh*cperc ///
	r1draw r2draw r3draw r4draw r1season r1sleephour r1nap r2season r2sleephour r2nap r3season r3sleephour r3nap r4season r4sleephour r4nap /// CHARLS specific items
	r*wtrespb r*wtresp r2wtrespl r*wthh r*wthha r*wtrespa r*wtrespbiob

drop r1jbgyr r2jbgyr r3jbgyr r4jbgyr r1jbgmo r2jbgmo r3jbgmo r4jbgmo r1retyr r2retyr r3retyr r4retyr
	
rename (r1imrc r2imrc r3imrc r4imrc ///
		r1dlrc r2dlrc r3dlrc r4dlrc ///
		r1ser7 r2ser7 r3ser7 r4ser7 ///
		r1mo r2mo r3mo r4mo ///
		r1dy r2dy r3dy r4dy ///
		r1yr r2yr r3yr r4yr ///
		r1dw r2dw r3dw r4dw ///
		r1wspeed r2wspeed r3wspeed ///
		r1gripsum r2gripsum r3gripsum ///
		r1puff r2puff r3puff ///
		r1balance r2balance r3balance ///
		r1chr5sec r2chr5sec r3chr5sec ///
		r1depresl r2depresl r3depresl r4depresl ///
		r1effortl r2effortl r3effortl r4effortl ///
		r1sleeprl r2sleeprl r3sleeprl r4sleeprl ///
		r1whappyl r2whappyl r3whappyl r4whappyl ///
		r1flonel r2flonel r3flonel r4flonel ///
		r1botherl r2botherl r3botherl r4botherl ///
		r1goingl r2goingl r3goingl r4goingl ///
		r1mindtsl r2mindtsl r3mindtsl r4mindtsl ///
		r1fhopel r2fhopel r3fhopel r4fhopel ///
		r1fearll r2fearll r3fearll r4fearll ///
		r1dsight r2dsight r3dsight r4dsight ///
		r1nsight r2nsight r3nsight r4nsight ///
		r1hearing r2hearing r3hearing r4hearing ///
		r1hba r3hba ///
		r1agey r2agey r3agey r4agey ///
		r1mstath r2mstath r3mstath r4mstath ///
		h1rural h2rural h3rural h4rural ///
		r1draw r2draw r3draw r4draw ///
		r1season r2season r3season r4season ///
		r1sleephour r2sleephour r3sleephour r4sleephour /// 
		r1nap  r2nap r3nap r4nap ///
		hh1cperc hh2cperc hh3cperc hh4cperc ///
		r1wtrespb r2wtrespb r3wtrespb r4wtrespb r1wtresp r2wtresp r3wtresp r4wtresp r2wtrespl r1wthh r2wthh r3wthh r4wthh r1wthha r2wthha r3wthha r4wthha ///
		r1wtrespa r2wtrespa r3wtrespa r1wtrespbiob r2wtrespbiob r3wtrespbiob) ///
		///
		(imrc1 imrc2 imrc3 imrc4 ///
		dlrc1 dlrc2 dlrc3 dlrc4 ///
		series1 series2 series3 series4 ///
		month1 month2 month3 month4 ///
		day1 day2 day3 day4 ///
		year1 year2 year3 year4 ///
		dayweek1 dayweek2 dayweek3 dayweek4 ///
		wspeed1 wspeed2 wspeed3 ///
		grip1 grip2 grip3 ///
		fev1 fev2 fev3 ///
		balance1 balance2 balance3 ///
		chr5sec1 chr5sec2 chr5sec3 ///
		depres1 depres2 depres3 depres4 ///
		effort1 effort2 effort3 effort4 ///
		sleep1 sleep2 sleep3 sleep4 ///
		happy1 happy2 happy3 happy4 ///
		lonely1 lonely2 lonely3 lonely4 ///
		bother1 bother2 bother3 bother4 ///
		going1 going2 going3 going4 ///
		mind1 mind2 mind3 mind4 ///
		hope1 hope2 hope3 hope4 ///
		fear1 fear2 fear3 fear4 ///
		dsight1 dsight2 dsight3 dsight4 ///
		nsight1 nsight2 nsight3 nsight4 ///
		hearing1 hearing2 hearing3 hearing4 ///
		hba1 hba3 ///
		age1 age2 age3 age4 ///
		marital1 marital2 marital3 marital4 ///
		rural1 rural2 rural3 rural4 ///
		draw1 draw2 draw3 draw4 ///
		season1 season2 season3 season4 ///
		sleephour1 sleephour2 sleephour3 sleephour4 ///
		nap1 nap2 nap3 nap4 ///
		hhcperc1 hhcperc2 hhcperc3 hhcperc4 ///
		wtrespb1 wtrespb2 wtrespb3 wtrespb4 wtresp1 wtresp2 wtresp3 wtresp4 wtrespl2 wthh1 wthh2 wthh3 wthh4 wthha1 wthha2 wthha3 wthha4 ///
		wtrespa1 wtrespa2 wtrespa3 wtrespbiob1 wtrespbiob2 wtrespbiob3)

**redefine education
*tab raeducl

gen edu2=0 if edu!=.
replace edu2=1 if edu==2 | edu==3 | edu==4
tab edu2

**redefine wealth - household consumption per capta
sum hhcperc1 hhcperc2 hhcperc3 hhcperc4

xtile wealth1=hhcperc1 if inw1==1, nq(2)
xtile wealth2=hhcperc2 if inw2==1, nq(2)
xtile wealth3=hhcperc3 if inw3==1, nq(2)
xtile wealth4=hhcperc4 if inw4==1, nq(2)

gen h_wealth=.
replace h_wealth=wealth1 if inw1==1 & h_wealth==.
replace h_wealth=wealth2 if inw2==1 & h_wealth==.
replace h_wealth=wealth3 if inw3==1 & h_wealth==.
replace h_wealth=wealth4 if inw4==1 & h_wealth==.
tab h_wealth	//baseline wealth quantile	

	
reshape long inw imrc dlrc series month day year dayweek wspeed grip fev balance chr5sec depres effort sleep happy lonely bother going mind hope fear dsight nsight hearing hba age marital rural draw season sleephour nap consumption_pc wtrespb wtresp wtrespl wthh wthha wtrespa wtrespbiob, i(ID) j(wave)

distinct ID // 25586
label values wave
label variable wave "Wave"
drop if inw == 0
tab wave

recode wave-hba (.m .d .r .p .n .s .x .i = .)

recode wspeed chr5sec (0/1 = .)

reg month day year dayweek
egen memory = rowtotal (month day year dayweek) if e(sample)==1

reg month day year dayweek season
egen memory_ext_charls = rowtotal (month day year dayweek season) if e(sample)==1

distinct ID
distinct ID if age == .
distinct ID if age>=60 & age != .
keep if age>=60 & age != .
distinct ID // 13746

hist age, by(wave) name(histage, replace)
distinct ID
bysort wave: distinct ID
sort ID wave
by ID: gen nobs = _n
ta nobs
by ID: gen totobs = nobs[_N]
ta totobs if nobs==1 // number of total observations / repeated measures
ta wave if nobs==1 // number of first observations by wave

egen sub_psychological = rownonmiss (depres effort sleep happy lonely going)
egen sub_locomotor = rownonmiss (wspeed chr5sec balance)
egen sub_vitality = rownonmiss (grip fev hba)
egen sub_cognition = rownonmiss (imrc dlrc memory)
egen sub_sensory = rownonmiss (hearing nsight dsight)
tab1 sub*

egen availableinfo = rowtotal (sub_psychological sub_locomotor sub_vitality sub_cognition sub_sensory)
ta availableinfo
recode availableinfo (18=1) (else=0), gen(fullinfo)
recode availableinfo (0=0) (else=1), gen(partialinfo)

hist age if fullinfo==1, by(wave) name(fullinfobyage, replace) // by design, no fullinfo in waves 2 (no hba) or 4 (no locomotor or vitality)
ta age if fullinfo==1 & wave==1
hist age if partialinfo==1, by(wave) name(partialinfobyage, replace)

bysort wave: sum depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight

sort ID wave
by ID: gen gen_baseline = age[1]
recode gen_baseline(60/64=60) (65/69=65) (70/74=70) (75/79=75) (80/84=80) (85/89=85) (90/max=90)
ta gen_baseline if nobs==1
bysort gen_baseline: sum totobs
bysort gen_baseline: sum totobs if fullinfo==1
bysort gen_baseline: sum totobs if partialinfo==1

recode rabyear (1910/1919 = 1910) (1920/1929 = 1920) (1930/1934 = 1930) (1935/1939 = 1935) (1940/1944 = 1940) (1945/1949 = 1945) (1950/1954 = 1950) (1955/1959 = 1955) (1960/1964 = 1960) (1965/1969 = 1965), gen(byear_decade)
ta byear_decade

distinct ID if fullinfo
ta gen_baseline if nobs==1 & fullinfo // n of cases by gen_baseline, full info
ta rabyear if nobs==1 & fullinfo // birth year, full info
ta byear_decade if nobs==1 & fullinfo // birth year, full info

distinct ID if partialinfo
ta gen_baseline if nobs==1 & partialinfo
ta byear_decade if nobs==1 & partialinfo // birth year, partialinfo 

distinct ID if availableinfo > 9
ta gen_baseline if nobs==1 & partialinfo

sort ID wave
by ID: egen totobs_partial = sum(partialinfo)
by ID: egen totobs_full = sum(fullinfo)

ta totobs_full if nobs==1
ta totobs_full gen_baseline if nobs==1, col

ta totobs_partial if nobs==1
ta totobs_partial gen_baseline if nobs==1, col

recode balance (1/3=0) (4=1), gen(balance_bin)


distinct ID // 13746
destring ID, replace 

recode depres effort sleep lonely bother going mind fear (1=4) (2=3) (3=2) (4=1) // so higher scores are better health / IC
recode dsight nsight hearing (1=5) (2=4) (4=2) (5=1)

bysort wave: sum depres effort happy lonely going sleep wspeed chr5sec balance_bin grip fev hba imrc dlrc memory hearing nsight dsight

bysort wave: tab1 depres effort sleep happy lonely going imrc dlrc memory hearing nsight dsight balance_bin, mis
bysort wave: sum wspeed chr5sec grip fev hba
bysort wave: mdesc wspeed chr5sec grip fev hba

sort ID wave
preserve
keep if nobs==1
keep ID
gen id2 = _n
tempfile ids
save `ids', replace
restore
merge m:1 ID using `ids', nogen
replace ID = id2

recode grip (60/max = 60) 
replace wspeed = -1*log(wspeed)
sum wspeed
replace wspeed = wspeed - r(min)
	hist wspeed
replace chr5sec = -1*log(chr5sec)
sum chr5sec
replace chr5sec= chr5sec- r(min)
	hist chr5sec

replace fev = fev/30

sum depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin

**gender
recode ragender (1=0) (2=1), gen(female)


**all
preserve 
keep if partialinfo==1
keep if inlist(wave,1,2,3)
tab1 hearing dsight nsight
save charls_for_fscores, replace // YAFEI: convenience dataset to merge factor scores
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using charls_for_fscores, nolabel novar replace // YAFEI: dataset to obtain factor scores in Mplus
restore


**by gender
preserve 
keep if partialinfo==1 & female == 0
sort ID wave
save charls_for_fscores_female0, replace 
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using charls_for_fscores_female0, nolabel novar replace // YAFEI: this will be useful to attach the male-specific factor scores
restore

preserve 
keep if partialinfo==1 & female == 1
sort ID wave
save charls_for_fscores_female1, replace
keep ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
order ID wave depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin
recode depres effort sleep happy lonely going wspeed chr5sec balance grip fev hba imrc dlrc series memory hearing nsight dsight balance_bin (.=-9999)
export delimited using charls_for_fscores_female1, nolabel novar replace // YAFEI: this dataset will be useful for attaching the female-specific factor scores
restore








