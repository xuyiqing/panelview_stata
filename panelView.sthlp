{smcl}
{* *! version 0.1 21aug2021}{...}
{cmd:help panelView}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:panelView} {hline 2}}Visualizing Panel Data {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 18 2}
{cmdab:panelView} {it:{help varname:Y D}} {it:{help varlist:X}}
{ifin} 
{cmd:,} {opt I(varname)} {opt T(varname numeric)} {opt TYPE(string)}
[{it:options}]

{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Main}
{synopt:{opt Y D X}}{it:{help varlist}} of outcome variable, treatment variable, and covariates. Including covariates may change the plot because of missing values in these covariates{p_end}
{synopt:{opt i(varname)}}Specify the unit (group) indicator{p_end}
{synopt:{opt t(varname numeric)}}Specify the time indicator{p_end}
{synopt:{opt type(string)}}Use {cmd:type(treat)} to plot treatments, {cmd:type(outcome)} to plot outcomes, and {cmd:type(bivar)} or {cmd:type(bivariate)} to plot outcome and treatment against
time in the same graph{p_end}

{syntab:Advanced}
{synopt:{opt [if] [in]}}If any variable not included in the {cmd:varlist} or {cmd: i()} / {cmd: t()} appears in the {cmd:if}/ {cmd:in} subcommand, we should add this variable into the {cmd:varlist} following {cmd:panelView} command{p_end}
{synopt:{opt discreteoutcome}}Plot the discrete outcome variable{p_end}
{synopt:{opt bytiming}}Sort units by the timing of receiving the treatment (then by the total number of periods exposed to the treatment){p_end}
{synopt:{opt mycol:or(string)}}Change the color schemes; click {it:{help colorpalette:here}} for sequential colors (3-9 colors). Default is {cmd:Blues}{p_end} 
{synopt:{opt pre:post(off)}}Not distinguish the pre- and post-treatment periods for treated units{p_end}
{synopt:{opt continuoustreat}}Plot the continuous treatment variable. If it is combined with {cmd: type(outcome)}, the figure would be the same as ignoring treatment{p_end}
{synopt:{opt xlabdist(integer)}}Change gaps between labels on the x-axis.{cmd: ylabdist} Change gaps between labels on the y-axis. Default is {cmd: 1}{p_end}
{synopt:{opt ignoretreat}}Omit the treatment indicator{p_end}
{synopt:{opt bygroup}}Put each unit into different treatment groups, then plot respectively{p_end}
{synopt:{opt style()}}To visualize connected line ({cmd:connected} or {cmd:c}), line ({cmd:line} or {cmd:l}), or bar ({cmd:bar} or {cmd:b}) plot rather than the default. The first element defines the outcome style, and the second defines the treatment style{p_end}
{synopt:{opt byunit}}Plot D and Y against time by each unit in the same graph in {cmd:type(bivar)}{p_end}
{synopt:{opt theme(bw)}}Use the black and white theme (default when specified {cmd:type(bivar)}){p_end}
{synopt:{opt lwd()}}Set the line width in {cmd:type(bivar)}. Default is {cmd:medium}{p_end}
{synopt:{opt *}}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
  {p_end}

{title:Description}

{pstd}
{opt panelView} has two main functionalities: {p_end}
{pstd}
(1) it visualizes the treatment and missing-value statuses of each observation in a panel/time-series-cross-sectional (TSCS) dataset; {p_end}
{pstd}
(2) it plots the outcome variable (either continuous or discrete) in a time-series fashion. {p_end}
{pstd}
We develop this package in the belief that it is always a good idea to understand your raw data better before conducting statistical analyses.{p_end}

{title:Examples}

{pstd}Load example data (the {cmd:turnout} dataset){p_end}
{p 4 8 2}{stata "sysuse turnout":. sysuse turnout}{p_end}

{pstd}Basic syntax{p_end}
{p 4 8 2}{stata "panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) prepost(off)":. panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) prepost(off)}{p_end}

{p 6 6 2}for DID-type TSCS data with a dichotomous treatment indicator, we can stop distinguish the pre- and post-treatment periods for treated units by specifying {cmd:prepost(off)}. 
{p_end}

{p 4 8 2}{stata "panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) prepost(off) bytiming":. panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) prepost(off) bytiming}{p_end}

{p 6 6 2}use the {cmd:bytiming} option to sort units by the timing of receiving the treatment. {p_end}

{pstd}Distinguish the pre- and post-treatment periods for treated units by not specifying {cmd:prepost(off)}{p_end}
{p 4 8 2}{stata "panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat)":. panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat)}{p_end}

{pstd}Change the color schemes for the controls and treated using the {cmd:mycolor} option. For example, {cmd:PuBu} indicates light purple to blue{p_end}
{p 4 8 2}{stata "panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) mycolor(PuBu) bytiming":. panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(treat) mycolor(PuBu) bytiming}{p_end}


{pstd}Treatment: missing & switch on and off{p_end}

{pstd}Load example data (the {cmd:capacity} dataset){p_end}
{p 4 8 2}{stata "sysuse capacity":. sysuse capacity}{p_end}
{p 4 8 2}{stata "panelView lnpop demo lngdp , i(country) t(year) type(treat) mycolor(Reds) prepost(off) xlabdist(3) ylabdist(10)":. panelView lnpop demo lngdp , i(country) t(year) type(treat) mycolor(Reds) prepost(off) xlabdist(3) ylabdist(10)}  {p_end}

{p 6 6 2}For a panel dataset in which the treatment may switch on and off, we do not differentiate between pre- and post-treatment statuses. Use the {cmd:xlabdist} and {cmd:ylabdist} option to change the gaps between labels on the x- and y-axes. {p_end}


{pstd}Ignoring Treatment Conditions{p_end}

{pstd}Load example data (the {cmd:capacity} dataset){p_end}
{p 4 8 2}{stata "sysuse capacity":. sysuse capacity}{p_end}
{p 4 8 2}{stata "panelView demo, i(ccode) t(year) type(treat) mycolor(Reds) xlabel(none) ylabel(none) ignoretreat":. panelView demo, i(ccode) t(year) type(treat) mycolor(Reds) xlabel(none) ylabel(none) ignoretreat}{p_end}

{p 6 6 2}Omit the treatment variable, in which case, the plot will show missing (the white area) and non-missing values only. {p_end}
{p 6 6 2}If the treatment indicator has only 1 level, then treatment status will not be shown on the plot, which is the same as {cmd:ignoretreat}. {p_end}
{p 6 6 2}If the treatment indicator has more than 2 treatment levels or is a continuous variable, then treatment status will not be shown on the {cmd:type(outcome)} plot, the same as {cmd:ignoretreat}. {p_end}


{pstd}More than Two Treatment Conditions{p_end}

{pstd}{cmd:panelView} supports TSCS data with more than 2 treatment levels. For example, we create a measure of regime type with three treatment levels: {p_end}
{pstd}Load example data (the {cmd:capacity} dataset){p_end}
{p 4 8 2}{stata "sysuse capacity":. sysuse capacity}{p_end}
{p 4 8 2}{stata "gen demo2 = 0":. gen demo2 = 0}{p_end}
{p 4 8 2}{stata "replace demo2 = -1 if polity2 < -0.5":. replace demo2 = -1 if polity2 < -0.5}{p_end}
{p 4 8 2}{stata "replace demo2 = 1 if polity2 > 0.5":. replace demo2 = 1 if polity2 > 0.5}{p_end}
{p 4 8 2}{stata "panelView Capacity demo2 lngdp, i(ccode) t(year) type(treat) xlabdist(3) ylabdist(11) prepost(off)":. panelView Capacity demo2 lngdp, i(ccode) t(year) type(treat) xlabdist(3) ylabdist(11) prepost(off)}{p_end}

{p 6 6 2}If the number of treatment levels is greater than 5, then the treatment indicator will be regarded as a continuous variable. {p_end}
{p 6 6 2}We can plot the continuous treatment variable by {cmd:continuoustreat}. Note that {cmd:continuoustreat} need to combine with {cmd:prepost(off)}. {p_end}


{pstd}Plotting Outcomes{p_end}

{pstd}Continuous Outcomes{p_end}
{p 4 8 2}{stata "sysuse turnout":. sysuse turnout}{p_end}
{p 4 8 2}{stata "panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(outcome) ylabel(0 (25) 100)":. panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(outcome) ylabel(0 (25) 100)}{p_end}

{p 6 6 2}We paint the period right before when the treatment begin as treated period. Different with {cmd:type(treat)}, {cmd:type(outcome)} does not need {cmd:xlabdist} and {cmd:ylabdist}. If needed, we should use  {cmd:xlabel} and {cmd:ylabel}. {p_end}

{p 4 8 2}{stata "panelView turnout policy_edr , i(abb) t(year) type(outcome) bygroup xlabel(1920 (20) 2000) ":. panelView turnout policy_edr, i(abb) t(year) type(outcome) bygroup xlabel(1920 (20) 2000)}{p_end}

{p 6 6 2}Option {cmd:bygroup} will analyze the data and automatically put each unit into different groups, e.g. (1) Always treated, (2) always in control, (3) treatment status changed. {p_end}

{pstd}Discrete Outcomes{p_end}
{p 4 8 2}{stata "sysuse simdata":. sysuse simdata}{p_end}
{p 4 8 2}{stata "panelView Y D, type(outcome) i(id) t(time) discreteoutcome xlabel(8 (2) 15) ylabel(0 (1) 2)":. panelView Y D, type(outcome) i(id) t(time) discreteoutcome xlabel(8 (2) 15) ylabel(0 (1) 2)}{p_end}
{p 6 6 2}Accommodate discrete variables by setting {cmd:discreteoutcome}. {p_end}


{pstd}Plotting any variable in a panel dataset{p_end}

{p 4 8 2}{stata "sysuse turnout":. sysuse turnout}{p_end}
{p 4 8 2}{stata "panelView turnout policy_edr, i(abb) t(year) type(outcome) ylabel(0 (25) 100) ignoretreat":. panelView turnout policy_edr, i(abb) t(year) type(outcome) ylabel(0 (25) 100) ignoretreat}{p_end}

{p 6 6 2}Plot an outcome variable (or any variable) in a panel dataset by {cmd:type(outcome)} and {cmd:ignoretreat}. {p_end}


{pstd}Plotting Y and D against time in the same graph{p_end}

{pstd}Plot average time series for all units{p_end}
{p 4 8 2}{stata "sysuse turnout":. sysuse turnout}{p_end}
{p 4 8 2}{stata "panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) xlabdist(7) type(bivariate) ylabel(40 (10) 70) ylabel(0 (0.1) 0.5, axis(2)) msize(*0.5) style(c b)":. panelView turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) xlabdist(7) type(bivariate) ylabel(40 (10) 70) ylabel(0 (0.1) 0.5, axis(2)) msize(*0.5) style(c b)}{p_end}

{p 6 6 2}Visualize time series of the mean outcome and treatment in one figure by {cmd:type(bivar)}. {cmd:style(c b)} means that, for continuous treatment, we use connected line plot; for discrete treatment, we use bar plot. {p_end} 
{p 6 6 2}The left y axis indicates outcome label, and the right y axis indicates treatment label. {p_end}

{pstd}Plot by each unit{p_end}
{p 4 8 2}{stata "sysuse turnout":. sysuse turnout}{p_end}
{p 4 8 2}{stata "panelView turnout policy_edr if abb >= 1 & abb <= 12, i(abb) t(year) xlabdist(10) type(bivar) byunit":. panelView turnout policy_edr if abb >= 1 & abb <= 12, i(abb) t(year) xlabdist(10) type(bivar) byunit}{p_end}

{p 6 6 2}Plot D and Y for each unit against time in the same graph. {p_end}

{pstd}Line the discrete treatment{p_end}
{p 4 8 2}{stata "sysuse turnout":. sysuse turnout}{p_end}
{p 4 8 2}{stata "panelView turnout policy_edr if abb >= 1 & abb <= 12, i(abb) t(year) xlabdist(10) style(line) type(bivar) byunit":. panelView turnout policy_edr if abb >= 1 & abb <= 12, i(abb) t(year) xlabdist(10) style(line) type(bivar) byunit}{p_end}

{p 6 6 2}To visualize the zero level with discrete treatment, we add {cmd:style(line)} to plot treatment lines instead of bars.{p_end} 

{title:Authors}

      Yiqing Xu, yiqingxu@stanford.edu
      Stanford
      
      Hongyu Mou, muhongyu@pku.edu.cn
      PKU