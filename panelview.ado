/*
Feb 14 2023
Hongyu Mou, Yiqing Xu
*/

capture program drop panelview

program define panelview
	version 15.1
	syntax varlist(min = 1 numeric) [if] [in] , ///
	I(varname) T(varname numeric)	///
	TYPE(string)					///
	[								///
	continuoustreat					///
	discreteoutcome					///
	bytiming						///
	ignoretreat						///
	ignoreY							///
	MYCOLor(string)					///
	PREpost							///
	xlabdist(integer 1)				/// 
	ylabdist(integer 1)				///
	bygroup							///
	style(string)					///
	byunit							///
	theme(string)					///
	lwd(string)						///
	leavegap						///
	bygroupside						///
	displayall						///
	bycohort						///
	collapsehistory					///
	*								///
	]
	
	//check if i and t uniquely identify the obs:
	isid `i' `t'


	//check needed packages

	cap which colorpalette.ado
	if _rc {
		*di as error "colorpalette.ado required: {stata ssc install palettes, replace}"
		di as error "colorpalette.ado required: {stata search gr0075} and click to install, and please make sure the other required packages (labutil, sencode, grc1leg) are installed"
		exit 199
	}
	
	cap which labmask.ado
	if _rc {
		di as error "labmask.ado required: {stata ssc install labutil, replace}, and please make sure the other required packages (gr0075, sencode, grc1leg) are installed"
		exit 199
	}

	cap which sencode.ado
	if _rc {
		di as error "sencode.ado required: {stata ssc install sencode, replace}, and please make sure the other required packages (labutil, gr0075, grc1leg) are installed"
		exit 199
	}

	cap which grc1leg.ado
	if _rc {
		di as error "grc1leg.ado required: {stata search grc1leg} and click to install, and please make sure the other required packages (labutil, gr0075, sencode) are installed"
		exit 199
	}
	

	//check for bad option combinations:

	if "`continuoustreat'" != "" {
		if "`bytiming'" != "" { 
			di as err "options continuoustreat and bytiming may not be combined"
			exit 198
		}
	}

	if "`continuoustreat'" != "" {
		if "`ignoretreat'" != "" {
			di as err ///
			"options continuoustreat and ignoretreat may not be combined"
			exit 198
		}
	}

	if "`continuoustreat'" != "" {
		if ("`type'" == "miss" | "`type'" == "missing") {
			di as err ///
			"options continuoustreat and type(missing) may not be combined"
			exit 198
		}
	}	

	if ("`bygroup'" != "") { 
		if ("`prepost'" == "") { 
			*di as err ///
			"options bygroup and prepost should be combined"
			*exit 198
			loc prepost 1
		}
	}

	if ("`bygroupside'" != "") { 
		if ("`bygroup'" == "") { 
			loc bygroup 1
		}
		if ("`prepost'" == "") { 
			loc prepost 1
		}
	}


	if ("`type'" == "outcome") {
		if ("`bytiming'" != "") {
			di as err ///
			"options type(outcome) and bytiming may not be combined"
			exit 198
		}
	}

	if ("`type'" != "outcome") {
		if ("`bygroup'" != "") {
			di as err ///
			"option bygroup should be combined with type(outcome)"
			exit 198
		}
	}

	if ("`type'" != "treat") {
		if ("`collapsehistory'" != "") {
			di as err ///
			"option collapsehistory should be combined with type(treat)"
			exit 198
		}
	}

	if ("`leavegap'" != "") {
		if ("`collapsehistory'" != "") {
			di as err ///
			"options collapsehistory and leavegap should not be combined"
			exit 198
		}
	}

	if ("`type'" != "outcome") {
		if ("`bycohort'" != "") {
			di as err ///
			"option bycohort should be combined with option type(outcome)"
			exit 198
		}
	}

	if ("`type'" == "outcome" | "`type'" == "bivar") {
		if ("`leavegap'" != "") {
			di as err ///
			"option leavegap should be combined with type(treat) or type(missing)"
			exit 198
		}
	}

	if ("`type'" != "treat" & "`type'" != "miss" & "`type'" != "missing") {
		if ("`ignoreY'" != "") {
			di as err ///
			"option ignoreY should be combined with type(treat) or type(missing)"
			exit 198
		}
	}

	if ("`ignoretreat'" != "") {
		if ("`ignoreY'" != "") {
			di as err ///
			"option ignoreY should not be combined with ignoretreat"
			exit 198
		}
	}

	if ("`ignoretreat'" != "") {
		if ("`collapsehistory'" != "") {
			di as err ///
			"option collapsehistory should not be combined with ignoretreat"
			exit 198
		}
	}

	if ("`ignoretreat'" != "") {
		if ("`type'" == "miss" | "`type'" == "missing") {
			di as err ///
			"option type(missing) should not be combined with ignoretreat"
			exit 198
		}
	}

	if ("`leavegap'" != "") {
		if ("`prepost'" != "") {
			di as err ///
			"option leavegap is not recommended to be combined with prepost"
			exit 198
		}
	}

	

	if ("`bycohort'" != "") {
	loc leavegap 1
	}



    set trace off

	//check if "type" is specified correctly:
	if ("`type'" != "miss" & "`type'" != "missing" & "`type'" != "treat" & "`type'" != "outcome" & "`type'" != "bivar" &"`type'" != "bivariate") {
				di as err ///
				"option type can only be one of the following: treat, outcome, bivariate (bivar), and missing (miss)"
				exit 198
			}

	preserve 
	tempfile backup
	

	qui keep `varlist' `i' `t' //only keep using variables, i.e. include covariates
	
	qui ds `varlist'
	tempvar numvar
	cap gen `numvar' = `: word count `r(varlist)''
/*
	if ("`ignoretreat'" != "" | "`type'" == "miss" | "`type'" == "missing") {
		if `numvar' > 1 {
			di "All variables other than the first is omitted"
		}
	}
*/
	if `numvar' == 1 {
		if ("`ignoretreat'" == "" & "`type'" != "miss" & "`type'" != "missing" & "`type'" != "treat" & "`type'" != "outcome") {
				di as err "should combine with option ignoretreat, type(missing), type(treat) , or type(outcome) when varlist has only one variable" 
				exit 198
		}
		else if ("`type'" == "miss" | "`type'" == "missing") {
			tokenize `varlist'
			loc outcome `1'
			loc treat `1'
		} 
		else if ("`type'" == "treat") {
			tokenize `varlist'
			loc treat `1'
		}
		else { //"`type'" == "outcome"
			tokenize `varlist'
			loc outcome `1'
			loc ignoretreat 1
		}
	}
	else if  `numvar' == 2 {
		if ("`ignoreY'" != "") {
			tokenize `varlist'
			loc treat `1'
		}
		else {
			if ("`ignoretreat'" != ""|"`type'" == "miss" | "`type'" == "missing") {
				tokenize `varlist'
				loc outcome `1'
				loc treat `1'
				*loc covariates `2' 
				*drop if mi(`covariates')
				} 
				else {
				tokenize `varlist'
				loc outcome `1'
				loc treat `2'
			}
		}
	} 
	else { //`numvar' >= 3:
	if ("`ignoreY'" != "") {
			tokenize `varlist'
			loc treat `1'
		}
		else {
		if ("`ignoretreat'" != ""|"`type'" == "miss" | "`type'" == "missing") { 
			tokenize `varlist'
			loc outcome `1'
		} 
		else { 
			tokenize `varlist'
			loc outcome `1'
			loc treat `2'
		}
	}
	}

qui save `backup',replace

if ("`type'" == "treat" | "`type'" == "miss" | "`type'" == "missing") {
		tempfile backup_misstable

		marksample touse 
		
		//drop missing from controls sss
		tempvar countmissvar minrowmiss
		qui replace `touse' = . if `touse' == 0
		qui egen `countmissvar' = rowmiss(`touse')
		qui bysort `i': egen `minrowmiss' = min(`countmissvar')
		*cap drop if `minrowmiss' != 0 //table right, figure wrong sss

		//cap drop if `touse' == 0 //figure right, table wrong

		// misschk `varlist', extmiss // search misschk; install spost9_ado
		// strip off string variables	

		tempvar varlist1

		loc varlist1 `varlist'

		parse "`varlist1'", parse(" ")
		local vars
		while "`1'" != ""  { // loop through variables
			capture confirm numeric variable `1'
			if _rc==0 {
				local vars "`vars' `1'"
			}
			mac shift
		}

		local varlist1 "`vars'"
		parse "`varlist1'", parse(" ")

		local nvar = 0

		di _n in g "   #  Variable        # Missing   % Missing"
		di    in g "--------------------------------------------"
		
		tempvar ifin
    	mark `ifin' `if' `in'
		quietly tab `ifin'
		local total = r(N)	
		*display `total'
		

		while "`1'" != ""  { // loop through variables
			local ++nvar
			//qui count if `1'>=. // count missing; 
			qui count if `1'>=. & `ifin' // count missing; 
			* create binary variables indicating if observation is missing
			if "`dummy'"~="" {
				if "`replace'"=="replace" {
					capture drop `gennm'`1'
				}
				//quietly gen `gennm'`1' = (`1'>=.) // 
				quietly gen `gennm'`1' = (`1'>=.) if `ifin' // 
					label var `gennm'`1' "Missing value for `1'?"
					label val `gennm'`1' lmisschk
			}
			* list # and percent missing
			di in y %3.0f "   `nvar' " _col(7) "`1'" ///
				_col(23) %7.0f r(N) _col(36) %6.1f 100*r(N)/`total'
			mac shift
		} // loop through list of variables


		parse "`varlist1'", parse(" ")
		

	//  loop through all variables and count missing

    tempvar ismissn ismissw missw missn
    quietly gen `missn' = 0 if `ifin'
    label var `missn' "Missing for how many variables?"
    quietly gen str1 `missw' = "" if `ifin'
    label var `missw' "Missing for which variables?"

    local nvar = 0
    //local i = 0
    local ext "a b c d e f g h i j k l m n o p q r s t u v w x y z" // 1.1.0
    while "`1'" != ""  {
        local ++nvar
        * ones has only one's digit of variable number
        local ones = mod(`nvar',10)

        * drop tempvars from last loop
        capture drop `ismissn' `ismissw'

        * 1 if mssing, else 0; . if not in if in
        capture quietly gen `ismissn' = (`1'>=.) if `ifin' // changed == 1.1.0

        * string with indicator of missing status. Space if no missing;
        * then if missing, either . or digit number.
        capture quietly gen str1 `ismissw' = "`notmissstr'"

            quietly replace `ismissw' = "." if `1'==. & `ifin'
            foreach ltr in `ext' {
                quietly replace `ismissw' = "`ltr'" if `1'==.`ltr' & `ifin'
            }

        * add blank every 5th variable
        if mod(`nvar'-1,5) == 0 {
            quietly replace `missw' = `missw' + " "
        }

        * build string with pattern of missing data
        quietly replace `missw' = `missw' + `ismissw'
        * count total number of missing for given case
        quietly replace `missn' = `missn' + `ismissn'
        mac shift
    }
    capture drop `ismissn' `ismissw'

//  List results

    * patterns of missing data
    *tab `missw' if `ifin', `nosort'

    * number missing for given observations
    tab `missn' if `ifin'
	qui save `backup_misstable', replace
}

	qui use `backup', clear

	marksample touse 

//drop missing from controls
	if "`leavegap'" == "" {
	cap drop if `touse' == 0
	}
	else if "`leavegap'" != "" { 
		tempvar countmissvar minrowmiss
		qui replace `touse' = . if `touse' == 0
		qui egen `countmissvar' = rowmiss(`touse')
		qui bysort `i': egen `minrowmiss' = min(`countmissvar') 
		cap drop if `minrowmiss' != 0
	}


	quietly count if `touse'
	if r(N) == 0 {
		error 2000
	}


	local ids `i'
	local tunit `t'

	//limit the unit number:
	bysort `i': gen nvals = (_n == 1)
	qui count if nvals

	*di "`r(N)'" 
	if ("`bycohort'" == "" ) {
	if (r(N) > 500 & "`displayall'" == "") {
		di "If the number of units is more than 500, we randomly select 500 units to present. You can use displayall option to show all units"
		tempfile holding
		qui save `holding'

		qui keep `i'
		qui duplicates drop

		set seed 1234
		qui sample 500, count

		qui merge 1:m `i' using `holding', assert(match using) keep(match) nogenerate
	}
	}

	
	
	tempvar nids
	cap label list `ids' 
	if "`r(k)'" != "" { //numeric units indicator with labels:
		qui egen `nids' = group(`ids') 
		*label list `ids'
	}
	else { //numeric units indicator without labels or string variable:
	capture confirm numeric variable `ids'
	if !_rc { //numeric units indicator without labels:
		tempvar labelids
		qui tostring `ids', gen(`labelids')
		labmask `ids', val(`labelids') 
		*label list `ids'

		qui egen `nids' = group(`ids')
	}
	else { //string variable:
		tempvar i_numeric labeli
		qui encode `ids',gen(`i_numeric')
		*label list `i_numeric'
		drop `ids'
		rename `i_numeric' `ids'
	
		qui egen `nids' = group(`ids')	
	}
	}
	
	qui levelsof `nids' if `touse'
	loc numids = r(r)


	

	// ignore treatment:
	tempvar gcontrol

	capture confirm variable `treat'
	if !_rc {
	qui levelsof `treat' if `touse', loc (levstreat)
	loc numlevstreat = r(r) 
	if ("`bycohort'" != "" & `numlevstreat' != 2) {
		di as err "option bycohort works only with dummy treatment variable"
		exit 198
	}
	}

	
	capture assert `treat' == 0 | `treat' == 1
	if ("`bycohort'" != "" & _rc) {
		di as err "option bycohort works only with dummy treatment variable"
		exit 198
	}

	if ("`ignoretreat'" != "" | "`type'" == "miss" | "`type'" == "missing") { 
			cap gen `gcontrol' = 1 
		}
	*if ("`continuoustreat'" != "" & "`type'" == "outcome") { 
	else if (`numlevstreat' > 2 & "`type'" == "outcome") { 
			cap gen `gcontrol' = 1 
	}
	else {
    		*if ("`ignoretreat'" != "" | "`type'" == "miss" | "`type'" == "missing") { 
			*cap gen `gcontrol' = 1 
			*} 
			*else {			
			if (`numlevstreat' == 2) {
			tempvar max_treat
			cap bys `nids': egen `max_treat' = max(`treat') 
			cap gen `gcontrol' = 1
			qui replace `gcontrol' = 0 if `max_treat' >= 1
			}
			else {
				if (`numlevstreat' == 1) {
					di "Only one treatment level"
					cap gen `gcontrol' = 1 
				}
				else { 
					if  ("`prepost'" != "") { 
					di as err "with more than two treatment levels, option prepost may not be combined" 
					exit 198
					}
					else {
						if (`numlevstreat' >= 5 & "`continuoustreat'" == "") {
							di "Too many treatment levels; treat as continuous."
							local continuoustreat `"continuoustreat"'
							cap gen `gcontrol' = 1
						}
						if (`numlevstreat' <= 4 & "`continuoustreat'" != "") { 
							di "Too few treatment levels; consider drop the continuoustreat option."
						}
					}
				}
			}
			*}
		}	

	sort `ids' `tunit' 


	//sort by time of first treatment
	if "`bytiming'" != "" { 
		tempvar bytime 
		tempvar min_bytime
		tempvar num_trtime
		cap gen `bytime' = .
		cap replace `bytime' = `tunit' if `treat' > = 1
		cap bys `nids': egen `min_bytime' = min(`bytime') 
		cap bys `nids': egen `num_trtime' = count(`bytime')
		drop `bytime'

		tempvar nids2
		tempvar nids3
		decode `ids', generate(`nids2')
		sencode `nids2', generate(`nids3') gsort(`min_bytime'  -`num_trtime'  `ids') 
		*tab `min_bytime',m // missing: controls
		*tab `num_trtime',m // 0: controls
		*tab `ids',m
	}
	else {
		tempvar nids2 nidslab
		decode `ids', generate(`nids2')
		sencode `nids2', generate(`nidslab')
	}		
	
	qui levelsof `nids' if `touse' , loc (levsnids) 
	
	/*
	tempvar newtime
	egen `newtime' = group(`tunit')
	*qui sum `newtime'
	*loc maxmintime = r(max) - r(min)
	*qui levelsof `newtime'
	*loc numsoftime = r(r)
	*loc plotcoef = `maxmintime' / (`numsoftime' -1) 
	

	tempvar labeltime
	qui tostring `tunit', gen(`labeltime')
	labmask `newtime', val(`labeltime')
	*/

	tempvar maxtime mintime timegap inttimegap timegap2 mintimegap id_oneobs 
		cap bysort `nids': gen `maxtime' = `tunit'[_N]
		qui sum `maxtime'
		loc maxmaxtime = r(max)
		cap bysort `nids': egen `mintime' = min(`tunit')
		qui sum `mintime'
		loc minmintime = r(min)
		loc maxmaxminmingap = `maxmaxtime' - `minmintime'
	

		qui levelsof `tunit'
		loc numtime = r(r)
		cap gen `timegap' = (`maxmaxminmingap')/(`numtime'-1) //possible common difference
		qui gen `inttimegap' = int(`timegap')

		cap bysort `nids': gen `timegap2' = `tunit'[_n]-`tunit'[_n-1]
		cap bysort `nids': egen `mintimegap' = min(`timegap2')

		if "`leavegap'" != "" {
		if ( `timegap' != `mintimegap' | `inttimegap' != `timegap') { //not arithmetic sequence
		tempvar differencetime
		cap bysort `nids': gen `differencetime' = `tunit'[_n] - `tunit'[_n-1]
		qui sum `differencetime'
		loc min_differencetime = r(min)
		loc max_differencetime = r(max)
		loc divide_differencetime = `max_differencetime' / `min_differencetime'

		if (`min_differencetime' != `max_differencetime' & `min_differencetime' != 1 & `divide_differencetime' == int(`divide_differencetime')) { // 两两difference相除是整数倍
			qui save `backup', replace
			qui keep `nids'
			qui duplicates drop `nids', force
			qui expand `numtime'
			cap bysort `nids': gen `tunit' = `minmintime' + (_n-1) * `min_differencetime'
			qui merge 1:1 `nids' `tunit' using `backup'
			qui drop _merge
		}
		else { //commmon difference = 1 
			qui save `backup', replace
			qui keep `nids'
			qui duplicates drop `nids', force
			qui expand `maxmaxminmingap'
			cap bysort `nids': gen `tunit' = `minmintime' + _n
			qui merge 1:1 `nids' `tunit' using `backup'
			qui drop _merge
		}
		}
		}
	
	
	if  "`leavegap'" == "" {
		loc alltimegap = `maxmaxminmingap'/(`numtime'-1)
		if (`timegap' != `mintimegap' | `inttimegap' != `timegap') {
			di "Time is not evenly distributed (possibly due to missing data). "
		}
		else {
			tempvar tunit_merge
			qui gen `tunit_merge' = `tunit'
			qui save `backup', replace
			qui keep `nids'
			qui duplicates drop `nids', force
			qui expand `numtime'

			cap bysort `nids': gen `tunit_merge' = `minmintime' + (_n-1) * `alltimegap'
			qui merge 1:1 `nids' `tunit_merge' using `backup'
			tempvar difftime
			qui gen `difftime' = (`tunit_merge' == `tunit')
			qui sum `difftime'
			loc min_difftime = r(min)
			loc max_difftime = r(max)
			*if  (`max_difftime' != `min_difftime') { 
				*if (`alltimegap' != 1) {
				*di "Time is not evenly distributed (possibly due to missing data). "
				*}
			*}
			qui drop `tunit_merge'
			qui drop _merge
		}
	}


	tempvar newtime
	qui egen `newtime' = group(`tunit')

	tempvar labeltime
	qui tostring `tunit', gen(`labeltime')
	labmask `newtime', val(`labeltime')




	//indicate the last period as a different colored dot in outcome plot if only treated in the last period:
		tempvar lastchangedot maxtime2 dtreat islastchangedot
		cap bysort `nids': gen `maxtime2' = `tunit'[_N-1]
		cap gen `lastchangedot' = 0
		cap bysort `nids': replace `lastchangedot' = 1 if `treat' == 1 & `tunit' == `maxtime'
		cap bysort `nids': gen `dtreat' = `treat'[_N] - `treat'[_N-1] if `lastchangedot' == 1
		cap bysort `nids': replace `lastchangedot' = 0 if `dtreat' == 0

		cap count if `lastchangedot' == 1
		loc islastchangedot = (r(N) != 0)


/*
	//paint the period right before treatment:
	if ("`ignoretreat'" == "" & "`type'" != "miss" & "`type'" != "missing") {
	if ("`type'" == "outcome" & "`discreteoutcome'" == "" ) { 
			cap destring `labeltime', replace
			tempvar L1_labeltime L1_time
			cap bys `nids': gen `L1_labeltime' = `labeltime'[_n-1] if `treat' >= 1
			cap bys `nids': egen `L1_time' = min(`L1_labeltime')
			cap replace `treat' = 1 if `labeltime' == `L1_time'		
		}
	}
*/

	tempvar plotvalue varmiss
	qui egen `varmiss' = rowmiss(`varlist')

	if ("`continuoustreat'" != "" & "`type'" == "outcome") {
		cap gen `plotvalue' = 0
		}
		else {
			if ("`ignoretreat'" != ""|"`type'" == "miss" | "`type'" == "missing") { 
				 if "`leavegap'" != "" {
					cap gen `plotvalue' = 0 if `varmiss' == 0
				 }
				 else {
					cap gen `plotvalue' = 0
				 }
			}
			else { 
				if ("`type'" == "outcome" & `numlevstreat' > 2) {
				cap gen `plotvalue' = 0
				di "The number of treatment level is > 2; we ignore the treatment status."
				}
				else {	//"`type'" == "treat"
					if "`leavegap'" != "" {
						cap gen `plotvalue' = `treat' if `varmiss' == 0
					}
					else {
						cap gen `plotvalue' = `treat'
					}
				//remapping continuous treatment to 5 levels to fit color palettes levels:
				if "`continuoustreat'" != "" {
					qui sum `plotvalue' 
					loc maxminplotvalue = r(max) - r(min)
						qui replace `plotvalue' = int((`plotvalue' - r(min)) * 4 / `maxminplotvalue' ) 
				}
				}
			}
		} 
		

if ("`type'" == "miss" | "`type'" == "missing") { 
	if ("`ignoretreat'" == "") {
		tempvar ignoretreat
		cap gen `ignoretreat' = 1 
	}
}


	qui levelsof `plotvalue' if `touse', loc (levsplot) 
	loc numlevsplot = r(r) 	

	if ("`ignoretreat'" == "") { 
	if ("`continuoustreat'" == "" | "`type'" != "outcome") {
		if `numlevstreat' == 2 {
		if "`prepost'" != "" {
		foreach x of loc levsplot {
			qui replace `plotvalue' = `x' + 1 if `treat' == `x' & `treat' != 0
		} 		
		qui replace `plotvalue' = 1 if `treat' == 0 & `gcontrol' == 0 //treated(pre)
		//levsplot: 0 <- control; 1 <- pre; 2 <- post
		qui levelsof `plotvalue' if `touse', loc (levsplot)
		loc numlevsplot = r(r)
		}
		}
		else if `numlevstreat' > 2 {
			if ("`type'" == "treat") {
				tempvar altlevsplot
				qui egen `altlevsplot' = group(`plotvalue') if `touse' 
				cap replace `altlevsplot' =  `altlevsplot' - 1
				qui levelsof `altlevsplot' if `touse', loc (levsplot)
				loc numlevsplot = r(r)
				qui drop `altlevsplot'
			}
		}
	}
	}



	//deciding color
	if ("`type'" == "outcome") {
		colorpalette "198 219 239" "251 162 127" "red", n(`numlevsplot') nograph
	}
	else {
		colorpalette "198 219 239" "ebblue" "navy" "30 45 83" "black", n(`numlevsplot') nograph
	}

	if (`"`mycolor'"' != "") {
		colorpalette `mycolor' , n(`numlevsplot') nograph
	}

	if "`theme'" == "bw" {
		colorpalette Greys , n(`numlevsplot') nograph
	}

	if (`"`mycolor'"' != "Greys" & `"`mycolor'"' != "") { 
		if ( "`theme'" == "bw") {
			di as err " If mycolor is not Greys, mycolor cannot combine with option theme(bw)"
			exit 198
		}
	}
	


	qui return list
	tokenize `levsplot' 
	loc trpreortr `2'
	tempvar nopre
	if "`trpreortr'" != "" {
		cap gen `nopre' = (`trpreortr' == 2) 
	}
	else {
		cap gen `nopre' = 0
	}




	if `nopre' != 1 { 
		foreach w of loc levsplot {
		loc uu = `w' + 1 //012 -> 123
		loc col`w' = r(p`uu')
		// colorpalette stores #th color in r(p#) 
		}
	}
	else { 
		foreach w of loc levsplot {
			if `w' == 0 {
				loc uu = `w' + 1
				loc col`w' = r(p`uu')
			}
			else if `w' == 2 {
				loc col`w' = r(p`w')
			}
		}
	}







		if (`"`xlabel'"'=="") {
			qui sum `newtime', mean
			local xlabel `"xlabel(`r(min)'(`xlabdist')`r(max)', angle(90) nogrid labsize(tiny) valuelabel noticks)"'
		}

		if `"`bytiming'"' != "" { // With bytiming:		
		if (`"`ylabel'"'=="") {
			qui sum `nids3', mean
			local ylabel `"ylabel(`r(min)'(`ylabdist')`r(max)', angle(0) nogrid labsize(tiny) valuelabel noticks)"'
		}
		}
		else { // Without bytiming:
		if (`"`ylabel'"'=="") {
			qui sum `nids', mean
			local ylabel `"ylabel(`r(min)'(`ylabdist')`r(max)', angle(0) nogrid labsize(tiny) valuelabel noticks)"'
		}
		}
	
		tempvar bgplotvalue labplotvalue
		qui bysort `nids': egen `bgplotvalue' = min(`plotvalue')
		qui levelsof `bgplotvalue' if `touse', loc (bglevsplot)

		label define `labplotvalue' 0 "Always Under Control" 1 "Treatment Status Changed" 2 "Always Treated"
		label val `bgplotvalue' `labplotvalue'



	if ("`type'" == "outcome") { 
	//1. ploting outcome: type(outcome):
	if ("`discreteoutcome'" == "" ) { //continuous outcome
		//1.1. plotting lines of continuous outcome:

			qui tsset `nids' `tunit'
			qui drop if `tunit'==.
			tsfill, full

			tempvar stagger0 stagger
			qui by `nids': gen `stagger0' =1 if `treat'[_n]-`treat'[_n+1]==0
			qui by `nids': replace `stagger0' =0 if `treat'[_n]-`treat'[_n+1]==1
			qui egen `stagger' = min(`stagger0')
			loc staggersaclar=`stagger'
			if (`staggersaclar' == 0) { //treatment reversal:
				if ("`continuoustreat'" == "" & "`ignoretreat'" == "" & `numlevsplot'!=1){
					di as err "continuous outcome lines cannot work with treatment reversals in Stata, please try the R version to make it"
					exit 198
				}
			}


		di "now display lines of continuous outcome"
		loc lines1


		if ("`bycohort'" == "" ) {
		foreach w of loc levsplot {
			foreach x of loc levsnids {
					if (`"`prepost'"' != "" & `w' == 1 ) { 
					//with prepost: `w' == 1: treated(pre)
					if `islastchangedot' == 0 {
						loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse', lcolor("`col`w''")"'
					}
					else{
						loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse', lcolor("`col`w''") || scatter `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse' & `lastchangedot' == 1, mcolor("`col`3''") msize(vsmall)"'
					}
					} 
					else if (`"`prepost'"' == "" & `w' == 0 ) { 
					//without prepost: `w' == 0: treated(pre)
					if `islastchangedot' == 0 {
						loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse' , lcolor("`col`w''")"'
						}
					else{
						loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse', lcolor("`col`w''") || scatter `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse' & `lastchangedot' == 1, mcolor("`col`2''") msize(vsmall)"'
					}
					}
				loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `plotvalue' == `w' & `touse' , lcolor("`col`w''")"' 
			}
		}
		

			if ("`continuoustreat'" != "") {
			tw `lines1' legend(region(lstyle(none) fcolor(none)) order(1) label(1 "Observed") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
			}
			else { // not continuoustreat:
				if ("`ignoretreat'" != "" | `numlevsplot'==1) { // ignore treatment:
				tw `lines1' legend(region(lstyle(none) fcolor(none)) order(1) label(1 "Observed") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
				}
				else {
					if `numlevstreat' > 2  { 
						tw `lines1' legend(region(lstyle(none) fcolor(none)) order(1) label(1 "Observed") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
					}
					else { // not ignore treatment:
						if ("`bygroup'" != "" ) { //with bygroup:
						if `islastchangedot' == 0 {
								tempvar allunits 								
								qui egen `allunits' = max(`nids') 
								local largestlegend = 3*`allunits' + 1
								local midlegend = 2*`allunits'
								if ("`bygroupside'" == "" ) {
								twoway `lines1' by(`bgplotvalue', note("") cols(1)) legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
								}
								else if ("`bygroupside'" != "" ) {
								twoway `lines1' by(`bgplotvalue', note("") rows(1)) legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
								}
						}
						else {
								tempvar allunits 								
								qui egen `allunits' = max(`nids') 
								local largestlegend = `allunits' + 2
								local midlegend = `allunits' + 1
								if ("`bygroupside'" == "" ) {
								twoway `lines1' by(`bgplotvalue', note("") cols(1)) legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
								}
								else if ("`bygroupside'" != "" ) {
								twoway `lines1' by(`bgplotvalue', note("") rows(1)) legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
								}
							}
						}
						else{ //without bygroup: prepost=on:
						if (`"`prepost'"' != "") {
							if `islastchangedot' == 0 {
								tempvar allunits 								
								qui egen `allunits' = max(`nids') 
								local largestlegend = 3*`allunits' + 1
								local midlegend = 2*`allunits'
								tw `lines1'  legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
							}
							else {
								tempvar allunits 								
								qui egen `allunits' = max(`nids') 
								local largestlegend = `allunits' + 2
								local midlegend = `allunits' + 1
								tw `lines1'  legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
							}
						}
							else { //prepost = off:
								if `islastchangedot' == 0 {
									tempvar allunits								
									qui egen `allunits' = max(`nids') 
									local largestlegend=3*`allunits'
									tw `lines1' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control"  `largestlegend' "Treated") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
								}
								else {
									tw `lines1' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control"  2 "Treated") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'

								}
							}
						}
					}
				}
			}
		}
		else if ("`bycohort'" != "" ) {
			* impute missing:
			** expand to balanced panel:
			qui tsset `nids' `tunit'
			tsfill, full

			tempvar stagger0 stagger
			qui by `nids': gen `stagger0' =1 if `treat'[_n]-`treat'[_n+1]==0
			qui by `nids': replace `stagger0' =0 if `treat'[_n]-`treat'[_n+1]==1
			qui egen `stagger' = min(`stagger0')
			loc staggersaclar=`stagger'

			if `staggersaclar' == 1 { //staggered adoption: only allow dummy treatment
				qui bysort `nids' (`tunit'): replace `treat' = `treat'[_n-1] if `treat' == .

				gsort `nids' -`tunit'
				qui bysort `nids': replace `treat' = `treat'[_n-1] if `treat' == .
				sort `nids' `tunit'

				*qui bysort `nids' (`tunit'): replace `treat' = 1 if `treat' == . & `treat'[_n-1] == 1 
				
				*gsort `nids' -`tunit'
				*qui bysort `nids': replace `treat' = 0 if `treat' == . & `treat'[_n-1] == 0 
				*sort `nids' `tunit'
			}
			else if `staggersaclar' == 0 { //treatment reversal:
				di as err "option bycohort works only with staggered adoption"
				exit 198
			}



			* graph:
			qui tostring `treat', replace
			tempvar history	numhistorylevels
			qui bysort `nids' (`tunit'): generate `history' = `treat'[1]
			qui by `nids': replace `history' = `history'[_n-1] + `treat' if _n > 1
			qui by `nids': replace `history' = `history'[_N]
			qui by `history', sort: gen `numhistorylevels' = _n == 1 

			*tab `history', m
			sort `nids' `tunit'
			*list in 1/180

			qui count if `numhistorylevels' 
			display "Number of unique treatment history: `r(N)'"
			

			if (`r(N)' > 20) {   
				di as error "Option bycohort would not work if the number of unique treatment history is more than 20."
				exit 198
			}
			else { // `r(N)' <= 20
			tempvar outcomehistorymean historygroup
			qui egen `outcomehistorymean' = mean(`outcome'), by(`history' `tunit')
			qui replace `outcome' = `outcomehistorymean'
			qui egen `historygroup' = group(`history')
			qui levelsof `historygroup' if `touse', loc(historylevels)
			tempfile cohortlinehistory
			qui keep `outcome' `historygroup' `tunit' `gcontrol' `lastchangedot' `plotvalue' `touse'
			qui duplicates drop
			qui sum `tunit'
			qui replace `lastchangedot' = 0 if `tunit' != r(max)
			qui save `cohortlinehistory'

			foreach w of loc levsplot { //levsplot: 0 <- control; 1 <- pre; 2 <- post
				foreach x of loc historylevels {
					if (`"`prepost'"' != "" & `w' == 1 ) {
					//with prepost: `w' == 1: treated(pre)
					if `islastchangedot' == 0 {
						loc lines1 `" `lines1' || line `outcome' `tunit' if `historygroup' == `x' & `gcontrol' == 0 & `touse', lcolor("`col`w''")"'
					}
					else{
						loc lines1 `" `lines1' || line `outcome' `tunit' if `historygroup' == `x' & `gcontrol' == 0 & `touse', lcolor("`col`w''") || scatter `outcome' `tunit' if `historygroup' == `x' & `gcontrol' == 0 & `touse' & `lastchangedot' == 1, mcolor("`col`3''") msize(vsmall)"'
					}
					} 
					else if (`"`prepost'"' == "" & `w' == 0 ) { 
					//without prepost: `w' == 0: treated(pre)
					if `islastchangedot' == 0 {
						loc lines1 `" `lines1' || line `outcome' `tunit' if `historygroup' == `x' & `gcontrol' == 0 & `touse', lcolor("`col`w''")"'
						}
					else {
						loc lines1 `" `lines1' || line `outcome' `tunit' if `historygroup' == `x' & `gcontrol' == 0 & `touse', lcolor("`col`w''") || scatter `outcome' `tunit' if `historygroup' == `x' & `gcontrol' == 0 & `touse' & `lastchangedot' == 1, mcolor("`col`2''") msize(vsmall)"'
					}
					}
				loc lines1 `" `lines1' || line `outcome' `tunit' if `historygroup' == `x' & `plotvalue' == `w' & `touse', lcolor("`col`w''")"' 
				}
			}
			sort `tunit'
			if (`"`prepost'"' != "") { //with prepost:
				if `islastchangedot' == 0 { //no last changedot
					tempvar allunits
					qui egen `allunits' = max(`historygroup') 
					local largestlegend = 3*`allunits' + 1
					local midlegend = 2*`allunits'
					tw `lines1'  legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) ytitle("Cohort Average") title("Cohort Outcome Trajectories") `options'
				}
				else { //with last changedot
					tempvar allunits 								
					qui egen `allunits' = max(`historygroup') 
					local largestlegend = `allunits' + 2
					local midlegend = `allunits' + 1
					tw `lines1' sort legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) ytitle("Cohort Average") title("Cohort Outcome Trajectories") `options'
				}
			}
			else { //prepost = off:
				if `islastchangedot' == 0 { //no last changedot
					tempvar allunits
					qui egen `allunits' = max(`historygroup') 
					local largestlegend=3*`allunits'
					tw `lines1'  legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `largestlegend' "Treated") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) ytitle("Cohort Average") title("Cohort Outcome Trajectories") `options'
				}
				else { //with last changedot
					tw `lines1' sort legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" 2 "Treated") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) ytitle("Cohort Average") title("Cohort Outcome Trajectories") `options'
				}
			}
		}
		}
	}
		else { 
		//1.2. plotting dots of discrete outcome:
		
			//add some randomness to time units and outcome so that they can scatter around:
			* di "now display dots of discrete outcome"
			tempvar rout rtime
			cap gen `rtime' = `tunit' + runiform(-0.2, 0.2)
			cap gen `rout' = `outcome' + runiform(-0.2, 0.2)

			
			loc dot1
			
			foreach w of loc levsplot {
				loc dot1 `" `dot1' || sc `rout' `rtime' if `plotvalue' == `w' & `touse' , mcolor("`col`w''") msize(small)"'
			}
			
			if ("`continuoustreat'" != "") { 
			tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) order(1) label(1 "Observed") size(*0.8) symxsize(3) keygap(1)) ytitle("`outcome'") xtitle("`tunit'") `options'
			}
			else { 
					if ("`ignoretreat'" != "" | `numlevsplot'==1) { // ignore treatment:
					tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) order(1) label(1 "Observed") size(*0.8) symxsize(3) keygap(1)) ytitle("`outcome'") xtitle("`tunit'") `options'
					} 
					else {
					if `numlevstreat' > 2  { 
					tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) order(1) label(1 "Observed") size(*0.8) symxsize(3) keygap(1)) ytitle("`outcome'") xtitle("`tunit'") `options'
					}
					else { // not ignore treatment:
					if ("`bygroup'" != "" ) { //with bygroup:
					if ("`bygroupside'" == "" ) {
					twoway `dot1' by(`bgplotvalue', cols(1) note("")) legend(region(lstyle(none) fcolor(none)) note("") row(1) label(1 "Control") label(2 "Treated (Pre)") label(3 "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) ytitle("`outcome'") xtitle("`tunit'") `options'
					}
					else if ("`bygroupside'" != "" ) { {
					twoway `dot1' by(`bgplotvalue', rows(1) note("")) legend(region(lstyle(none) fcolor(none)) note("") row(1) label(1 "Control") label(2 "Treated (Pre)") label(3 "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) ytitle("`outcome'") xtitle("`tunit'") `options'
					}
					} 
					else{ //without bygroup:
					if (`"`prepost'"' != "") {
					tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) label(1 "Control") label(2 "Treated (Pre)") label(3 "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) ytitle("`outcome'") xtitle("`tunit'") `options'
					}
					else { //prepost=off:
					tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) label(1 "Control") label(2 "Treated") size(*0.8) symxsize(3) keygap(1)) ytitle("`outcome'") xtitle("`tunit'") `options'
					}
					}
					}
					}
					}	
			}		
		}
	
	



	else if ("`type'" == "treat" | "`type'" == "miss" | "`type'" == "missing") {
	// 2. Heatmap of treatment: type(treat):
	di "Note: White cells represent missing values/observations in data."

	if  `"`collapsehistory'"' == "" {
		if `"`bytiming'"' != "" {
		*2.1. With bytiming:		
		tempvar y0 y1
		cap gen `y1'=`nids3'+ 0.5 
		qui sum `y1'
		la val `y1' `:val lab `nids3''
		cap gen `y0'=`nids3'- 0.5 
		
		qui levelsof `plotvalue' if `touse', loc(levsplot)
		qui sum `plotvalue' if `touse', mean
		if (`r(min)' < 0) {
			tempvar add 
			cap gen `add' = 0 - `r(min)'
			cap replace `plotvalue' = `plotvalue' + `add'
			qui levelsof `plotvalue' if `touse', loc(levsplot_color)
			colorpalette "198 219 239" "107 174 214" "66 146 198" "31 120 180" "8 81 156" , n(`numlevsplot') nograph
			if (`"`mycolor'"' != "") {
				colorpalette `mycolor' , n(`numlevsplot') nograph
			}
			foreach w of loc levsplot_color {
			loc uu = `w' + 1 
			loc col`w' = r(p`uu') 
			}
			foreach w of loc levsplot_color{
				loc gcom `"`gcom'||rbar `y1' `y0' `newtime' if (`plotvalue'==`w')&(`touse'), barw(`xdist') col("`col`w''") fi(inten100) lw(none) "'
				}
		}
		else {		
		foreach w of loc levsplot{
			loc gcom `"`gcom'||rbar `y1' `y0' `newtime' if (`plotvalue'==`w')&(`touse'), barw(`xdist') col("`col`w''") fi(inten100) lw(none) "'
			}
		}
		loc sc `"sc `nids3' `newtime' if `touse', mlabpos(0) msy(i)"' 
		}
	
		
		else {
		*2.2. Without bytiming:
		tempvar y0 y1
		cap gen `y1'=`nids'+ 0.5 
		qui sum `y1'
		la val `y1' `:val lab `nidslab''
		cap gen `y0'=`nids'- 0.5 
		
		qui levelsof `plotvalue' if `touse', loc(levsplot)
		qui sum `plotvalue' if `touse', mean
		if (`r(min)' < 0) {
			tempvar add 
			cap gen `add' = 0 - `r(min)'
			cap replace `plotvalue' = `plotvalue' + `add'
			qui levelsof `plotvalue' if `touse', loc(levsplot_color)
			colorpalette "198 219 239" "107 174 214" "66 146 198" "31 120 180" "8 81 156" , n(`numlevsplot') nograph
			if (`"`mycolor'"' != "") {
				colorpalette `mycolor' , n(`numlevsplot') nograph
			}
			foreach w of loc levsplot_color {
			loc uu = `w' + 1 
			loc col`w' = r(p`uu') 
			}
			foreach w of loc levsplot_color{
				loc gcom `"`gcom'||rbar `y1' `y0' `newtime' if (`plotvalue'==`w')&(`touse'), barw(`xdist') col("`col`w''") fi(inten100) lw(none) "' 
				//100% intensity, full color. Line has zero width: it vanishes
				}
		}
		else {
			foreach w of loc levsplot{
				loc gcom `"`gcom'||rbar `y1' `y0' `newtime' if (`plotvalue'==`w')&(`touse'), barw(`xdist') col("`col`w''") fi(inten100) lw(none) "' 
				//100% intensity, full color. Line has zero width: it vanishes
				}
		}

		loc sc `"sc `nids' `newtime' if `touse', mlabpos(0) msy(i)"' 
		}

			if ("`ignoretreat'" != "" | `numlevsplot'==1) { // ignore treatment:
			local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1) label(1 "Observed") size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
			} 
			else { // not ignore treatment:
				if `nopre' == 1 {
					local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2) label(1 "Control") label(2 "Treated") size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'	
				}
				else { 
				if (`"`prepost'"' != "") {
					local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3) label(1 "Control") label(2 "Treated (Pre)") label(3 "Treated (Post)") size(*0.6) symxsize(3) keygap(1)) xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1) xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
					}
					
					else {
						if "`continuoustreat'" != "" {
						qui sum `treat'
						loc maxminplotvalue = r(max) - r(min)
						loc dismaxminplotvalue = `maxminplotvalue' / 4
						loc r_max = r(max) + `dismaxminplotvalue'
						tempvar plotvalue1
						qui egen `plotvalue1' = cut(`treat'), at(`r(min)' (`dismaxminplotvalue') `r_max')
						qui levelsof `plotvalue1' if `touse', loc (levsplot1)
						tokenize `levsplot1'
						loc contrlev1 `1'
						loc contrlev2 `2'
						loc contrlev3 `3'
						loc contrlev4 `4'
						loc contrlev5 `5'
						loc contrlev11=round(`1', 0.001)
						loc contrlev22=round(`2', 0.001)
						loc contrlev33=round(`3', 0.001)
						loc contrlev44=round(`4', 0.001)
						loc contrlev55=round(`5', 0.001)
						if `contrlev55' > `contrlev44' {
							local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3 4 5) label(1 "`contrlev11'") label(2 "`contrlev22'") label(3 "`contrlev33'") label(4 "`contrlev44'") label(5 "`contrlev55'") title("Treatment levels: ", size(*0.45)) size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
						}
						else {
							local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3 4) label(1 "`contrlev11'") label(2 "`contrlev22'") label(3 "`contrlev33'") label(4 "`contrlev44'") title("Treatment level: ", size(*0.45)) size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
						}
						}
						else {
							if `numlevstreat' > 2 {
								tokenize `levsplot'
								loc trlev1 `1'
								loc trlev2 `2'
								loc trlev3 `3'
								loc trlev4 `4' // If the number of treatment levels >= 5, need to combine with Continuoustreat
								if "`trlev4'" != ""{ //treatment levels = 4:
								local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(2) order(1 2 3 4) label(1 "Treatment level: `trlev1'") label(2 "Treatment level: `trlev2'") label(3 "Treatment level: `trlev3'") label(4 "Treatment level: `trlev4'") size(*0.55) symxsize(3) keygap(0.5) colgap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
								}
								else { //treatment levels = 3:
								local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3) label(1 "Treatment level: `trlev1'") label(2 "Treatment level: `trlev2'") label(3 "Treatment level: `trlev3'") size(*0.55) symxsize(3) keygap(0.5) colgap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
								}
							}
							else { //treatment levels = 2:
								local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2) label(1 "Control") label(2 "Treated") size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
							}
						}
					} 
				}
			}
		tw `gcom' plotr(fc(white) margin(zero)) ||`sc'  `options'
	}


	else if `"`collapsehistory'"' != "" { // with collapsehistory	
				
			qui tostring `treat', replace
			tempvar history	numhistorylevels historymember
			qui bysort `nids' (`tunit'): generate `history' = `treat'[1]
			qui by `nids': replace `history' = `history'[_n-1] + `treat' if _n > 1
			qui by `nids': replace `history' = `history'[_N]
			qui by `history', sort: gen `numhistorylevels' = _n == 1 

			qui bysort `history' `nids': gen `historymember'= _n == 1 
			qui by `history': replace `historymember' = sum(`historymember')
			qui by `history': replace `historymember' = `historymember'[_N]

			*tab `history', m
			*tab `history', m sort

			tempvar historygroup
			qui egen `historygroup' = group(`history')
			*tab `historygroup', m
			*tab `historygroup', m sort

			tempvar labelhistorymember			
			qui tostring `historymember', gen(`labelhistorymember')
			labmask `historygroup', val(`labelhistorymember')


			qui count if `numhistorylevels' 
			display "Number of unique treatment history: `r(N)'"
			
		
			tempfile cohortlinehistory
			qui keep `treat' `historygroup' `historymember' `newtime' `lastchangedot' `plotvalue' `touse' `nopre'
			qui duplicates drop
			gsort -`historymember' `historygroup' `newtime'
			*list

			qui sum `newtime'
			qui replace `lastchangedot' = 0 if `newtime' != r(max)
			*list in 1/120
			qui save `cohortlinehistory' //i: historygroup; t: newtime

			qui sum `historygroup', mean
			local ylabel `"ylabel(`r(min)'(1)`r(max)', alternate angle(0) nogrid labsize(tiny) valuelabel noticks)"'

			tempvar y0 y1
			cap gen `y1'=`historygroup'+ 0.5 
			qui sum `y1'
			la val `y1' `:val lab `historygroup''
			cap gen `y0'=`historygroup'- 0.5 
			
			qui levelsof `plotvalue' if `touse', loc(levsplot)

			qui sum `plotvalue' if `touse', mean
			if (`r(min)' < 0) {
				tempvar add 
				cap gen `add' = 0 - `r(min)'
				cap replace `plotvalue' = `plotvalue' + `add'
				qui levelsof `plotvalue' if `touse', loc(levsplot_color)
				colorpalette "198 219 239" "107 174 214" "66 146 198" "31 120 180" "8 81 156" , n(`numlevsplot') nograph
				if (`"`mycolor'"' != "") {
					colorpalette `mycolor' , n(`numlevsplot') nograph
				}
				foreach w of loc levsplot_color {
				loc uu = `w' + 1 
				loc col`w' = r(p`uu') 
				}
				foreach w of loc levsplot_color{
					loc gcom `"`gcom'||rbar `y1' `y0' `newtime' if (`plotvalue'==`w')&(`touse'), barw(`xdist') col("`col`w''") fi(inten100) lw(none) "'
					}
			}
			else {		
				foreach w of loc levsplot{
					loc gcom `"`gcom'||rbar `y1' `y0' `newtime' if (`plotvalue'==`w')&(`touse'), barw(`xdist') col("`col`w''") fi(inten100) lw(none) "'
				}
			}

			loc sc `"sc `historygroup' `newtime' if `touse', mlabpos(0) msy(i)"' 

			if `nopre' == 1 {
					local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2) label(1 "Control") label(2 "Treated") size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("Number of `ids'") `ylabel' `xlabel' "'	
				}
				else { 
				if (`"`prepost'"' != "") {
					local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3) label(1 "Control") label(2 "Treated (Pre)") label(3 "Treated (Post)") size(*0.6) symxsize(3) keygap(1)) xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1) xtitle("`tunit'") ytitle("Number of `ids'") `ylabel' `xlabel' "'
					}
					
					else {
						if "`continuoustreat'" != "" {
						qui sum `treat'
						loc maxminplotvalue = r(max) - r(min)
						loc dismaxminplotvalue = `maxminplotvalue' / 4
						loc r_max = r(max) + `dismaxminplotvalue'
						tempvar plotvalue1
						qui egen `plotvalue1' = cut(`treat'), at(`r(min)' (`dismaxminplotvalue') `r_max')
						qui levelsof `plotvalue1' if `touse', loc (levsplot1)
						tokenize `levsplot1'
						loc contrlev1 `1'
						loc contrlev2 `2'
						loc contrlev3 `3'
						loc contrlev4 `4'
						loc contrlev5 `5'
						loc contrlev11=round(`1', 0.001)
						loc contrlev22=round(`2', 0.001)
						loc contrlev33=round(`3', 0.001)
						loc contrlev44=round(`4', 0.001)
						loc contrlev55=round(`5', 0.001)
						if `contrlev55' > `contrlev44' {
							local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3 4 5) label(1 "`contrlev11'") label(2 "`contrlev22'") label(3 "`contrlev33'") label(4 "`contrlev44'") label(5 "`contrlev55'") title("Treatment levels: ", size(*0.45)) size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("Number of `ids'") `ylabel' `xlabel' "'
						}
						else {
							local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3 4) label(1 "`contrlev11'") label(2 "`contrlev22'") label(3 "`contrlev33'") label(4 "`contrlev44'") title("Treatment level: ", size(*0.45)) size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("Number of `ids'") `ylabel' `xlabel' "'
						}
						}
						else {
							if `numlevstreat' > 2 {
								tokenize `levsplot'
								loc trlev1 `1'
								loc trlev2 `2'
								loc trlev3 `3'
								loc trlev4 `4' // If the number of treatment levels >= 5, need to combine with Continuoustreat
								if "`trlev4'" != ""{ //treatment levels = 4:
								local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(2) order(1 2 3 4) label(1 "Treatment level: `trlev1'") label(2 "Treatment level: `trlev2'") label(3 "Treatment level: `trlev3'") label(4 "Treatment level: `trlev4'") size(*0.55) symxsize(3) keygap(0.5) colgap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("Number of `ids'") `ylabel' `xlabel' "'
								}
								else { //treatment levels = 3:
								local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3) label(1 "Treatment level: `trlev1'") label(2 "Treatment level: `trlev2'") label(3 "Treatment level: `trlev3'") size(*0.55) symxsize(3) keygap(0.5) colgap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("Number of `ids'") `ylabel' `xlabel' "'
								}
							}
							else { //treatment levels = 2:
								local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2) label(1 "Control") label(2 "Treated") size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("Number of `ids'") `ylabel' `xlabel' "'
							}
						}
					} 
				}
				tw `gcom' plotr(fc(white) margin(zero)) ||`sc' `options'
	}
	}





	else if ("`type'" == "bivar" | "`type'" == "bivariate"){
		
		if (`"`mycolor'"' != "") {
			colorpalette `mycolor' , n(2) nograph
			loc y2color = r(p1)
			loc y1color = r(p2)
		}
		else {
			loc y1color = "0 0 0"
			loc y2color = "144 144 144"
		}
		

		if ("`lwd'" == "") {
			loc linewide = "medium"
		}
		else {
			loc linewide = "`lwd'"
		}


			if ("`style'" == "") {
				if ("`discreteoutcome'" == "" & "`continuoustreat'" == "") { //continuous Y, discrete D
					loc style = "l b"
				}
				else if ("`discreteoutcome'" != "" & "`continuoustreat'" == "") { //discrete Y, discrete D
					loc style = "b b"
				}
				else if ("`discreteoutcome'" == "" & "`continuoustreat'" != "") { //continuous Y, continuous D
					loc style = "l l"
				}
				else if ("`discreteoutcome'" != "" & "`continuoustreat'" != "") { //discrete Y, continuous D
					loc style = "b l"
				}
			}
			else if ("`style'" != "") {
				if ("`style'" == "l" | "`style'" == "line") {
					loc style = "l l"
				}
				else if ("`style'" == "b" | "`style'" == "bar") {
					loc style = "b b"
				}
				else if ("`style'" == "c" | "`style'" == "connected") {
					loc style = "c c"
				}
			}


		qui sum `newtime', mean
		local xlabel `"xlabel(`r(min)'(`xlabdist')`r(max)', valuelabel)"'

		qui levelsof `treat' if `touse' , loc (levstreat)
		qui levelsof `outcome' if `touse' , loc (levsoutcome)


		if "`byunit'" == "" {
		// 3.1 Plot D and Y against time in the same graph (average D and Y by year):
			collapse (mean) `outcome' `treat', by(`newtime')

			if ("`style'" == "l b"|"`style'" == "line bar"|"`style'" == "line b"|"`style'" == "l bar") {
				twoway line `outcome' `newtime', `xlabel' yaxis(1) color("`y1color'") lw(`linewide') `options' ///
					|| bar `treat' `newtime', yaxis(2) color("`y2color'%50") xtitle("") `options' ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
			}
			else if ("`style'" == "l l"|"`style'" == "line line"|"`style'" == "line l"|"`style'" == "l line") {
				twoway line `outcome' `newtime', `xlabel' yaxis(1) color("`y1color'") lw(`linewide') `options' ///
					|| line `treat' `newtime', yaxis(2) color("`y2color'") xtitle("") lw(`linewide') `options' ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
			}
			else if ("`style'" == "b l"|"`style'" == "bar line"|"`style'" == "bar l"|"`style'" == "b line") {
				twoway bar `outcome' `newtime', `xlabel' yaxis(1) color("`y1color'%20") `options' ///
					|| line `treat' `newtime', yaxis(2) color("`y2color'") xtitle("") lw(`linewide') `options' ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
			}
			else if ("`style'" == "b b"|"`style'" == "bar bar"|"`style'" == "bar b"|"`style'" == "b bar") {
				twoway bar `outcome' `newtime', `xlabel' yaxis(1) color("`y1color'%50") `options' ///
				|| bar `treat' `newtime', yaxis(2) color("`y2color'%50") xtitle("") `options' ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
			}
			else if ("`style'" == "c b"|"`style'" == "connected bar"|"`style'" == "connected b"|"`style'" == "c bar") {
				twoway connected `outcome' `newtime', `xlabel' yaxis(1) color("`y1color'") lw(`linewide') `options' ///
					|| bar `treat' `newtime', yaxis(2) color("`y2color'%50") xtitle("") `options' ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
			}
			else if ("`style'" == "c c"|"`style'" == "connected connected"|"`style'" == "connected c"|"`style'" == "c connected") {
				twoway connected `outcome' `newtime', `xlabel' yaxis(1) color("`y1color'") lw(`linewide') `options' ///
					|| connected `treat' `newtime', yaxis(2) color("`y2color'") xtitle("") lw(`linewide') `options' ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
			}
			else if ("`style'" == "b c"|"`style'" == "bar connected"|"`style'" == "bar c"|"`style'" == "b connected") {
				twoway bar `outcome' `newtime', `xlabel' yaxis(1) color("`y1color'%20") `options' ///
					|| connected `treat' `newtime', yaxis(2) color("`y2color'") xtitle("") lw(`linewide') `options' ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
			}
			else if ("`style'" == "l c"|"`style'" == "line connected"|"`style'" == "line c"|"`style'" == "l connected") {
				twoway line `outcome' `newtime', `xlabel' yaxis(1) color("`y1color'") lw(`linewide') `options' ///
					|| connected `treat' `newtime', yaxis(2) color("`y2color'") xtitle("") lw(`linewide') `options' ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
			}
			else if ("`style'" == "c l"|"`style'" == "connected line"|"`style'" == "connected l"|"`style'" == "c line") {
				twoway connected `outcome' `newtime', `xlabel' yaxis(1) color("`y1color'") lw(`linewide') `options' ///
					|| line `treat' `newtime', yaxis(2) color("`y2color'") xtitle("") lw(`linewide') `options' ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
			}
		}

		else {
		// 3.2 Plot D and Y against time in the same graph by each unit:
		cap label list `i' 
		if "`r(k)'" == "" {
			tempvar labeli
			qui tostring `i', gen(`labeli')
			labmask `i', val(`labeli') 
		}

		qui levelsof `ids' if `touse' , loc (levsids) 

		local graphs ""
		if ("`discreteoutcome'" == "" & "`continuoustreat'" == "") { //continuous Y, discrete D
			foreach x of loc levsids {
				local lx: label (`i') `x'
				qui levelsof `treat' if `touse' , loc (levstreat)

				if ("`style'" == "l b"|"`style'" == "line bar"|"`style'" == "line b"|"`style'" == "l bar") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel'  ///
						||, ylabel(`levstreat', valuelabel axis(2)) ytitle("",axis(2)) xtitle("") title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "l l"|"`style'" == "line line"|"`style'" == "line l"|"`style'" == "l line") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, ylabel(`levstreat', valuelabel axis(2)) ytitle("",axis(2)) xtitle("") title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b l"|"`style'" == "bar line"|"`style'" == "bar l"|"`style'" == "b line") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%20") lw(none) `xlabel' ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, ylabel(`levstreat', valuelabel axis(2)) ytitle("",axis(2)) xtitle("") title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b b"|"`style'" == "bar bar"|"`style'" == "bar b"|"`style'" == "b bar") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%50") lw(none) `xlabel' ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel'  ///
						||, ylabel(`levstreat', valuelabel axis(2)) ytitle("",axis(2)) xtitle("") title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c b"|"`style'" == "connected bar"|"`style'" == "connected b"|"`style'" == "c bar") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel'  ///
						||, ylabel(`levstreat', valuelabel axis(2)) ytitle("",axis(2)) xtitle("") title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c c"|"`style'" == "connected connected"|"`style'" == "connected c"|"`style'" == "c connected") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, ylabel(`levstreat', valuelabel axis(2)) ytitle("",axis(2)) xtitle("") title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b c"|"`style'" == "bar connected"|"`style'" == "bar c"|"`style'" == "b connected") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%20") lw(none) `xlabel' ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, ylabel(`levstreat', valuelabel axis(2)) ytitle("",axis(2)) xtitle("") title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "l c"|"`style'" == "line connected"|"`style'" == "line c"|"`style'" == "l connected") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, ylabel(`levstreat', valuelabel axis(2)) ytitle("",axis(2)) xtitle("") title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c l"|"`style'" == "connected line"|"`style'" == "connected l"|"`style'" == "c line") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, ylabel(`levstreat', valuelabel axis(2)) ytitle("",axis(2)) xtitle("") title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
			}
		}
		else if ("`discreteoutcome'" != "" & "`continuoustreat'" == "") { //discrete Y, discrete D
			foreach x of loc levsids {
				local lx: label (`i') `x'
				qui levelsof `treat' if `touse' , loc (levstreat) 
				qui levelsof `outcome' if `touse' , loc (levsoutcome) 				
				
				if ("`style'" == "l b"|"`style'" == "line bar"|"`style'" == "line b"|"`style'" == "l bar") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel' ylabel(`levstreat', valuelabel axis(2))  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "l l"|"`style'" == "line line"|"`style'" == "line l"|"`style'" == "l line") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide') ylabel(`levstreat', valuelabel axis(2))  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b l"|"`style'" == "bar line"|"`style'" == "bar l"|"`style'" == "b line") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%20") lw(none) `xlabel' ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide') ylabel(`levstreat', valuelabel axis(2))  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b b"|"`style'" == "bar bar"|"`style'" == "bar b"|"`style'" == "b bar") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%50") lw(none) `xlabel' ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel' ylabel(`levstreat', valuelabel axis(2))  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c b"|"`style'" == "connected bar"|"`style'" == "connected b"|"`style'" == "c bar") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel' ylabel(`levstreat', valuelabel axis(2))  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c c"|"`style'" == "connected connected"|"`style'" == "connected c"|"`style'" == "c connected") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide') ylabel(`levstreat', valuelabel axis(2))  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b c"|"`style'" == "bar connected"|"`style'" == "bar c"|"`style'" == "b connected") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%20") lw(none) `xlabel' ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide') ylabel(`levstreat', valuelabel axis(2))  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "l c"|"`style'" == "line connected"|"`style'" == "line c"|"`style'" == "l connected") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide') ylabel(`levstreat', valuelabel axis(2))  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c l"|"`style'" == "connected line"|"`style'" == "connected l"|"`style'" == "c line") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide') ylabel(`levstreat', valuelabel axis(2))  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}

			}
		}
		else if ("`discreteoutcome'" == "" & "`continuoustreat'" != "") { //continuous Y, continuous D
			foreach x of loc levsids {
				local lx: label (`i') `x'

				if ("`style'" == "l b"|"`style'" == "line bar"|"`style'" == "line b"|"`style'" == "l bar") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel'  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "l l"|"`style'" == "line line"|"`style'" == "line l"|"`style'" == "l line") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b l"|"`style'" == "bar line"|"`style'" == "bar l"|"`style'" == "b line") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%20") lw(none) `xlabel' ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b b"|"`style'" == "bar bar"|"`style'" == "bar b"|"`style'" == "b bar") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%50") lw(none) `xlabel' ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel'  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c b"|"`style'" == "connected bar"|"`style'" == "connected b"|"`style'" == "c bar") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel'  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c c"|"`style'" == "connected connected"|"`style'" == "connected c"|"`style'" == "c connected") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b c"|"`style'" == "bar connected"|"`style'" == "bar c"|"`style'" == "b connected") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%20") lw(none) `xlabel' ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "l c"|"`style'" == "line connected"|"`style'" == "line c"|"`style'" == "l connected") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c l"|"`style'" == "connected line"|"`style'" == "connected l"|"`style'" == "c line") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}

			}
		}
		else if ("`discreteoutcome'" != "" & "`continuoustreat'" != "") { //discrete Y, continuous D
			foreach x of loc levsids {
				local lx: label (`i') `x'
				qui levelsof `outcome' if `touse' , loc (levsoutcome) 
				/*
				twoway `lineordot' `outcome' `newtime' if `ids' == `x', yaxis(1) ylabel(`levsoutcome', valuelabel axis(1)) color("`y1color'") `xlabel' lw(`linewide')  ///
				|| `lineordot' `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
				||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw 
				local graphs "`graphs' graph_`x'"
				*/
				if ("`style'" == "l b"|"`style'" == "line bar"|"`style'" == "line b"|"`style'" == "l bar") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel'  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "l l"|"`style'" == "line line"|"`style'" == "line l"|"`style'" == "l line") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b l"|"`style'" == "bar line"|"`style'" == "bar l"|"`style'" == "b line") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%20") lw(none) `xlabel' ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b b"|"`style'" == "bar bar"|"`style'" == "bar b"|"`style'" == "b bar") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%50") lw(none) `xlabel' ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel'  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c b"|"`style'" == "connected bar"|"`style'" == "connected b"|"`style'" == "c bar") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| bar `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'%50") lw(none) `xlabel'  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c c"|"`style'" == "connected connected"|"`style'" == "connected c"|"`style'" == "c connected") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "b c"|"`style'" == "bar connected"|"`style'" == "bar c"|"`style'" == "b connected") {
					twoway bar `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'%20") lw(none) `xlabel' ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "l c"|"`style'" == "line connected"|"`style'" == "line c"|"`style'" == "l connected") {
					twoway line `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| connected `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}
				else if ("`style'" == "c l"|"`style'" == "connected line"|"`style'" == "connected l"|"`style'" == "c line") {
					twoway connected `outcome' `newtime' if `ids' == `x', yaxis(1) color("`y1color'") `xlabel' lw(`linewide') ylabel(`levsoutcome', valuelabel axis(1)) ytitle("")  ///
						|| line `treat' `newtime' if `ids' == `x', yaxis(2) color("`y2color'") `xlabel' lw(`linewide')  ///
						||, xtitle("") ytitle("",axis(2)) title("`lx'") name(graph_`x', replace) nodraw  ///
					legend(region(lstyle(none) fcolor(none)) rows(1) size(*0.8) symxsize(3))
						local graphs "`graphs' graph_`x'"
				}

			}
		}
		
		tokenize graphs
		loc graph_1 `2'
		grc1leg `graphs', legendfrom(`graph_1') ycommon cols(4) l1title(`outcome') r1title(`treat') `options'
		}
	}
	restore
end