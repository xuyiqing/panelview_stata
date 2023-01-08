{smcl}
{* *! version 0.1.4 29Dec2022}{...}
{cmd:help panelview}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:panelview} {hline 2}}Visualizing Panel Data {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 18 2}
{cmdab:panelview} {it:{help varname:Y}} [{it:{help varname:D}} {it:{help varlist:X}}]
{ifin} 
{cmd:,} {opt i(varname)} {opt t(varname numeric)} {opt type(string)}
[{it:options}]

{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Main}
{synopt:{opt Y D X}}{it:{help varlist}} of outcome variable, treatment variable, and covariates, respectively. Including covariates may change the look of the plot due to missing values in these covariates.
Variables appearing in the {cmd:if}/{cmd:in} clause should be included in the varlist{p_end}
{synopt:{opth i(varname)}}specifies the unit (group) indicator{p_end}
{synopt:{opth t(varname)}}specifies the time indicator{p_end}
{synopt:{opt type(string)}}can be {cmd:treat}, {cmd:outcome}, {cmd:{ul:bivar}iate}, and {cmd:{ul:miss}ing}.
{cmd:type(treat)} plots treatment assignment using a heatmap; {cmd:type(outcome)} plots a variable in a time-series fashion;
{cmd:type(bivariate)} plots the outcome and treatment against time in the same graph; {cmd:type(missing)} plots the missing data status of a variable. {p_end}

{syntab:Advanced}
{synopt:{opt continuoustreat}}presents the treatment variable {cmd:D} in a continuous fashion{p_end}
{synopt:{opt discreteoutcome}}when a variable is discrete, make sure {cmd: panelview} respects its discreteness in {cmd: type(outcome)} plots{p_end}
{synopt:{opt bytiming}}sorts units by when they first receive the treatment; if the timing is the same, then by the total number of periods exposed to the treatment{p_end}
{synopt:{opt ignoretreat}}omits the treatment indicator, that is, any variables after {cmd: Y} will be interpreted as covariates{p_end}
{synopt:{opt ignoreY}}shows treatment status of the first variable in the varlist instead of the second (e.g., D in formula is D X, instead of X).
It needs to be combined with {cmd:type(treat)} or {cmd:type(missing)}. If there is only one variable in the varlist, the option is turned on by default{p_end}
{synopt:{opt mycol:or(string)}}changes the color schemes; click {it:{help colorpalette:here}} for sequential colors (3-9 colors){p_end}
{synopt:{opt pre:post}}distinguishes the pre- and post-treatment periods for treated units{p_end}
{synopt:{opt xlabdist(integer)}}changes the gap between labels on the x-axis; default is {cmd: 1}{p_end}
{synopt:{opt ylabdist(integer)}}changes the gap between labels on the y-axis; default is {cmd: 1}{p_end}
{synopt:{opt bygroup}}puts each unit into different treatment groups, then plot them separately in a column when {cmd: type(outcome)} is invoked{p_end}
{synopt:{opt style()}}determines the style of the elements in a plot. The first and second entries define the style of the outcome and treatment, respectively.
{cmd:connected} or {cmd:c} for connected lines, {cmd:line} or {cmd:l} for lines, and {cmd:bar} or {cmd:b} for bars{p_end}
{synopt:{opt byunit}}plots the outcome and treatment variables against time by each unit when {cmd: type(bivariate)} is invoked{p_end}
{synopt:{opt theme(bw)}}uses the black and white theme (default when specified {cmd:type(bivar)}){p_end}
{synopt:{opt lwd()}}sets the line width in {cmd:type(bivar)}. Default is {cmd:medium}{p_end}
{synopt:{opt leavegap}}keeps the time gap as an white bar if time is not evenly distributed (possibly due to missing data){p_end}
{synopt:{opt bygroupside}}arranges subfigures of {cmd:bygroup} in a row rather than in a column{p_end}
{synopt:{opt displayall}}shows all units if the number of units is more than 500, otherwise we randomly select 500 units to present{p_end}
{synopt:{opt bycohort}}plots the average outcome lines based on unique treatment history{p_end}
{synopt:{opt collapsehistory}}plots only the unique treatment histories, 
including figures alongside the plot for the number of units whose histories are characterized by each pattern{p_end}
{synopt:{opt *}}Common graph options, such as {cmd:title}, {cmd:ytitle}, {cmd:xtitle}, {cmd:xlabel}, {cmd:ylabel}, and {cmd:legend}, can be applied in {cmd:panelview} as well.

{synoptline}
{p2colreset}{...}
{p 4 6 2}
  {p_end}

{title:Description}

{pstd}
{opt panelview} has three main functionalities: {p_end}
{pstd}
(1) it plots the treatment status and missing values in a panel dataset; {p_end}
{pstd}
(2) it visualizes variables of interest in a time-series fashion;  {p_end}
{pstd}
(3) it depicts the bivariate relationships between a treatment variable and an outcome variable either by unit or in aggregate. {p_end}
{pstd}

{title:Examples}

{pstd}Load example data (the turnout dataset){p_end}
{phang2}. {stata sysuse turnout, clear}{p_end}

{pstd}Basic syntax{p_end}
{phang2}. {stata panelview turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status", size(medium))}{p_end}

{p 6 6 2} In this plot, {cmd: turnout} is the outcome, {cmd: policy_edr} is the treatment, {cmd: policy_mail_in} and {cmd: policy_motor} are the covariates.
Here we change the texts and sizes of titles using {cmd: xtitle}, {cmd: ytitle}, and {cmd: title}. For more choice of text size style, click {it:{help textsizestyle:here}}.{p_end}

{p 6 6 2} For panel data with a staggered adoption design, we can distinguish the pre- and post-treatment periods for treated units by specifying {cmd:prepost}:
{p_end}
{phang2}. {stata panelview turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) prepost}{p_end}

{p 6 6 2}Use {cmd:bytiming} to sort units by the timing of receiving the treatment. We also use {cmd:label} and {cmd:size} options inside {cmd: legend} to specify label and size of the legend: {p_end}
{phang2}. {stata panelview turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) bytiming legend(label(1 "No EDR") label(2 "EDR") size(vsmall))}{p_end}


{pstd}Change the color schemes for the controls and treated using the {cmd:mycolor} option. For example, {cmd:PuBu} indicates light purple to blue:{p_end}
{phang2}. {stata panelview turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) bytiming mycolor(PuBu)}{p_end}


{pstd}Treatment: missing & switch on and off{p_end}

{pstd}Load example data (the state capacity dataset){p_end}
{phang2}. {stata sysuse capacity, clear}{p_end}
{phang2}. {stata panelview lnpop demo lngdp , i(country) t(year) type(treat) mycolor(Reds) xlabdist(3) ylabdist(10)}  {p_end}

{p 6 6 2}{cmd: demo} is a binary indicator of regime type. Use the {cmd:xlabdist} and {cmd:ylabdist} options to change the gaps between labels on the x- and y-axes. {p_end}


{pstd}Ignoring the Treatment Indicator{p_end}

{p 6 6 2}When we omit the treatment variable, the plot will show missing (the white area) and non-missing values only. This is essentially a plot for missing data: {p_end}
{phang2}. {stata panelview demo, i(ccode) t(year) type(treat) mycolor(Reds) xlabel(none) ylabel(none) ignoretreat}{p_end}

{p 6 6 2}Another way to achieve this goal is to set {cmd:type({ul:miss}ing)}: {p_end}
{phang2}. {stata panelview demo, i(ccode) t(year) type(missing) mycolor(Reds) xlabel(none) ylabel(none)}{p_end}


{pstd}More than Two Treatment Conditions{p_end}

{pstd}{cmd:panelview} supports panel data with more than 2 treatment levels. For example, we create a measure of regime type with three treatment levels: {p_end}
{phang2}. {stata gen demo2 = 0}{p_end}
{phang2}. {stata replace demo2 = -1 if polity2 < -0.5}{p_end}
{phang2}. {stata replace demo2 = 1 if polity2 > 0.5}{p_end}
{phang2}. {stata panelview Capacity demo2 lngdp, i(ccode) t(year) type(treat) xlabdist(3) ylabdist(11)}{p_end}

{p 6 6 2}If the number of treatment levels is greater than 5, then the treatment indicator will be regarded as a continuous variable. We can plot the continuous treatment variable by specifying {cmd:continuoustreat}. {p_end}


{pstd}Plotting Outcomes{p_end}

{pstd}Continuous Outcomes{p_end}
{phang2}. {stata sysuse turnout, clear}{p_end}
{phang2}. {stata panelview turnout policy_edr, i(abb) t(year) type(outcome) prepost ylabel(0 (25) 100, labsize(small)) xlabel(, labsize(small))}{p_end}

{p 6 6 2}The three different colors represent the pure control units, treated units in the pre-treatment periods, and treated units in the post-treatment period. {p_end}
{p 6 6 2}Different from a treatment status plot, an outcome plot does not allow {cmd:xlabdist} and {cmd:ylabdist}. Instead, {cmd:xlabel} and {cmd:ylabel} can be used to adjust looks of axis labels. {p_end}

{phang2}. {stata panelview turnout policy_edr, i(abb) t(year) type(outcome) bygroup xlabel(1920 (20) 2000)}{p_end}

{p 6 6 2}Because {cmd:bygroup} is invoked, {cmd: panelview} analyzes the data and automatically put each unit into different groups based on the changes of their treatment statuses,
e.g. (1) units always being treated, (2) units always under control, (3) units whose treatment status has changed.{p_end}

{pstd}Discrete Outcomes{p_end}
{phang2}. {stata sysuse simdata, clear}{p_end}
{phang2}. {stata panelview Y D, type(outcome) i(id) t(time) discreteoutcome xlabel(8 (2) 15) ylabel(0 (1) 2)}{p_end}

{p 6 6 2}Accommodate discrete variables by setting {cmd:discreteoutcome}. {p_end}


{pstd}Plotting any variable in a panel dataset{p_end}
{phang2}. {stata sysuse turnout, clear}{p_end}
{phang2}. {stata panelview turnout, i(abb) t(year) type(outcome) ylabel(0 (25) 100) legend(off)}{p_end}

{p 6 6 2}When we ignore the treatment status and apply {cmd:type(outcome)}, {cmd: panelview} can plot an outcome variable or an arbitrary variable in a panel dataset.{p_end}


{pstd}Plotting Y and D against time in the same graph{p_end}

{pstd}Plot average time series for all units{p_end}
{phang2}. {stata panelview turnout policy_edr, i(abb) t(year) xlabdist(7) type(bivariate) msize(*0.5) style(c b) ytitle("turnout") ytitle("policy_edr", axis(2)) legend(label(1 "turnout") label(2 "policy_edr"))}{p_end}

{p 6 6 2}Visualize the average outcome and average treatment status against time simultaneously by specifying {cmd:type(bivariate)}.
{cmd:style(c b)} means that, for the continuous outcome, we use a connected line plot; for the discrete treatment, we use a bar plot. We can specify the symbol size by {cmd:msize()} for connected line.
The left y axis indicates outcome label; the right y axis indicates treatment label. {p_end}

{pstd}Plot by each unit{p_end}
{phang2}. {stata panelview turnout policy_edr if abb >= 1 & abb <= 12, i(abb) t(year) xlabdist(10) type(bivar) byunit}{p_end}

{p 6 6 2}Plot D and Y for each unit against time in the same graph. {p_end}

{p 6 6 2}Use a line plot to represent (discrete) treatment status: {p_end}
{phang2}. {stata panelview turnout policy_edr if abb >= 1 & abb <= 12, i(abb) t(year) xlabdist(10) style(l l) type(bivar) byunit l1title("Y") r1title("D")}{p_end}

{p 6 6 2}To better visualize a discrete treatment whose value is sometimes zero, we use {cmd:style(l l)} to invoke line plots instead of bar plots.
Instead of using {cmd:ytitle}, we use {cmd:l1title} and {cmd:r1title} to label the left and right axes, respectively. {p_end}


{title:Authors}

      Hongyu Mou (Maintainer), hongyumou@g.ucla.edu
      University of California, Los Angeles
      
      Yiqing Xu, yiqingxu@stanford.edu
      Stanford University
  
      Please do not hesitate to send your comments or suggestions to the maintainer. 
      
      
{title:Citation}

      Mou, Hongyu & Yiqing Xu. "panelview for visualizing panel data: a Stata package." Available at Statistical Software Components (SSC) archive. 

      For more examples, click {browse "https://github.com/xuyiqing/panelview_stata"}.
