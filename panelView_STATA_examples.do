/*
Version 0.1
Aug 17 2021
Hongyu Mou
*/

clear

/***** 1. D: dummy; type(treat) *****/
use turnout.dta, clear 
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status")  prepost(off)

*bytiming
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status")  prepost(off) bytiming legend(label(1 "No EDR") label(2 "EDR"))

*prepost != off
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status")  
*bytiming
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status") bytiming

panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) title("EDR Reform") prepost(off) ylabel("")

*mycolor(PuBu)
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status") prepost(off) mycolor(PuBu) bytiming 




/***** 2. Treatment may: missing & switch on and off; type(treat) *****/
use capacity.dta, clear
label list country
panelView lnpop demo lngdp , i(country) t(year) type(treat) mycolor(Reds) prepost(off) title("Democracy and State Capacity") xlabdist(3) ylabdist(10) 

*bytiming
panelView lnpop demo lngdp, i(country) t(year) type(treat) mycolor(Reds) prepost(off) title("Democracy and State Capacity") xlabdist(3) ylabdist(10) bytiming

use capacity.dta, clear
panelView lnpop demo lngdp, i(ccode) t(year) type(treat) mycolor(PuBu) prepost(off) title("Democracy and State Capacity") xlabdist(3) ylabdist(10)
*bytiming
panelView lnpop demo lngdp, i(ccode) t(year) type(treat) mycolor(PuBu) prepost(off) title("Democracy and State Capacity: Treatement Status", size(medsmall)) bytiming xlabdist(3) ylabel(none) 



/***** 3. Plotting a subset of units *****/
use capacity.dta, clear
egen ccodeid = group(ccode)
panelView lnpop demo lngdp ccodeid if ccodeid >= 1 & ccodeid <= 26, i(ccode) t(year) type(treat) mycolor(PuBu) prepost(off) title("Democracy and State Capacity") xlabdist(3)

*bytiming
use capacity.dta, clear
egen ccodeid = group(ccode)
panelView lnpop demo lngdp ccodeid if ccodeid >= 26 & ccodeid <= 51, i(ccode) t(year) type(treat) mycolor(PuBu) prepost(off) title("Democracy and State Capacity") xlabdist(3) bytiming



/***** 4. Ignoring treatment conditions *****/ 
use capacity.dta, clear
panelView demo, i(ccode) t(year) type(treat) mycolor(Reds) title("Missing Values") xlabel(none) ylabel(none) ignoretreat

use capacity.dta, clear
gen demo2 = 0
panelView Capacity demo2 lngdp, i(ccode) t(year) type(treat) title("Regime Type") xlabdist(3) ylabdist(11) legend(off) // type(treat) & numlevstreat = 1 

panelView Capacity demo2 lngdp, i(ccode) t(year) type(outcome) title("Regime Type") legend(off) // type(outcome) & numlevstreat = 1

/* 5. More than Two Treatment Conditions: still discrete treatment */
use capacity.dta, clear
gen demo2 = 0
replace demo2 = -1 if polity2 < -0.5
replace demo2 = 1 if polity2 > 0.5
tab demo2, m 
panelView Capacity demo2 lngdp, i(ccode) t(year) type(treat) title("Regime Type") xlabdist(3) ylabdist(11) prepost(off) mycolor(Blues) // numlevstreat = 3

panelView Capacity demo2 lngdp, i(ccode) t(year) type(outcome) title("Regime Type") prepost(off) // type(outcome) & numlevstreat = 3


use capacity.dta, clear
gen demo2 = 0
replace demo2 = -2 if polity2 < -0.7
replace demo2 = -1 if polity2 < -0.5 & polity2 > -0.7
replace demo2 = 1 if polity2 > 0.5
tab demo2, m 
panelView Capacity demo2 lngdp, i(ccode) t(year) type(treat) title("Regime Type") xlabdist(3) ylabdist(11) prepost(off) mycolor(Blues) // numlevstreat = 4

use capacity.dta, clear
gen demo2 = 0
replace demo2 = -2 if polity2 < -0.7
replace demo2 = -1 if polity2 < -0.5 & polity2 > -0.7
replace demo2 = 1 if polity2 > 0.5 & polity2 < 0.7
replace demo2 = 2 if polity2 > 0.7
tab demo2, m 
panelView Capacity demo2 lngdp, i(ccode) t(year) type(treat) title("Regime Type") xlabdist(3) ylabdist(11) prepost(off) continuoustreat // numlevstreat >= 5



/***** 6. Continuous treatment *****/
use capacity.dta, clear
tab polity2, m
panelView lngdp polity2, i(ccode) t(year) type(treat) continuoustreat mycolor(Reds) prepost(off) title("Regime Type") xlabdist(3) ylabdist(11) 

use capacity.dta, clear
tab polity2, m
replace polity2 = polity2 + 1
panelView lngdp polity2, i(ccode) t(year) type(treat) continuoustreat mycolor(Reds) prepost(off) title("Regime Type") xlabdist(3) ylabdist(11) 


/***** 7. Continuous Outcomes *****/
*Note: paint the period right before treatment

* Continuous outcome: turnout: 0-100; Discrete Treatment: policy_edr: 0/1
use turnout.dta, clear 
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(outcome) xtitle("Year") ytitle("Turnout") title("EDR Reform and Turnout") ylabel(0 (25) 100)
*prepost(off)
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(outcome) xtitle("Year") ytitle("Turnout") title("EDR Reform and Turnout") prepost(off)

use turnout.dta, clear
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(outcome) xtitle("Year") ytitle("Turnout") title("EDR Reform and Turnout") mycolor(PuBu) 

*specify which unit(s) we want to take a look at,ex: id = c("AL", "AR", "CT")):
use turnout.dta, clear 
panelView turnout policy_edr policy_mail_in policy_motor if abb == 1|abb == 2|abb == 6, i(abb) t(year) type(outcome) xtitle("Year") ytitle("Turnout") title("EDR Reform and Turnout (AL, AR, CT)") mycolor(PuBu) 

*Put each unit into different groups, then plot respectively, e.g. (1) always treated, (2) always in control, (3) treatment status changed.
use turnout.dta, clear
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(outcome) xtitle("Year") ytitle("Turnout") by(, title("EDR Reform and Turnout")) bytreatgroup xlabel(1920 (20) 2000)



/***** 8. Plotting any variable in a panel dataset *****/
* Plot an outcome variable (or any variable) in a panel dataset (type = "outcome")
*Ignore treatment status 
use turnout.dta, clear 
panelView turnout, i(abb) t(year) type(outcome) xtitle("Year") ytitle("Turnout") title("Turnout") ylabel(0 (25) 100) ignoretreat



/***** 9. Discrete outcomes *****/
use simdata.dta, replace
panelView Y D if time >= 8 & time <= 15, type(outcome) i(id) t(time) mycolor(Reds) discreteoutcome title("Raw Data") xlabel(8 (2) 15) ylabel(0 (1) 2) 

*ignoretreat
use simdata.dta, replace
panelView Y D if time >= 8 & time <= 15, type(outcome) i(id) t(time) discreteoutcome title("Raw Data") xlabel(8 (2) 15) ylabel(0 (1) 2) ignoretreat

*Put each unit into different groups, then plot respectively:
use simdata.dta, replace
panelView Y D if time >= 8 & time <= 15, type(outcome) i(id) t(time) discreteoutcome by(,title("Raw Data")) xlabel(8 (2) 15) ylabel(0 (1) 2) bytreatgroup 



/***** 10. Type(outcome) & continuoustreat / > 2 treatment levels *****/

use capacity.dta, clear 
* Continuous Outcome: Capacity; Continuoustreat: polity2
panelView Capacity polity2 lngdp, i(ccode) t(year) type(outcome) continuoustreat title("Measuring Stata Capacity") legend(off) theme(bw)

use capacity.dta, clear 
panelView Capacity demo lngdp, i(ccode) t(year) type(outcome) title("Measuring Stata Capacity") ignoretreat

* Treatment indicator has more than 2 treatment levels
* Continuous Outcome: Capacity
use capacity.dta, clear
gen demo2 = 0
replace demo2 = -1 if polity2 < -0.5
replace demo2 = 1 if polity2 > 0.5
tab demo2, m 
panelView Capacity demo2 lngdp, i(ccode) t(year) type(outcome) title("Measuring Stata Capacity") prepost(off) legend(off) // numlevstreat = 3


* Discrete outcome
use simdata.dta, replace
panelView Y D, type(outcome) i(id) t(time) mycolor(Greens) discreteoutcome title("Raw Data") ignoretreat

use simdata.dta, replace
replace D = 2 if time < 5
tab D, m
panelView Y D, type(outcome) i(id) t(time) mycolor(Greens) discreteoutcome title("Raw Data") prepost(off) // numlevstreat = 3

use simdata.dta, replace
range x 0 1
panelView Y x, type(outcome) i(id) t(time) discreteoutcome title("Raw Data") prepost(off) continuoustreat theme(bw) // continuoustreat





/***** 11. Plot mean D and Y against time in the same graph *****/
/***** 1. Y: continuous; D: dummy *****/
use turnout.dta, clear
*label the first and second y axes
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) xlabdist(7) type(bivar) ylabel(0 (20) 100) ylabel(0 (0.1) 0.5, axis(2)) connectedline msize(*0.5)

use capacity.dta, clear 
panelView lnpop demo, i(country) t(year) xlabdist(10) type(bivar) mycolor(Reds) linewidth(medthick)

/***** 2. Y: Discrete; D: dummy *****/
use simdata.dta, replace
panelView Y D,i(id) t(time) discreteoutcome xlabdist(4) type(bivar)

/***** 3. Y: continuous; D: continuous *****/
use capacity.dta, clear 
panelView lnpop polity2, i(country) t(year) continuoustreat prepost(off) xlabdist(20) type(bivar)

/***** 4. Y: Discrete; D: continuous *****/
use simdata.dta, replace
range x 0 1
panelView Y x, i(id) t(time) prepost(off) continuoustreat discreteoutcome xlabdist(4) type(bivar)


/***** Line the discete treatment *****/
* Y: continuous; D: dummy 
use turnout.dta, clear
panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) xlabdist(7) style(line) type(bivar)

*Y: Discrete; D: dummy
use simdata.dta, replace
panelView Y D,i(id) t(time) discreteoutcome xlabdist(4) style(line) type(bivar) connectedline





/***** 12. Plot D and Y against time in the same graph by each unit *****/

/***** 1. Y: continuous; D: dummy *****/
use turnout.dta, clear
panelView turnout policy_edr policy_mail_in policy_motor if abb >= 1 & abb <= 12, i(abb) t(year) xlabdist(10) type(bivar) byunit 

use capacity.dta, clear 
panelView lnpop demo if country >= 1 & country <= 24, i(country) t(year) xlabdist(20) type(bivar) byunit

/***** 2. Y: Discrete; D: dummy *****/
use simdata.dta, replace
panelView Y D if id >= 101 & id <= 120,i(id) t(time) discreteoutcome xlabdist(4) type(bivar) byunit


/***** 3. Y: continuous; D: continuous *****/
use capacity.dta, clear 
panelView lnpop polity2 if country >= 1 & country <= 12, i(country) t(year) continuoustreat prepost(off) xlabdist(20) type(bivar) byunit

/***** 4. Y: Discrete; D: continuous *****/
use simdata.dta, replace
range x 0 1
panelView Y x if id >= 101 & id <= 112, i(id) t(time) prepost(off) continuoustreat discreteoutcome xlabdist(4) type(bivar) byunit



/***** Line the discete treatment *****/
* Y: continuous; D: dummy 
use turnout.dta, clear
panelView turnout policy_edr policy_mail_in policy_motor if abb >= 1 & abb <= 12, i(abb) t(year) xlabdist(10) style(line) type(bivar) byunit

*Y: Discrete; D: dummy
use simdata.dta, replace
panelView Y D if id >= 101 & id <= 120,i(id) t(time) discreteoutcome xlabdist(4) style(line) type(bivar) byunit connectedline

 