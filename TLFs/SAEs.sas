data serpt;
	set adam.adae;
	where SAFFL='Y' and TRTEMFL='Y' and AESER='Y';
run;

proc sql;
	create table ser1 as select AEBODSYS, AEDECOD, TRTA, count(distinct USUBJID) 
		as Count from serpt group by AEBODSYS, AEDECOD, TRTA;
quit;

proc sql;
	create table ser2 as select TRT01A as TRTA, count(distinct USUBJID) as Denom 
		from adam.adsl where SAFFL='Y' group by TRT01A;
quit;

proc sort data=ser1;
	by TRTA;
run;

proc sort data=ser2;
	by TRTA;
run;

data mixser;
	merge ser1 ser2;
	by TRTA;
	pct=(Count/denom)*100;
	score=cats(put(count, 2.), ' (', put(pct, 5.1), '%)');
	keep AEBODSYS AEDECOD TRTA SCORE;
run;

proc sql;
	create table ser3 as select 'Total' as TRTA length=30, AEBODSYS, AEDECOD, 
		count(distinct USUBJID) as Count from serpt group by AEBODSYS, AEDECOD;
quit;

proc sql;
	create table dbad as select count(distinct USUBJID) as dbad from adam.adsl 
		where SAFFL='Y';
quit;

data mixserb;
	if _n_=1 then
		set dbad;
	set ser3;
	pct=(count/dbad)*100;
	score=cats(put(count, 2.), ' (', put(pct, 5.1), '%)');
	keep AEBODSYS AEDECOD TRTA SCORE;
run;

data comb_ser;
	set mixser mixserb;
run;

proc sort data=comb_ser;
	by AEBODSYS AEDECOD;
run;

proc transpose data=comb_ser out=finalsera(drop=_name_);
	by AEBODSYS AEDECOD;
	id TRTA;
	var Score;
run;

data sera_report;
	set finalsera;
	length SECTION $200;
	SECTION=AEBODSYS;
	PARAM=AEDECOD;
	keep SECTION PARAM 'Analgezia HCL 30 mg'n Placebo Total;
run;

/*------------------------------------------------------------*
| Sort by SOC and Preferred Term
 *------------------------------------------------------------*/
proc sort data=sera_report;
	by SECTION PARAM;
run;

/*------------------------------------------------------------*
| Final SOC / Preferred Term Report
 *------------------------------------------------------------*/
title 'Serious Adverse Events (SAEs) by System Organ Class (SOC) and Preferred Term (PT)';

proc report data=sera_report nowd headline headskip;
	columns SECTION PARAM 'Analgezia HCL 30 mg'n Placebo Total;
	define SECTION / group noprint;
	define PARAM / display "System Organ Class / Preferred Term" 
		style(column)=[just=left];
	define 'Analgezia HCL 30 mg'n / display "Analgezia HCL 30 mg" 
		style(column)=[just=center];
	define Placebo / display "Placebo" style(column)=[just=center];
	define Total / display "Total" style(column)=[just=center];

	/* Create SOC break header */
	break before SECTION / skip;
	compute before SECTION;
		line SECTION $200.;
	endcomp;
run;

title;