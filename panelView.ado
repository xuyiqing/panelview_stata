/*
Version 0.1
Aug 03 2021
*/

capture program drop panelView

program define panelView
	version 15.1
	syntax varlist(min = 1 numeric) [if] [in] , ///
	I(varname) T(varname numeric)	///
	TYPE(string)					///
	[        						///
	discreteoutcome					///
	bytiming						///
	MYCOLor(string)					///
	PREpost(string) 				///
	continuoustreat					///
	xlabdist(integer 1)				/// 
	ylabdist(integer 1)				///
	ignoretreat						///
	bytreatgroup					///
	*								///
	]
	
	
	//check needed packages
	cap which colorpalette.ado
	if _rc {
		di as error "colorpalette.ado required: {stata search colorpalette}"
		exit 199
	}
	
	cap which labmask.ado
	if _rc {
		di as error "labmask.ado required: {stata net install labutil.pkg}"
		exit 199
	}
	

	//check for bad option combinations: 
	if "`continuoustreat'" != "" {
		if ("`type'" == "treat") {
		if  ("`prepost'" != "off") {
		di as err "option ContinuousTreatment and PrePost(off) should be combined" 
		exit 198
		}
		}
	}


	if "`continuoustreat'" != "" {
		if "`bytiming'" != "" { 
			di as err "option Continuous Treatment and ByTiming may not be combined"
			exit 198
		}
	}

	if "`continuoustreat'" != "" {
		if "`ignoretreat'" != "" {
			di as err ///
			"option Continuous Treatment and Ignoretreat may not be combined"
			exit 198
		}
	}

	if "`ignoretreat'" != "" {
		if "`prepost'" != "" { 
			di as err ///
			"option Ignoretreat and PrePost(off) may not be combined"
			exit 198
		}
	}

	if ("`bytreatgroup'" != "") { 
		if ("`prepost'" != "") { 
			di as err ///
			"option Bytreatgroup and PrePost(off) may not be combined"
			exit 198
		}
	}

	if ("`type'" == "outcome") {
		if ("`bytiming'" != "") {
			di as err ///
			"option Type(outcome) and Bytiming may not be combined"
			exit 198
		}
	}

    set trace off 

	preserve 
	tempfile backup

	qui keep `varlist' `i' `t' //only keep using variables, i.e. include covariates
	marksample touse 
	drop if `touse' == 0 //To include covariates


	qui ds `varlist'
	tempvar numvar
	gen `numvar' = `: word count `r(varlist)''

	if `numvar' == 1 {
		if ("`ignoretreat'" == "") {
			di as err "should combine with option Ignoretreat when varlist has only one variable" 
			exit 198
		} 
		else {
			tokenize `varlist'
			loc outcome `1'
		}
	}
	else if  `numvar' == 2 {
		if "`ignoretreat'" != "" {
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
		if "`ignoretreat'" != "" { 
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
	if "`r(k)'" != "" {
		egen `nids' = group(`ids') 
	}
	else{
		tempvar labelids
		qui tostring `ids', gen(`labelids')
		labmask `ids', val(`labelids') 
		egen `nids' = group(`ids')
		
	}
	
	qui levelsof `nids' if `touse'
	loc numids = r(r)

	

	// ignore treatment:
	tempvar gcontrol
	if ("`continuoustreat'" != "" & "`type'" == "outcome") { 
			gen `gcontrol' = 1 
			} 
			else {
    		if ("`ignoretreat'" != "") { 
			gen `gcontrol' = 1 
			} 
			else { 
			qui levelsof `treat' if `touse', loc (levstreat)
			loc numlevstreat = r(r) 
			
			if (`numlevstreat' == 2) {
			tempvar max_treat
			bys `nids': egen `max_treat' = max(`treat') 
			gen `gcontrol' = 1
			qui replace `gcontrol' = 0 if `max_treat' >= 1
			}
			else {
				if (`numlevstreat' == 1) {
					di "Only one treatment level"
					gen `gcontrol' = 1 
				}
				else { 
					if  ("`prepost'" != "off") { 
					di as err "with more than two treatment levels, option PrePost(off) should be combined" 
					exit 198
					}
					else {
						if (`numlevstreat' >= 5) { // If the number of treatment levels >= 5, need to combine with Continuoustreat
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
		gen `bytime' = .
		replace `bytime' = `tunit' if `treat' > = 1
		bys `nids': egen `min_bytime' = min(`bytime')
		bys `nids': egen `num_trtime' = count(`bytime')
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
	if "`ignoretreat'" == "" {
	if ("`type'" == "outcome" & "`discreteoutcome'" == "" ) { 
			destring `labeltime', replace
			tempvar L1_labeltime L1_time
			bys `nids': gen `L1_labeltime' = `labeltime'[_n-1] if `treat' >= 1
			bys `nids': egen `L1_time' = min(`L1_labeltime')
			replace `treat' = 1 if `labeltime' == `L1_time'			
		}
	}


	tempvar plotvalue 
	if ("`continuoustreat'" != "" & "`type'" == "outcome") {
		gen `plotvalue' = 0
		}
		else {
			if "`ignoretreat'" != "" { 
			gen `plotvalue' = 0
			}
			else { 
				if ("`type'" == "outcome" & `numlevstreat' > 2) {
				gen `plotvalue' = 0
				}
				else {	
				gen `plotvalue' = `treat'
				//remapping continuous treatment to 5 levels to fit color palettes levels:
				if "`continuoustreat'" != "" {
					qui sum `plotvalue' 
					loc maxminplotvalue = r(max) - r(min)
					qui replace `plotvalue' = int((`plotvalue' - r(min)) * 4 / `maxminplotvalue' ) 
				}
				}
			}
		} 
		




	qui levelsof `plotvalue' if `touse', loc (levsplot) 
	loc numlevsplot = r(r) 

	if "`ignoretreat'" == "" { 
	if ("`continuoustreat'" == "" | "`type'" != "outcome") {
		if `numlevstreat' == 2 {
		if "`prepost'" != "off" {
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
				replace `altlevsplot' =  `altlevsplot' - 1
				qui levelsof `altlevsplot' if `touse', loc (levsplot)
				loc numlevsplot = r(r)
				drop `altlevsplot'
			}
		}
	}
	}
	
	//deciding color
	colorpalette Reds , n(`numlevsplot') nograph

	if (`"`mycolor'"' != "") {
		colorpalette `mycolor' , n(`numlevsplot') nograph
		
	}
	
	qui return list
	tokenize `levsplot' 
	loc trpreortr `2'
	tempvar nopre
	if "`trpreortr'" != "" {
		gen `nopre' = (`trpreortr' == 2) 
	}
	else {
		gen `nopre' = 0
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
					if (`"`prepost'"' != "off" & `w' == 1 ) { 
					//with prepost: `w' == 1: treated(pre)
						loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse' , lcolor("`col`w''")"'
					} 
					else if (`"`prepost'"' == "off" & `w' == 0 ) { 
					//without prepost: `w' == 0: treated(pre)
						loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `gcontrol' == 0 & `touse' , lcolor("`col`w''")"'
					}
				loc lines1 `" `lines1' || line `outcome' `tunit' if `nids' == `x' & `plotvalue' == `w' & `touse' , lcolor("`col`w''")"' 
			}
		}
		
		
		if ("`continuoustreat'" != "") {
			tw `lines1' legend(region(lstyle(none) fcolor(none)) order(1) label(1 "Observed")) yscale(noline) xscale(noline) `options'
			}
			else { // not continuoustreat:
				if ("`ignoretreat'" != "") { // ignore treatment:
				tw `lines1' legend(region(lstyle(none) fcolor(none)) order(1) label(1 "Observed")) yscale(noline) xscale(noline) `options'
				}
				else {
					if `numlevstreat' > 2  { 
						tw `lines1' legend(region(lstyle(none) fcolor(none)) order(1) label(1 "Observed")) yscale(noline) xscale(noline) `options'
					}
					else { // not ignore treatment:
						if ("`bytreatgroup'" != "" ) { //with bytreatgroup:
						twoway `lines1' by(`bgplotvalue', legend(off) note("") cols(1)) yscale(noline) xscale(noline) `options'
						}
						else{ //without bytreatgroup:
						if (`"`prepost'"' != "off") {
						tw `lines1' legend(off) yscale(noline) xscale(noline) `options'
						}
							else { //prepost=off:
								tw `lines1' legend(off) yscale(noline) xscale(noline) `options'
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
			gen `rtime' = `tunit' + runiform(-0.2, 0.2)
			gen `rout' = `outcome' + runiform(-0.2, 0.2)

			
			loc dot1
			
			foreach w of loc levsplot {
				loc dot1 `" `dot1' || sc `rout' `rtime' if `plotvalue' == `w' & `touse' , mcolor("`col`w''") msize(small)"'
			}
			
			if ("`continuoustreat'" != "") { 
			tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) order(1) label(1 "Observed")) ytitle("`outcome'") xtitle("`tunit'") `options'
			}
			else { 
					if "`ignoretreat'" != "" { // ignore treatment:
					tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) order(1) label(1 "Observed")) ytitle("`outcome'") xtitle("`tunit'") `options'
					} 
					else {
					if `numlevstreat' > 2  { 
					tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) order(1) label(1 "Observed")) ytitle("`outcome'") xtitle("`tunit'") `options'
					}
					else { // not ignore treatment:
					if ("`bytreatgroup'" != "" ) { //with bytreatgroup: cannot combined with prepost(off)
					twoway `dot1' by(`bgplotvalue', cols(1) note("")) legend(region(lstyle(none) fcolor(none)) note("") row(1) label(1 "Control") label(2 "Treated (Pre)") label(3 "Treated (Post)")) yscale(noline) xscale(noline) ytitle("`outcome'") xtitle("`tunit'") `options'
					} 
					else{ //without bytreatgroup:
					if (`"`prepost'"' != "off") {
					tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) label(1 "Control") label(2 "Treated (Pre)") label(3 "Treated (Post)")) yscale(noline) xscale(noline) ytitle("`outcome'") xtitle("`tunit'") `options'
					}
					else { //prepost=off:
					tw `dot1' legend(region(lstyle(none) fcolor(none)) row(1) label(1 "Control") label(2 "Treated")) ytitle("`outcome'") xtitle("`tunit'") `options'
					}
					}
					}
					}
			}
		}		
	}
	
	
	
	
	
	else if ("`type'" == "treat"){
	// 2. Heatmap of treatment: type(treat):

		if `"`bytiming'"' != "" {
		*2.1. With bytiming:		
		tempvar y0 y1
		gen `y1'=`nids3'+ 0.5 
		qui sum `y1'
		la val `y1' `:val lab `nids3''
		gen `y0'=`nids3'- 0.5 
		
		qui levelsof `plotvalue' if `touse', loc(levsplot)
		qui sum `plotvalue' if `touse', mean
		if (`r(min)' < 0) {
			tempvar add 
			gen `add' = 0 - `r(min)'
			replace `plotvalue' = `plotvalue' + `add'
			qui levelsof `plotvalue' if `touse', loc(levsplot_color)
			colorpalette Reds , n(`numlevsplot') nograph
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
		gen `y1'=`nids'+ 0.5 
		qui sum `y1'
		la val `y1' `:val lab `nidslab''
		gen `y0'=`nids'- 0.5 
		
		qui levelsof `plotvalue' if `touse', loc(levsplot)
		qui sum `plotvalue' if `touse', mean
		if (`r(min)' < 0) {
			tempvar add 
			gen `add' = 0 - `r(min)'
			replace `plotvalue' = `plotvalue' + `add'
			qui levelsof `plotvalue' if `touse', loc(levsplot_color)
			colorpalette Reds , n(`numlevsplot') nograph
			if (`"`mycolor'"' != "") {
				colorpalette `mycolor' , n(`numlevsplot') nograph
			}
			foreach w of loc levsplot_color {
			loc uu = `w' + 1 
			loc col`w' = r(p`uu') 
			}
			foreach w of loc levsplot_color{
				loc gcom `"`gcom'||rbar `y1' `y0' `newtime' if (`plotvalue'==`w')&(`touse'), barw(`xdist') col("`col`w''") fi(inten100) lw(none) "' //100% intensity, full color. Line has zero width: it vanishes
				}
		}
		else {
			foreach w of loc levsplot{
				loc gcom `"`gcom'||rbar `y1' `y0' `newtime' if (`plotvalue'==`w')&(`touse'), barw(`xdist') col("`col`w''") fi(inten100) lw(none) "' //100% intensity, full color. Line has zero width: it vanishes
				}
		}

		loc sc `"sc `nids' `newtime' if `touse', mlabpos(0) msy(i)"' 
		}

			if "`ignoretreat'" != "" { // ignore treatment:
			local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1) label(1 "Observed") size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
			} 
			else { 
				if `nopre' == 1 {
				local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2) label(1 "Control") label(2 "Treated") size(*0.6) symxsize(3) keygap(1))  xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1)  xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'	
				}
				else { // not ignore treatment:
				if (`"`prepost'"' != "off") {
					local gcom `"`gcom' legend(region(lstyle(none) fcolor(none)) rows(1) order(1 2 3) label(1 "Control") label(2 "Treated(Pre)") label(3 "Treated(Post)") size(*0.6) symxsize(3) keygap(1)) xsize(2) ysize(2) yscale(noline reverse) xscale(noline) aspect(1) xtitle("`tunit'") ytitle("`ids'") `ylabel' `xlabel' "'
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
		tw `gcom' plotr(fc(white) margin(zero)) ||`sc' `options'
	}
	
	restore
end