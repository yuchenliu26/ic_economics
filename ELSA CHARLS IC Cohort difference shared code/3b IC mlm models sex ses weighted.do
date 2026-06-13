
**# ELSA

********************************************overall
	use elsa_fscores, clear
	
	sort ID wave
	drop totobs
	by ID: gen totobs = _N
	
	drop nobs
	by ID: gen nobs = _n
	
	distinct ID // 14710
	tab partialinfo wave
	sum rabyear totobs if nobs == 1, detail
	tab1 rabyear ragender raeducl marital if nobs == 1

	drop byear_decade
	recode rabyear (1900/1904 = 1900) (1905/1909 = 1905) (1910/1914 = 1910) (1915/1919 = 1915) (1920/1924 = 1920) (1925/1929 = 1925) (1930/1934 = 1930) (1935/1939 = 1935) (1940/1944 = 1940) (1945/1949 = 1945) (1950/1954 = 1950) (1955/1959 = 1955) (1960/1964 = 1960) (1965/1969 = 1965), gen(byear_decade)
	
	
	gen rabyear_cen = rabyear - 1920 // substantial number of observations in the range of 1920 - 1954
	
	gen wave_cen = wave - 1
	gen years = wave_cen * 2
	ta years
	
	rename (g psych locom vital cogni sensor) (intrinsic_capacity psychological locomotor vitality cognition sensory)	
	
	
**original results
	
	//not use
		foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {

		mixed `var' (c.years##c.years)##c.rabyear_cen || ID: years, cov(unstructured)
				
		margins, ///
		at(rabyear_cen=(0(1)30) years=(0(2)16)) ///
		saving(elsa_`var', replace) // YAFEI: this saves the marginal predicted levels for the plots
		
	}
	
	
	mixed intrinsic_capacity (c.years##c.years)##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_intrinsic_capacity, replace) 
	
	mixed psychological      (c.years##c.years)##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_psychological, replace) 
	
	mixed locomotor          (c.years##c.years)##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_locomotor, replace) 

	mixed vitality           (c.years##c.years)##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_vitality, replace) 
	
	mixed cognition          (c.years##c.years)##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_cognition, replace) 
	
	mixed sensory            (c.years##c.years)##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_sensory, replace)


	foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {
		
		use elsa_`var', clear
		gen year = _at1 + 2002
		gen cohort = _at2 + 1920
		gen age = year - cohort
		drop if !inrange(age,60,90)

		twoway ///
			(connected _margin age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48")) ///
			(connected _margin age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123")), ///
			xtitle("Age", size(small)) ytitle("Mean factor score", size(small)) title("`var'", size(medium)) ///
			legend(order(1 "1920" 3 "1930" 5 "1940" 7 "1950") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xlabel(60(5)90, gmin gmax labsize(small)) ///
			name(elsa_`var'_age, replace) ///
			ylab(-1.5(.5).5, gmin gmax labsize(small))
			
			
	 twoway ///
			(connected _margin year if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb year if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48")) ///
			(connected _margin year if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb year if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin year if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb year if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin year if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb year if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123")), ///
			xtitle("Year", size(small)) ytitle("Mean factor score", size(small)) title("`var'", size(medium)) ///
			legend(order(1 "1920" 3 "1930" 5 "1940" 7 "1950") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xtick(2002(4)2018) ///
			xlabel(2002(4)2018, labsize(small)) ///
			name(elsa_`var'_year, replace) ///
			ylab(-1.5(.5).5, gmin gmax labsize(small))
		
	}
	*by age
	grc1leg elsa_intrinsic_capacity_age elsa_psychological_age elsa_locomotor_age elsa_vitality_age elsa_cognition_age elsa_sensory_age, row(2)
	
	*by year
	grc1leg elsa_intrinsic_capacity_year elsa_psychological_year elsa_locomotor_year elsa_vitality_year elsa_cognition_year elsa_sensory_year, row(2)
	
	
	
		
	
**using survey weights and 95% confidence intervals

	foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {

		mixed `var' (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years, cov(unstructured)

		margins, ///
		at(rabyear_cen=(0(1)30) years=(0(2)16)) ///
		saving(elsa_`var', replace) // YAFEI: this saves the marginal predicted levels for the plots
		
	}
	
	mixed intrinsic_capacity (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_intrinsic_capacity, replace) 
	
	mixed psychological      (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_psychological, replace) 
	
	mixed locomotor          (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_locomotor, replace) 

	mixed vitality           (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_vitality, replace) 
	
	mixed cognition          (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_cognition, replace) 
	
	mixed sensory            (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_sensory, replace)


	foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {
		
		use elsa_`var', clear
		gen year = _at1 + 2002
		gen cohort = _at2 + 1920
		gen age = year - cohort
		drop if !inrange(age,60,90)

		twoway ///
			(connected _margin age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48")) ///
			(connected _margin age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123")), ///
			xtitle("Age", size(small)) ytitle("Mean factor score", size(small)) title("`var'", size(medium)) ///
			legend(order(1 "1920" 3 "1930" 5 "1940" 7 "1950") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xlabel(60(5)90, gmin gmax labsize(small)) ///
			name(elsa_`var'_age, replace) ///
			ylab(-1.5(.5).5, gmin gmax labsize(small))
		
	}
	
	grc1leg elsa_intrinsic_capacity_age elsa_psychological_age elsa_locomotor_age elsa_vitality_age elsa_cognition_age elsa_sensory_age, row(2)

	
	
***using longitudinal weights final
	mixed intrinsic_capacity (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_intrinsic_capacity, replace) 
	
	mixed psychological      (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_psychological, replace) 
	
	mixed locomotor          (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_locomotor, replace) 

	mixed vitality           (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_vitality, replace) 
	
	mixed cognition          (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_cognition, replace) 
	
	mixed sensory            (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_sensory, replace)


	foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {
		
		use elsa_`var', clear
		gen year = _at1 + 2002
		gen cohort = _at2 + 1920
		gen age = year - cohort
		drop if !inrange(age,60,90)

		twoway ///
			(connected _margin age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48")) ///
			(connected _margin age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123")), ///
			xtitle("Age", size(small)) ytitle("Mean factor score", size(small)) title("`var'", size(medium)) ///
			legend(order(1 "1920" 3 "1930" 5 "1940" 7 "1950") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xlabel(60(5)90, gmin gmax labsize(small)) ///
			name(elsa_`var'_age, replace) ///
			ylab(-1.5(.5).5, gmin gmax labsize(small))
		
	}
	
	grc1leg elsa_intrinsic_capacity_age elsa_psychological_age elsa_locomotor_age elsa_vitality_age elsa_cognition_age elsa_sensory_age, row(2)

	
	**export grid
		foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {
		
		use elsa_`var', clear
		gen year = _at1 + 2002
		gen cohort = _at2 + 1920
		gen age = year - cohort
		keep if cohort==1950 | cohort==1940 | cohort==1930 | cohort==1920
		sort cohort age
		
		export excel cohort age _margin _ci_lb _ci_ub using elsa_`var'_age, firstrow (variables) replace
		
	}
	
	
**using longitudinal weights
mixed intrinsic_capacity (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_ic, replace) 
marginsplot

mixed psychological (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_psychological, replace) 
marginsplot

mixed locomotor     (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_locomotor, replace) 
marginsplot

mixed vitality      (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
margins, at(rabyear_cen=(0(1)30) years=(0(2)16)) saving(elsa_vitality, replace) 
marginsplot, by (year)

mixed cognition     (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)
margins, saving(elsa_cognition, replace) 
marginsplot

mixed sensory       (c.years##c.years)##c.rabyear_cen [pw=lwtresp] || ID: years, cov(unstructured)



****************************************************************************************************************by sex
	* Separate fscores (by sex)

	use elsa_fscores_sex, clear
	
	sort ID wave
	drop totobs
	by ID: gen totobs = _N
	drop nobs
	by ID: gen nobs = _n
	distinct ID // 14710
	tab partialinfo wave
	sum rabyear totobs if nobs == 1, detail
	tab1 rabyear ragender raeducl marital if nobs == 1

	drop byear_decade
	recode rabyear (1900/1904 = 1900) (1905/1909 = 1905) (1910/1914 = 1910) (1915/1919 = 1915) (1920/1924 = 1920) (1925/1929 = 1925) (1930/1934 = 1930) (1935/1939 = 1935) (1940/1944 = 1940) (1945/1949 = 1945) (1950/1954 = 1950) (1955/1959 = 1955) (1960/1964 = 1960) (1965/1969 = 1965), gen(byear_decade)
	
	
	gen rabyear_cen = rabyear - 1920 
	
	gen wave_cen = wave - 1
	gen years = wave_cen * 2
	ta years
	

***************
rename (g psych locom vital cogni sensor) (ic psychological locomotor vitality cognition sensory)	

*female
mixed ic (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 1, cov(unstructured)
est sto elsa_female1_ic
mixed psychological (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 1, cov(unstructured)
est sto elsa_female1_psy
mixed locomotor (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 1, cov(unstructured)
est sto elsa_female1_loc
mixed vitality (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 1, cov(unstructured)
est sto elsa_female1_vit
mixed cognition (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 1, cov(unstructured)
est sto elsa_female1_cog
mixed sensory (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 1, cov(unstructured)
est sto elsa_female1_sen

esttab elsa_female1_ic elsa_female1_psy elsa_female1_loc elsa_female1_vit elsa_female1_cog elsa_female1_sen using elas_ic_female.rtf, replace b (%9.3fc) ci (%9.3fc) wide nostar transform(ln*: exp(@)^2 exp(@)^2 at*: tanh(@) (1-tanh(@)^2))
esttab elsa_female1_ic elsa_female1_psy elsa_female1_loc elsa_female1_vit elsa_female1_cog elsa_female1_sen using elas_ic_female.rtf, append b (%9.3fc) p (%9.3fc) wide transform(ln*: exp(@)^2 exp(@)^2 at*: tanh(@) (1-tanh(@)^2)) noparentheses

*male 
mixed ic (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 0, cov(unstructured)
est sto elsa_female0_ic
mixed psychological (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 0, cov(unstructured)
est sto elsa_female0_psy
mixed locomotor (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 0, cov(unstructured)
est sto elsa_female0_loc
mixed vitality (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 0, cov(unstructured)
est sto elsa_female0_vit
mixed cognition (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 0, cov(unstructured)
est sto elsa_female0_cog
mixed sensory (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years if female == 0, cov(unstructured)
est sto elsa_female0_sen

esttab elsa_female0_ic elsa_female0_psy elsa_female0_loc elsa_female0_vit elsa_female0_cog elsa_female0_sen using elas_ic_female.rtf, append b (%9.3fc) ci (%9.3fc) wide nostar transform(ln*: exp(@)^2 exp(@)^2 at*: tanh(@) (1-tanh(@)^2))
esttab elsa_female0_ic elsa_female0_psy elsa_female0_loc elsa_female0_vit elsa_female0_cog elsa_female0_sen using elas_ic_female.rtf, append b (%9.3fc) p (%9.3fc) wide transform(ln*: exp(@)^2 exp(@)^2 at*: tanh(@) (1-tanh(@)^2)) noparentheses


**
	preserve
	keep if female == 0 
	
	rename (g psych locom vital cogni sensor) (ic psychological locomotor vitality cognition sensory)	
		
	foreach var in ic psychological locomotor vitality cognition sensory {

		mixed `var' (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years, cov(unstructured)
		estat recovariance, correlation

		margins, ///
		at(rabyear_cen=(0(1)30) years=(0(2)16)) ///
		saving(elsa_`var'_female0, replace) 
		
	}		
	restore

**
		
	keep if female == 1 
	rename (g psych locom vital cogni sensor) (ic psychological locomotor vitality cognition sensory)
	
	foreach var in ic psychological locomotor vitality cognition sensory {

		mixed `var' (c.years##c.years)##c.rabyear_cen [pw=cwtresp] || ID: years, cov(unstructured)
		estat recovariance, correlation

		margins, ///
		at(rabyear_cen=(0(1)30) years=(0(2)16)) ///
		saving(elsa_`var'_female1, replace) 
		
	}		
			


	foreach var in ic psychological locomotor vitality cognition sensory {
		
		use elsa_`var'_female0, clear
		gen year = _at1 + 2002
		gen cohort = _at2 + 1920
		gen age = year - cohort
		drop if !inrange(age,60,90)
	
		twoway ///
			(connected _margin age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48"))  ///
			(connected _margin age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123")) ///
			(line _margin age if cohort == ., msymbol(O) msize(vsmall) color(black) lpattern(shortdash)) ///
			(line _margin age if cohort == ., msymbol(O) msize(vsmall) color(black) lpattern(solid)), ///
			xtitle("Age", size(small)) ytitle("Mean factor score", size(small)) title("`var' - Men", size(medium)) ///
			legend(order(1 "1920" 3 "1930" 5 "1940" 7 "1950" 9 "Women" 10 "Men") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xlabel(60(5)90, gmin gmax labsize(small)) ///
			name(elsa_`var'_age_female0, replace) ///
			ylab(-1.5(.5)1, gmin gmax labsize(small))
	}

grc1leg elsa_ic_age_female0 elsa_psychological_age_female0 elsa_locomotor_age_female0 elsa_vitality_age_female0 elsa_cognition_age_female0 elsa_sensory_age_female0, row(2)

	

	foreach var in ic psychological locomotor vitality cognition sensory {
		
		use elsa_`var'_female1, clear
		gen year = _at1 + 2002
		gen cohort = _at2 + 1920
		gen age = year - cohort
		drop if !inrange(age,60,90)

		twoway ///
			(connected _margin age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48") lpattern(shortdash)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1920, msymbol(O) msize(vsmall) color("173 220 48"))  ///
			(connected _margin age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(shortdash)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(shortdash)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(shortdash)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123")) ///
			(line _margin age if cohort == ., msymbol(O) msize(vsmall) color(black) lpattern(shortdash)) ///
			(line _margin age if cohort == ., msymbol(O) msize(vsmall) color(black) lpattern(solid)), ///
			xtitle("Age", size(small)) ytitle("Mean factor score", size(small)) title("`var' - Women", size(medium)) ///
			legend(order(1 "1920" 3 "1930" 5 "1940" 7 "1950" 9 "Women" 10 "Men") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xlabel(60(5)90, gmin gmax labsize(small)) ///
			name(elsa_`var'_age_female1, replace) ///
			ylab(-1.5(.5)1, gmin gmax labsize(small))
	}
	
grc1leg elsa_ic_age_female1 elsa_psychological_age_female1 elsa_locomotor_age_female1 elsa_vitality_age_female1 elsa_cognition_age_female1 elsa_sensory_age_female1, row(2)













	


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

		
***# CHARLS*********************************************************************************************************************************
use charls_fscores, clear

	sort ID wave
	
	drop totobs
	by ID: gen totobs = _N
	
	drop nobs
	by ID: gen nobs = _n
	
	distinct ID // 11411
	tab partialinfo wave
	sum rabyear totobs if nobs == 1, detail
	tab1 rabyear ragender raeducl marital if nobs == 1
	
	ta totobs if nobs == 1
	
	drop byear_decade
	recode rabyear (1900/1904 = 1900) (1905/1909 = 1905) (1910/1914 = 1910) (1915/1919 = 1915) (1920/1924 = 1920) (1925/1929 = 1925) (1930/1934 = 1930) (1935/1939 = 1935) (1940/1944 = 1940) (1945/1949 = 1945) (1950/1954 = 1950) (1955/1959 = 1955) (1960/1964 = 1960) (1965/1969 = 1965), gen(byear_decade)	
	
	recode wave (1 = 0) (2 = 2) (3 = 4) (4 = 7), gen(years) 
	
	keep if inrange(wave,1,3)
	
	sort ID wave
	
	recode wave (1 = 2011) (2 = 2013) (3 = 2015) (4 = 2018), gen(wav_year)
	gen wav_age = wav_year - rabyear
	
	gen rabyear_cen = rabyear - 1930 // substantial number of observations in the range of 1935 - 1951

rename (g psych locom vital cogni sensor) (intrinsic_capacity psychological locomotor vitality cognition sensory)
gen a2_wtrespb=wtrespb/10000


	foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {

		mixed `var' c.years##c.rabyear_cen || ID: years, cov(unstructured)
		estat recovariance, correlation

		margins, ///
		at(rabyear_cen=(0(1)20) years=(0(2)4)) ///
		saving(charls_`var', replace) // YAFEI: this saves the marginal predicted levels for the plots
		
	}		

	* Additional model for vitality without random slopes		
		mixed vitality c.years##c.rabyear_cen || ID: 
		estat recovariance, correlation

		margins, ///
		at(rabyear_cen=(0(1)20) years=(0(2)4)) ///
		saving(charls_vitality, replace) // YAFEI: this will replace the marginal predicted levels saved for vitality with new ones obtained without random slopes, as the additional complexity in the models is clearly not needed

	
	mixed intrinsic_capacity c.years##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)20) years=(0(2)4)) saving(charls_intrinsic_capacity, replace)
	
	mixed psychological c.years##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)20) years=(0(2)4)) saving(charls_psychological, replace)
	
	mixed locomotor c.years##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)20) years=(0(2)4)) saving(charls_locomotor, replace)
	
	mixed vitality c.years##c.rabyear_cen || ID: 
	margins, at(rabyear_cen=(0(1)20) years=(0(2)4)) saving(charls_vitality, replace)
	
	mixed cognition c.years##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)20) years=(0(2)4)) saving(charls_cognition, replace)
	
	mixed sensory c.years##c.rabyear_cen || ID: years, cov(unstructured)
	margins, at(rabyear_cen=(0(1)20) years=(0(2)4)) saving(charls_sensory, replace)
		
		
	foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {
		
		use charls_`var', clear
		gen year = _at1 + 2011
		gen cohort = _at2 + 1930
		gen age = year - cohort
		drop if !inrange(age,60,90)

		twoway ///
			(connected _margin age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123")) , ///
			xtitle("Age", size(small)) ytitle("Mean factor score", size(small)) title("`var'", size(medium)) ///
			legend(order(1 "1930" 3 "1940" 5 "1950") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xlabel(60(5)90, gmin gmax labsize(small)) ///
			name(charls_`var'_age, replace) ///
			ylab(-1.5(.5).5, gmin gmax labsize(small))
			
			
		twoway ///
			(connected _margin year if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb year if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin year if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb year if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin year if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb year if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123")) , ///
			xtitle("Year", size(small)) ytitle("Mean factor score", size(small)) title("`var'", size(medium)) ///
			legend(order(1 "1930" 3 "1940" 5 "1950") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xtick(2011(4)2015) ///
			xlabel(2011(4)2015, labsize(small)) ///
			name(charls_`var'_year, replace) ///
			ylab(-1.5(.5).5, gmin gmax labsize(small))
			
	}
	
	



*by age
grc1leg charls_intrinsic_capacity_age charls_psychological_age charls_locomotor_age charls_vitality_age charls_cognition_age charls_sensory_age, row(2)

*by year
grc1leg charls_intrinsic_capacity_year charls_psychological_year charls_locomotor_year charls_vitality_year charls_cognition_year charls_sensory_year, row(2)


***charls using survey weights
mixed intrinsic_capacity c.years##c.rabyear_cen [pw=a2_wtrespb]  || ID: years, cov(unstructured)
mixed psychological      c.years##c.rabyear_cen [pw=a2_wtrespb]  || ID: years, cov(unstructured)
mixed locomotor          c.years##c.rabyear_cen [pw=a2_wtrespb]  || ID: years, cov(unstructured)
mixed vitality           c.years##c.rabyear_cen [pw=a2_wtrespb]  || ID: 
mixed cognition          c.years##c.rabyear_cen [pw=a2_wtrespb]  || ID: years, cov(unstructured)
mixed sensory            c.years##c.rabyear_cen [pw=a2_wtrespb]  || ID: years, cov(unstructured)





	foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {

		mixed `var' c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years, cov(unstructured)

		margins, ///
		at(rabyear_cen=(0(1)20) years=(0(2)4)) ///
		saving(charls_`var', replace) // YAFEI: this saves the marginal predicted levels for the plots
		
	}		

	* Additional model for vitality without random slopes
				
		mixed vitality c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: 

		margins, ///
		at(rabyear_cen=(0(1)20) years=(0(2)4)) ///
		saving(charls_vitality, replace) // YAFEI: this will replace the marginal predicted levels saved for vitality with new ones obtained without random slopes, as the additional complexity in the models is clearly not needed


	foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {
		
		use charls_`var', clear
		gen year = _at1 + 2011
		gen cohort = _at2 + 1930
		gen age = year - cohort
		drop if !inrange(age,60,90)

		twoway ///
			(connected _margin age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123")) , ///
			xtitle("Age", size(small)) ytitle("Mean factor score", size(small)) title("`var'", size(medium)) ///
			legend(order(1 "1930" 3 "1940" 5 "1950") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xlabel(60(5)90, gmin gmax labsize(small)) ///
			name(charls_`var'_age, replace) ///
			ylab(-1.5(.5).5, gmin gmax labsize(small))
			
	}

grc1leg charls_intrinsic_capacity_age charls_psychological_age charls_locomotor_age charls_vitality_age charls_cognition_age charls_sensory_age, row(2)


	**grids
		foreach var in intrinsic_capacity psychological locomotor vitality cognition sensory {
		
		use charls_`var', clear
		gen year = _at1 + 2011
		gen cohort = _at2 + 1930
		gen age = year - cohort
		keep if cohort==1950 | cohort==1940 | cohort==1930
		sort cohort age
		
		export excel cohort age _margin _ci_lb _ci_ub using charls_`var'_age, firstrow (variables) replace
					
	}

****************************************************************************************CAHRLS mixed models by gender
use charls_fscores_sex, clear

	sort ID wave
	drop totobs
	by ID: gen totobs = _N
	
	drop nobs
	by ID: gen nobs = _n
	
	distinct ID // 11411
	tab partialinfo wave
	sum rabyear totobs if nobs == 1, detail
	tab1 rabyear ragender raeducl marital if nobs == 1
	
	ta totobs if nobs == 1
	
	drop byear_decade
	recode rabyear (1900/1904 = 1900) (1905/1909 = 1905) (1910/1914 = 1910) (1915/1919 = 1915) (1920/1924 = 1920) (1925/1929 = 1925) (1930/1934 = 1930) (1935/1939 = 1935) (1940/1944 = 1940) (1945/1949 = 1945) (1950/1954 = 1950) (1955/1959 = 1955) (1960/1964 = 1960) (1965/1969 = 1965), gen(byear_decade)	
	
	recode wave (1 = 0) (2 = 2) (3 = 4) (4 = 7), gen(years) 
	
	keep if inrange(wave,1,3)
	
	sort ID wave
	
	recode wave (1 = 2011) (2 = 2013) (3 = 2015) (4 = 2018), gen(wav_year)
	gen wav_age = wav_year - rabyear
	
	gen rabyear_cen = rabyear - 1930 // substantial number of observations in the range of 1935 - 1951

	rename (g psych locom vital cogni sensor) (ic psychological locomotor vitality cognition sensory)
	gen a2_wtrespb=wtrespb/10000

*********table
*female
mixed ic c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 1, cov(unstructured)
est sto charls_female1_ic
mixed psychological c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 1, cov(unstructured)
est sto charls_female1_psy
mixed locomotor c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 1, cov(unstructured)
est sto charls_female1_loc
mixed vitality c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 1, cov(unstructured)
est sto charls_female1_vit
mixed cognition c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 1, cov(unstructured)
est sto charls_female1_cog
mixed sensory c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 1, cov(unstructured)
est sto charls_female1_sen

esttab charls_female1_ic charls_female1_psy charls_female1_loc charls_female1_vit charls_female1_cog charls_female1_sen using charls_ic_female.rtf, replace b (%9.3fc) ci (%9.3fc) wide nostar transform(ln*: exp(@)^2 exp(@)^2 at*: tanh(@) (1-tanh(@)^2))
esttab charls_female1_ic charls_female1_psy charls_female1_loc charls_female1_vit charls_female1_cog charls_female1_sen using charls_ic_female.rtf, append b (%9.3fc) p (%9.3fc) wide transform(ln*: exp(@)^2 exp(@)^2 at*: tanh(@) (1-tanh(@)^2)) noparentheses

*male
mixed ic c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 0, cov(unstructured)
est sto charls_female0_ic
mixed psychological c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 0, cov(unstructured)
est sto charls_female0_psy
mixed locomotor c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 0, cov(unstructured)
est sto charls_female0_loc
mixed vitality c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 0, cov(unstructured)
est sto charls_female0_vit
mixed cognition c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 0, cov(unstructured)
est sto charls_female0_cog
mixed sensory c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years if female == 0, cov(unstructured)
est sto charls_female0_sen

esttab charls_female0_ic charls_female0_psy charls_female0_loc charls_female0_vit charls_female0_cog charls_female0_sen using charls_ic_female.rtf, append b (%9.3fc) ci (%9.3fc) wide nostar transform(ln*: exp(@)^2 exp(@)^2 at*: tanh(@) (1-tanh(@)^2))
esttab charls_female0_ic charls_female0_psy charls_female0_loc charls_female0_vit charls_female0_cog charls_female0_sen using charls_ic_female.rtf, append b (%9.3fc) p (%9.3fc) wide transform(ln*: exp(@)^2 exp(@)^2 at*: tanh(@) (1-tanh(@)^2)) noparentheses

***	
	preserve	
	keep if female == 0	
	foreach var in ic psychological locomotor vitality cognition sensory {

		mixed `var' c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years, cov(unstructured)
		margins, at(rabyear_cen=(0(1)20) years=(0(2)4)) saving(charls_`var'_female0, replace)
		}			
	restore
	
*	
	preserve	
	keep if female == 1		
	foreach var in ic psychological locomotor vitality cognition sensory {
		mixed `var' c.years##c.rabyear_cen [pw=a2_wtrespb] || ID: years, cov(unstructured)
		margins, at(rabyear_cen=(0(1)20) years=(0(2)4)) saving(charls_`var'_female1, replace)
		}		
	restore
	

*
	foreach var in ic psychological locomotor vitality cognition sensory {
		
		use charls_`var'_female0, clear
		gen year = _at1 + 2011
		gen cohort = _at2 + 1930
		gen age = year - cohort
		drop if !inrange(age,60,90)

		twoway ///
			(connected _margin age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(solid)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123"))  ///
			(line _margin age if cohort == ., color(black) lpattern(shortdash)) ///
			(line _margin age if cohort == ., color(black) lpattern(solid)), ///
			xtitle("Age", size(small)) ytitle("Mean factor score", size(small)) title("`var' - Men", size(medium)) ///
			legend(order(1 "1930" 3 "1940" 5 "1950" 7 "Women" 8 "Men") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xlabel(60(5)90, gmin gmax labsize(small)) ///
			name(charls_`var'_age_female0, replace) ///
			ylab(-1.5(.5)1, gmin gmax labsize(small))
	}
	
	
	foreach var in ic psychological locomotor vitality cognition sensory {
		
		use charls_`var'_female1, clear
		gen year = _at1 + 2011
		gen cohort = _at2 + 1930
		gen age = year - cohort
		drop if !inrange(age,60,90)

		twoway ///
			(connected _margin age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128") lpattern(shortdash)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1930, msymbol(O) msize(vsmall) color("40 174 128")) ///
			(connected _margin age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142") lpattern(shortdash)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1940, msymbol(O) msize(vsmall) color("44 114 142")) ///
			(connected _margin age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123") lpattern(shortdash)) ///
			(rcap _ci_ub _ci_lb age if cohort == 1950, msymbol(O) msize(vsmall) color("71 45 123"))  ///
			(line _margin age if cohort == ., color(black) lpattern(shortdash)) ///
			(line _margin age if cohort == ., color(black) lpattern(solid)), ///
			xtitle("Age", size(small)) ytitle("Mean factor score", size(small)) title("`var' - Women", size(medium)) ///
			legend(order(1 "1930" 3 "1940" 5 "1950" 7 "Women" 8 "Men") rows(1) region(lwidth(none)) rowgap(vsmall) colgap(medium) keygap(vsmall) size(vsmall)) scheme(s1mono) ///
			xlabel(60(5)90, gmin gmax labsize(small)) ///
			name(charls_`var'_age_female1, replace) ///
			ylab(-1.5(.5)1, gmin gmax labsize(small))
	}

*by age
grc1leg charls_ic_age_female1 charls_psychological_age_female1 charls_locomotor_age_female1 charls_vitality_age_female1 charls_cognition_age_female1 charls_sensory_age_female1, imargin(0 0 0 0)
grc1leg charls_ic_age_female0 charls_psychological_age_female0 charls_locomotor_age_female0 charls_vitality_age_female0 charls_cognition_age_female0 charls_sensory_age_female0, imargin(0 0 0 0)







	
	
	
	
	
	
	
	


	