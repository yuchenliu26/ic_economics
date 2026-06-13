
**# ELSA WLSMV factor scores

	* Partial info, all waves, WLSMV --- overall
	import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\elsa_fscores.csv", clear delim(" ", collapse) // use my own path

		//import delimited "elsa_fscores.csv", clear delim(" ", collapse) // YAFEI: these are the factor scores generated in Mplus
		keep v20
		* YAFEI: browse the dataset and copy them
		use elsa_for_fscores, clear
		* YAFEI: browse the dataset and paste them
		rename v20 g
		save elsa_fscores, replace

	import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\elsa_fscores_cf.csv", clear delim(" ", collapse) // use my own path
		//import delimited "elsa_fscores_cf.csv", clear delim(" ", collapse)
		keep v20 v22 v24 v26 v28
		* YAFEI: same, copy
		use elsa_fscores, clear
		* YAFEI: same, paste
		rename (v20 v22 v24 v26 v28) (psych locom vital cogni sensor)
		save elsa_fscores, replace
		
	
	* Partial info, all waves, WLSMV, MALES  --- gender

		import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\elsa_fscores_female0.csv", clear delim(" ", collapse) // YAFEI: these are the factor scores generated in Mplus
		keep v20
		* YAFEI: browse the dataset and copy them
		use elsa_for_fscores_female0, clear
		* YAFEI: browse the dataset and paste them
		rename v20 g
		save elsa_fscores_female0, replace

		import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\elsa_fscores_female0_cf.csv", clear delim(" ", collapse)
		keep v20 v22 v24 v26 v28
		* YAFEI: same, copy
		use elsa_fscores_female0, clear
		* YAFEI: same, paste
		rename (v20 v22 v24 v26 v28) (psych locom vital cogni sensor)
		save elsa_fscores_female0, replace
		
		
	* Partial info, all waves, WLSMV, FEMALES

		import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\elsa_fscores_female1.csv", clear delim(" ", collapse) // YAFEI: these are the factor scores generated in Mplus
		keep v20
		* YAFEI: browse the dataset and copy them
		use elsa_for_fscores_female1, clear
		* YAFEI: browse the dataset and paste them
		rename v20 g
		save elsa_fscores_female1, replace

		import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\elsa_fscores_female1_cf.csv", clear delim(" ", collapse)
		keep v20 v22 v24 v26 v28
		* YAFEI: same, copy
		use elsa_fscores_female1, clear
		* YAFEI: same, paste
		rename (v20 v22 v24 v26 v28) (psych locom vital cogni sensor)
		save elsa_fscores_female1, replace
		
	* Combined datasets
	
		append using elsa_fscores_female0
		sort ID wave
		save elsa_fscores_sex, replace
			
		

		
		
		
		
		
	
	
	
	
	
	
	
	
	
	
	
		
		
**# CHARLS WLSMV factor scores 


	* Partial info, w123, WLSMV ---overall
	import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\charls_fscores.csv", clear delim(" ", collapse) // use my own path
	
		//import delimited "charls_fscores.csv", clear delim(" ", collapse)
		keep v20
		* YAFEI: same, copy
		use charls_for_fscores, clear
		* YAFEI: same, paste
		rename v20 g
		save charls_fscores, replace

	import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\charls_fscores_cf.csv", clear delim(" ", collapse) // use my own path
	
		//import delimited "charls_fscores_cf.csv", clear delim(" ", collapse)
		keep v20 v22 v24 v26 v28
		* YAFEI: same, copy
		use charls_fscores, clear
		* YAFEI: same, paste
		rename (v20 v22 v24 v26 v28) (psych locom vital cogni sensor)
		save charls_fscores, replace




**by gender
	* Partial info, w123, WLSMV, MALES ---gender

		import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\charls_fscores_female0.csv", clear delim(" ", collapse)
		keep v20
		* YAFEI: same, copy
		use charls_for_fscores_female0, clear
		* YAFEI: same, paste
		rename v20 g
		save charls_fscores_female0, replace

		
		import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\charls_fscores_female0_cf.csv", clear delim(" ", collapse)
		keep v20 v22 v24 v26 v28
		* YAFEI: same, copy
		use charls_fscores_female0, clear
		* YAFEI: same, paste
		rename (v20 v22 v24 v26 v28) (psych locom vital cogni sensor)
		save charls_fscores_female0, replace

	* Partial info, w123, WLSMV, FEMALES

		import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\charls_fscores_female1.csv", clear delim(" ", collapse)
		keep v20
		* YAFEI: same, copy
		use charls_for_fscores_female1, clear
		* YAFEI: same, paste
		rename v20 g
		save charls_fscores_female1, replace

		
		import delimited "D:\OneDrive - UNSW\CEPAR\Funding\Longitudinal IC\Data & Code\IC MPlus code weighted final\charls_fscores_female1_cf.csv", clear delim(" ", collapse)
		keep v20 v22 v24 v26 v28
		* YAFEI: same, copy
		use charls_fscores_female1, clear
		* YAFEI: same, paste
		rename (v20 v22 v24 v26 v28) (psych locom vital cogni sensor)
		save charls_fscores_female1, replace	
		
		
	* Combined datasets
	
		append using charls_fscores_female0
		sort ID wave
		save charls_fscores_sex, replace
		
		
		



		



