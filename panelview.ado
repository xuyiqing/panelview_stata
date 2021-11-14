/*
Version 0.1
Nov 07 2021
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
	MYCOLor(string)					///
	PREpost							///
	xlabdist(integer 1)				/// 
	ylabdist(integer 1)				///
	bygroup							///
	style(string)					///
	byunit							///
	theme(string)					///
	lwd(string)						///
	*								///
	]
	
	//check if i and t uniquely identify the obs:
	isid `i' `t'


	//check needed packages

	cap which colorpalette.ado
	if _rc {
		*di as error "colorpalette.ado required: {stata ssc install palettes, replace}"
		di as error "colorpalette.ado required: {stata search gr0075} and click to install"
		exit 199
	}
	
	cap which labmask.ado
	if _rc {
		di as error "labmask.ado required: {stata ssc install labutil, replace}"
		exit 199
	}

	cap which sencode.ado
	if _rc {
		di as error "sencode.ado required: {stata ssc install sencode, replace}"
		exit 199
	}

	cap which grc1leg.ado
	if _rc {
		di as error "grc1leg.ado required: {stata search grc1leg} and click to install"
		exit 199
	}
	

	//check for bad option combinations:

	if "`continuoustreat'" != "" {
		if "`bytiming'" != "" { 
			di as err "option continuoustreat and bytiming may not be combined"
			exit 198
		}
	}

	if "`continuoustreat'" != "" {
		if "`ignoretreat'" != "" {
			di as err ///
			"option continuoustreat and ignoretreat may not be combined"
			exit 198
		}
	}

	if "`continuoustreat'" != "" {
		if ("`type'" == "miss" | "`type'" == "missing") {
			di as err ///
			"option continuoustreat and type(missing) may not be combined"
			exit 198
		}
	}	

	if ("`bygroup'" != "") { 
		if ("`prepost'" == "") { 
			di as err ///
			"option bygroup and prepost should be combined"
			exit 198
		}
	}

	if ("`type'" == "outcome") {
		if ("`bytiming'" != "") {
			di as err ///
			"option type(outcome) and bytiming may not be combined"
			exit 198
		}
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
	marksample touse 
	cap drop if `touse' == 0 //To include covariates


	qui ds `varlist'
	tempvar numvar
	gen `numvar' = `: word count `r(varlist)''


	if `numvar' == 1 {
		if ("`ignoretreat'" == "" & "`type'" != "miss" & "`type'" != "missing") {
				di as err "should combine with option type(missing) or ignoretreat when varlist has only one variable" 
				exit 198
		} 
		else {
			tokenize `varlist'
			loc outcome `1'
		}
	}
	else if  `numvar' == 2 {
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
	else { //`numvar' >= 3:
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
		


	quietly count if `touse'
	if r(N) == 0 {
		error 2000
	}

	local ids `i'
	local tunit `t'
	
	
	tempvar nids
	cap label list `ids' 
	if "`r(k)'" != "" { //numeric units indicator with labels:
		egen `nids' = group(`ids') 
		*label list `ids'
	}
	else{ //numeric units indicator without labels or string variable:
	capture confirm numeric variable `ids'
	if !_rc { //numeric units indicator without labels:
		tempvar labelids
		qui tostring `ids', gen(`labelids')
		labmask `ids', val(`labelids') 
		*label list `ids'

		egen `nids' = group(`ids')
	}
	else { //string variable:
		tempvar i_numeric labeli
		encode `ids',gen(`i_numeric')
		*label list `i_numeric'
		drop `ids'
		rename `i_numeric' `ids'
	
		egen `nids' = group(`ids')	
	}
	}
	
	qui levelsof `nids' if `touse'
	loc numids = r(r)

	

	// ignore treatment:
	tempvar gcontrol
	if ("`continuoustreat'" != "" & "`type'" == "outcome") { 
			gen `gcontrol' = 1 
	}
	else {
    if ("`ignoretreat'" != ""|"`type'" == "miss" | "`type'" == "missing") { 
			gen `gcontrol' = 1 
			} 
			else { 
			qui levelsof `treat' if `touse', loc (levstreat)
			loc numlevstreat = r(r) 
			
			if (`numlevstreat' == 2) {
			tempvar max_treat
			cap bys `nids': egen `max_treat' = max(`treat') 
			cap gen `gcontrol' = 1
			qui replace `gcontrol' = 0 if `max_treat' >= 1
			}
			else {
				if (`numlevstreat' == 1) {
					di "Only one treatment level"
					gen `gcontrol' = 1 
				}
				else { 
					if  ("`prepost'" != "") { 
					di as err "with more than two treatment levels, option prepost may not be combined" 
					exit 198
					}
					else {
						if (`numlevstreat' >= 5) {
						if ( "`continuoustreat'" == "") {
							di as err " If the number of treatment levels >= 5, need to combine with Continuoustreat"
							exit 198
						}
						}
						else {
							gen `gcontrol' = 1
						}
					}
				}
			}
			}
			}	

	sort `ids' `tunit' 

	//sort by time of first treatment
	if "`bytiming'" != "" { 
	cap which sencode.ado
		if _rc {
		di as error "sencode.ado required: {stata ssc install sencode, replace}"
		exit 199
		}

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
	}
	else {
		tempvar nids2 nidslab
		decode `ids', generate(`nids2')
		sencode `nids2', generate(`nidslab')
	}		
	
	qui levelsof `nids' if `touse' , loc (levsnids) 
	
	tempvar newtime
	egen `newtime' = group(`tunit')
	qui sum `newtime'
	loc maxmintime = r(max) - r(min)
	qui levelsof `newtime'
	loc numsoftime = r(r)
	loc plotcoef = `maxmintime' / (`numsoftime' -1) 
	
	tempvar labeltime
	qui tostring `tunit', gen(`labeltime')
	labmask `newtime', val(`labeltime')


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


	tempvar plotvalue 
	if ("`continuoustreat'" != "" & "`type'" == "outcome") {
		cap gen `plotvalue' = 0
		}
		else {
			if ("`ignoretreat'" != ""|"`type'" == "miss" | "`type'" == "missing") { 
			cap gen `plotvalue' = 0
			}
			else { 
				if ("`type'" == "outcome" & `numlevstreat' > 2) {
				cap gen `plotvalue' = 0
				}
				else {	
				cap gen `plotvalue' = `treat'
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
		gen `ignoretreat' = 1	
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
				egen `altlevsplot' = group(`plotvalue') if `touse' 
				cap replace `altlevsplot' =  `altlevsplot' - 1
				qui levelsof `altlevsplot' if `touse', loc (levsplot)
				loc numlevsplot = r(r)
				drop `altlevsplot'
			}
		}
	}
	}
	
	//deciding color
	colorpalette "198 219 239" "eltblue" "66 146 198" "31 120 180" "8 81 156", n(`numlevsplot') nograph

	if (`"`mycolor'"' != "") {
		colorpalette `mycolor' , n(`numlevsplot') nograph
	}

	if "`theme'" == "bw" {
		colorpalette Greys , n(`numlevsplot') nograph
	}

	if (`"`mycolor'"' != "Greys" & `"`mycolor'"' != "") { 
		if ( "`theme'" == "bw") {
			di as err " If mycolor is not Greys, mycolor cannot combine with theme(bw)"
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
		loc uu = `w' + 1 
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
		bysort `nids': egen `bgplotvalue' = min(`plotvalue')
		label define `labplotvalue' 0 "Always Under Control" 1 "Treatment Status Changed" 2 "Always Treated"
		label val `bgplotvalue' `labplotvalue'




	if ("`type'" == "outcome") { 
	//1. ploting outcome: type(outcome):
		if ("`discreteoutcome'" == "" ) {
		//1.1. plotting lines of continuous outcome:
		di "now display lines of continuous outcome"
		loc lines1
		
		foreach w of loc levsplot {
			foreach x of loc levsnids {
					if (`"`prepost'"' != "" & `w' == 1 ) { 
					//with prepost: `w' == 1: treated(pre)
						loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse' , lcolor("`col`w''")"'
					} 
					else if (`"`prepost'"' == "" & `w' == 0 ) { 
					//without prepost: `w' == 0: treated(pre)
						loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse' , lcolor("`col`w''")"'
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
						tempvar allunits 								
						egen `allunits' = max(`nids') 
						local largestlegend=3*`allunits'+1
						local midlegend=2*`allunits'
						twoway `lines1' by(`bgplotvalue', note("") cols(1)) legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
						}
						else{ //without bygroup: prepost=on:
						if (`"`prepost'"' != "") {
							tempvar allunits 								
							egen `allunits' = max(`nids') 
							local largestlegend=3*`allunits'+1
							local midlegend=2*`allunits'
						tw `lines1' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control" `midlegend' "Treated (Pre)" `largestlegend' "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
						}
							else { //prepost=off:
								tempvar allunits								
								egen `allunits' = max(`nids') 
								local largestlegend=3*`allunits'
								tw `lines1' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 "Control"  `largestlegend' "Treated") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) `options'
								
							}
						}
					}
				}
			}

		}
		else { 
		//1.2. plotting dots of discrete outcome:
		
			//add some randomness to time units and outcome so that they can scatter around:
			di "now display dots of discrete outcome"
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
					twoway `dot1' by(`bgplotvalue', cols(1) note("")) legend(region(lstyle(none) fcolor(none)) note("") row(1) label(1 "Control") label(2 "Treated (Pre)") label(3 "Treated (Post)") size(*0.8) symxsize(3) keygap(1)) yscale(noline) xscale(noline) ytitle("`outcome'") xtitle("`tunit'") `options'
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
	
	
	
	
	
	else if ("`type'" == "treat" | "`type'" == "miss" | "`type'" == "missing"){
	// 2. Heatmap of treatment: type(treat):

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
			else { 
				if `nopre' == 1 {
				local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2) label(1 "Control") label(2 "Treated") size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'	
				}
				else { // not ignore treatment:
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
						egen `plotvalue1' = cut(`treat'), at(`r(min)' (`dismaxminplotvalue') `r_max')
						qui levelsof `plotvalue1' if `touse', loc (levsplot1)
						tokenize `levsplot1'
						loc contrlev1 `1'
						loc contrlev2 `2'
						loc contrlev3 `3'
						loc contrlev4 `4'
						loc contrlev5 `5'					
						local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3 4 5) label(1 "`contrlev1'") label(2 "`contrlev2'") label(3 "`contrlev3'") label(4 "`contrlev4'") label(5 "`contrlev5'") title("Treatment Levels: ", size(*0.45)) size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
						}
						else {
							if `numlevstreat' > 2 {
								tokenize `levsplot'
								loc trlev1 `1'
								loc trlev2 `2'
								loc trlev3 `3'
								loc trlev4 `4' // If the number of treatment levels >= 5, need to combine with Continuoustreat
								if "`trlev4'" != ""{ //treatment levels = 4:
								local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(2) order(1 2 3 4) label(1 "Treatment Level: `trlev1'") label(2 "Treatment Level: `trlev2'") label(3 "Treatment Level: `trlev3'") label(4 "Treatment Level: `trlev4'") size(*0.55) symxsize(3) keygap(0.5) colgap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
								}
								else { //treatment levels = 3:
								local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3) label(1 "Treatment Level: `trlev1'") label(2 "Treatment Level: `trlev2'") label(3 "Treatment Level: `trlev3'") size(*0.55) symxsize(3) keygap(0.5) colgap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
								}
							}
							else {
								local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2) label(1 "Control") label(2 "Treated") size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
							}
						}
					} 
				}
			}
		tw `gcom' plotr(fc(white) margin(zero)) ||`sc'  `options'
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