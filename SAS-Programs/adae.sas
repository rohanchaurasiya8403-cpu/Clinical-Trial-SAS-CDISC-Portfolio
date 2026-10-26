proc sql;

create table empty_adae
(
STUDYID char(15) label='Study Identifier',
USUBJID char(25) label='Unique Subject Identifier',
SITEID char(7) label='Study Site Identifier',
COUNTRY char(3) label='Country',

AESEQ num label='Sequence Number',

AGE num label='Age',
AGEGR1N num label='Pooled Age Group 1 (N)',
AGEGR1 char(20) label='Pooled Age Group 1',

SEX char(1) label='Sex',

TRTAN num label='Actual Treatment (N)',
TRTA char(40) label='Actual Treatment',

AETERM char(200) label='Reported Term for the Adverse Event',
AEDECOD char(200) label='Dictionary-Derived Term',
AEBODSYS char(200) label='Body System or Organ Class',

ASTDT num format=date9.
      label='Start Date/Time of Adverse Events',

AENDT num format=date9.
      label='End Date/Time of Adverse Events',

ASTDY num label='Study Day of Start of Adverse Event',
AENDY num label='Study Day of End of Adverse Event',

AESEV char(40) label='Severity/Intensity',
AESEVN num label='Severity/Intensity (N)',

AESER char(40) label='Serious Event',

AEACN char(40) label='Action Taken with Study Treatment',

AEREL char(40) label='Causality',
AERELN num label='Causality (N)',

CQ01NAM char(200) label='CQ 01 Name',

RELGR1 char(15) label='Pooled Causality Group 1',
RELGR1N num label='Pooled Causality Group 1 (N)',

TRTEMFL char(1) label='Treatment Emergent Flag',

SAFFL char(1) label='Safety Population Flag'

);

quit;



proc format; 

invalue aes 'MILD'=1 'MODERATE'=2 'SEVERE'=3; 

invalue aer 'NOT RELATED'=0 'POSSIBLY RELATED'=1 'PROBABLY RELATED'=2; 

run; 

proc sql;
create table ae_adsl as
	select 	b.studyid, b.usubjid, b.siteid, b.country, b.age, b.agegr1, b.agegr1n, b.sex, b.trt01a, b.trt01an,
			a.aeseq, a.aeterm, a.aedecod, a.aebodsys, a.aestdtc, aeendtc,
			b.trtsdt, b.trtedt,
			aeser, aesev, aeacn, aerel, saffl
		from sdtm.ae a
		left join adam.adsl b
		on a.usubjid = b.usubjid
		order by usubjid, Aeseq;
;
quit;


proc format;
	value $AESN 'MILD'=1 'MODERATE'=2 'SEVERE'=3;	
run;


Data ADAE(keep=STUDYID USUBJID SITEID COUNTRY AESEQ AGE AGEGR1N AGEGR1 SEX TRTAN TRTA AETERM 
AEDECOD AEBODSYS ASTDT AENDT ASTDY AENDY AESEV AESEVN AESER AEACN AEREL AERELN CQ01NAM RELGR1
RELGR1N TRTEMFL SAFFL);
	Set empty_adae ae_adsl;
	TRTAN=TRT01AN;
	TRTA=trim(TRT01A);
	ASTDT=INPUT(AESTDTC, yymmdd10.);
	AENDT=INPUT(AEENDTC, yymmdd10.);
	
	if ^missing(astdt) and astdt < trtsdt then
	    ASTDY=astdt - trtsdt;
        else if ^missing(astdt) then 
         ASTDY=astdt - trtsdt +1;
        else ASTDY=.;
   if ^missing(aendt) and aendt < trtsdt then
	    AENDY=aendt - trtedt;
        else if ^missing(aendt) then 
         AENDY=aendt - trtsdt +1;
        else AENDY=.;
	if index(aedecod, 'PAIN')>0 or index(aedecod, 'ACHE')>0  then
		CQ01NAM='PAIN EVENT';
	else
		CQ01NAM=' ';

	AESEVN=input(put(AESEV, AESN.),best.);
	If AEREL='NOT RELATED' then
		AERELN=0;
	else if AEREL='POSSIBLY RELATED' then
		AERELN=1;
	else if AEREL='PROBABLY RELATED' then
		AERELN=2;
	

	If AEREL='NOT RELATED' Then
		do;
			RELGR1='NOT RELATED';
			RELGR1N=0;
		end;
	else
		do;
			RELGR1='RELATED';
			RELGR1N=1;
		end;
	if astdt >=trtsdt and astdt <= trtedt then
		TRTEMFL='Y';
	else
		TRTEMFL='';
		
run;

Data adam.ADAE;
set adae;
run;
