libname ADAM  '/home/u64411821/Clinical/ADAM' ;

proc sql;
create table  empty_adsl_shell   
(STUDYID char (15)	label="Study Identifier",
USUBJID char(25) label="Unique Subject Identifier",
SUBJID	char (7) label=	"Subject Identifier for the Study",
SITEID char (7)	label="Study Site Identifier",
COUNTRY	char (3) label="Country",
BRTHDT	int label="Date of Birth",
AGE	int label="Age",
AGEU char (5) label="Age Units",
AGEGR1 char (40) label="Pooled Age Group 1",
AGEGR1N	int label="Pooled Age Group 1 (N)",
SEX	char(1) label=	"Sex",
RACE char (40)	label="Race",
RACEOTH	char (40)	label="Race, Other, Specify",
RANDDT	int label="Date of Randomization",
TRTSDT	int label="Date of First Exposure to Treatment",
TRTEDT	int label="Date of Last Exposure to Treatment",
ARM	char(40) label="Description of Planned Arm",
TRT01P	char(40) label="Planned Treatment for Period 01",
TRT01A	char (40)	label= "Actual Treatment for Period 01",
TRT01PN	int label="Planned Treatment for Period 01 (N)",
TRT01AN	int label="Actual Treatment for Period 01 (N)",
ITTFL char(1) label="Intent-To-Treat Population Flag",
SAFFL char(1)	label="Safety Population Flag",
RESPFL	char (1)	label="Efficacy Responder Flag",
TRTSDTF	char(1)	label="Date of First Exposure Imput. Flag",
TRTEDTF	char(1) label=	"Date of Last Exposure Imput. Flag",
RANDFL	char(1)	label="Randomized Population Flag"
);
quit;



/* Transpose 2 tables- SUPPDM  XP */
proc transpose data=sdtm.suppdm out=supp_trans(drop=_:) ;
by usubjid;
var QVAL;
Id QNAM;
idlabel Qlabel;
run;

proc transpose data= sdtm.xp out=xp_trans (drop=_:);
by usubjid;
var xpstresn;
id visit;
idlabel visit;
run;


/*merge data to get info from SDTM.DM, SDTM.XP=chg_base, SDTM.SUPPDM=transposed suppdm  */
proc sql;
create table suppdm_dm_xp as 

select  a.* ,b.randtc, b.orace, c.resp_eff_fl

from sdtm.dm as a 
left join  supp_trans as b 
on a.usubjid=b.usubjid

left join chg_base as c 
on a.usubjid=c.usubjid
;
quit;


data chg_base;
	set xp_trans;

	if ^missing("month 6"n) and ^missing(baseline) then
		chg="month 6"n - baseline;
	else
		chg=.;

	if ^missing(chg) and chg<=-2 then
		resp_eff_fl="Y";
	else if missing(chg) then
		resp_eff_fl=" ";
	else
		resp_eff_fl="N";
run;

/* MACRO program to create to tranpose and chg from baseline */options mcompilenote=all;
%macro trans_chg_base (lib= , indataset=);

proc transpose data= &lib..&indataset out=&indataset._trans (drop=_:);
by usubjid;
var &indataset.stresn;
id visit;
idlabel visit;
run;

data &indataset._chg_base;
set &indataset._trans;
 
   if ^missing("month 6"n) and ^missing(baseline) then
    chg= "month 6"n - baseline;
    
    else chg=.;
    
    run;
  %mend;  
  
  options mprint symbolgen;
  %trans_chg_base (lib=sdtm, indataset=xp)


/*merge data to get info from SDTM.DM, SDTM.XP=chg_base, SDTM.SUPPDM=transposed suppdm  */
proc sql;
	create table suppdm_dm_xp as select a.* , b.randtc, b.orace, c.resp_eff_fl 
		from sdtm.dm as a left join supp_trans as b on a.usubjid=b.usubjid left join 
		chg_base as c on a.usubjid=c.usubjid;
quit;


/* Push the above info into empty shell */

data adsl(keep=STUDYID USUBJID SUBJID SITEID COUNTRY BRTHDT AGE AGEU AGEGR1 
		AGEGR1N SEX RACE RACEOTH RANDDT TRTSDT TRTEDT ARM TRT01P TRT01A TRT01PN 
		TRT01AN ITTFL SAFFL RESPFL TRTSDTF TRTEDTF RANDFL);
	set empty_adsl_shell suppdm_dm_xp;
format brthdt RANDDT TRTSDT TRTEDT yymmdd10.; 
	BRTHDT=input(BRTHDTC, YYMMDD10.);

	if AGE < 55 then
		do;
			AGEGR1='<55 Years';
			AGEGR1N=1;
		end;
	else
		do;
			AGEGR1='>=55 Years';
			AGEGR1N=2;
		end;
	RACEOTH=trim(orace);
	RANDDT=input(RANDTC, yymmdd10.);

	if length(RFXSTDTC)< 10 then
		do;
			TRTSDT=input(rfstdtc, yymmdd10.);
			TRTSDTF='M';
		end;
	else
		TRTSDT=input(RFXSTDTC, yymmdd10.);

	if length(RFXENDTC)< 10 then
		do;
			TRTEDT=input(RFPENDTC, yymmdd10.);
			TRTEDTF='D';
		end;
	else
		TRTEDT=input(RFXENDTC, yymmdd10.);
	TRT01P=trim(ARM);
	TRT01A=trim(ARM);

	if trim(arm)='Placebo' then
		do;
			TRT01PN=0;
			TRT01AN=0;
		end;
	else
		do;
			TRT01PN=1;
			TRT01AN=1;
		end;

	if ^missing(RANDDT) then
		ITTFL='Y';
	else
		ITTFL='N';

	if ^missing(TRTSDT) then
		SAFFL='Y';
	else
		SAFFL='N';
	RESPFL=resp_eff_fl;

	if ^missing(RANDDT) then
		RANDFL='Y';
	else
		RANDFL='N';
run;


/*Save the ADSL dataset into permenent library ADaM  */
data adam.adsl;
set work.adsl;
run;

proc export data=adam.adsl outfile='/home/u64411821/LWRWM6/adslo.csv' dbms=csv replace;
run;

