data empty_dm;
	length STUDYID   $15 DOMAIN    $2 USUBJID   $25 SUBJID    $7 RFSTDTC   $16 
		RFENDTC   $16 RFXSTDTC  $16 RFXENDTC  $16 RFICDTC   $16 RFPENDTC  $16 
		DTHDTC    $16 DTHFL     $2 SITEID    $7 BRTHDTC   $16 AGE 8 AGEU      $10 
		SEX       $2 RACE      $80 ARMCD     $8 ARM       $40 ACTARMCD  $8 
		ACTARM    $40 ARMNRS    $40 ACTARMUD  $40 COUNTRY   $3;
	label STUDYID="Study Identifier" DOMAIN="Domain Abbreviation" 
		USUBJID="Unique Subject Identifier" SUBJID="Subject Identifier for the Study" 
		RFSTDTC="Subject Reference Start Date/Time" 
		RFENDTC="Subject Reference End Date/Time" 
		RFXSTDTC="Date/Time of First Study Treatment" 
		RFXENDTC="Date/Time of Last Study Treatment" 
		RFICDTC="Date/Time of Informed Consent" 
		RFPENDTC="Date/Time of End of Participation" DTHDTC="Date/Time of Death" 
		DTHFL="Subject Death Flag" SITEID="Study Site Identifier" 
		BRTHDTC="Date/Time of Birth" AGE="Age" AGEU="Age Units" SEX="Sex" RACE="Race" 
		ARMCD="Planned Arm Code" ARM="Description of Planned Arm" 
		ACTARMCD="Actual Arm Code" ACTARM="Description of Actual Arm" 
		ARMNRS="Reason Arm and/or Actual Arm is Null" 
		ACTARMUD="Description of Unplanned Actual Arm" COUNTRY="Country";
	stop;
run;

proc format;
	value sex 1='M' 2='F' .='U';
	value race 1='WHITE' 2='BLACK OR AFRICAN AMERICAN' 3='ASIAN';
	value armcd 0='PLACEBO' 1='ALG123';
	value arm 0='Placebo' 1='Analgezia HCL 30 mg';
run;

data demog;
	set raw.demographic;
	length siteid $7 Studyid $15 usubjid $25;

	if subject >=700 then
		siteid='700';
	else if subject >=600 then
		siteid='600';
	else if subject >=500 then
		siteid='500';
	else if subject >=400 then
		siteid='400';
	else if subject >=300 then
		siteid='300';
	else if subject >=200 then
		siteid='200';
	else if subject >=100 then
		siteid='100';
	else
		siteid='NA';
	STUDYID='XYZ123';
	USUBJID=cats(studyid, siteid, put(subject, 3.));
run;

proc sort data=demog;
	by subject;
run;

proc sort data=raw.dosing;
	by subject startdt enddt;
run;

data fdosing;
	length firstdosedt lastdosedt 8;
	set raw.dosing;
	by subject;
	format firstdosedt lastdosedt yymmdd10.;
	retain firstdosedt lastdosedt;

	if first.subject then
		do;
			firstdosedt=.;
			lastdosedt=.;
		end;
	firstdosedt=min(startdt, firstdosedt);
	lastdosedt=max(enddt, lastdosedt);

	if last.subject;
run;

data dosing_fixed;
	set raw.dosing;
	length startdate enddate $16;

	if ^missing(startdt) then
		startdate=put(startdt, yymmdd10.);

	if missing(startdt) and missing(startmm) and missing(startdd) then
		startdate=put(startyy, 4.);

	if ^missing(enddt) then
		enddate=put(enddt, yymmdd10.);

	if missing(enddt) and missing(enddd) then
		enddate=cats(put(endyy, 4.), '-', put(endmm, z2.));
run;

proc sql;
	create table dosing_dates as select subject, min(startdate) as firstdosedt, 
		max(enddate) as lastdosedt from dosing_fixed group by subject;
quit;

data demog_dosing;
	merge demog(in=indemog) dosing_dates;
	by subject;

	if indemog=1;
run;

libname sdtm "/home/u64411821/Clinical/SDTM";

data DM(keep=STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC 
		RFICDTC RFPENDTC DTHDTC DTHFL SITEID BRTHDTC AGE AGEU SEX RACE ARMCD ARM 
		ACTARMCD ACTARM ARMNRS ACTARMUD COUNTRY);
	set work.empty_dm demog_dosing(rename=(race=_race));
	DOMAIN='DM';
	SUBJID=put(subject, 3.);
	RFSTDTC=put(randdt, yymmdd10.);
	RFENDTC=lastdosedt;
	RFXSTDTC=firstdosedt;
	RFXENDTC=lastdosedt;
	RFICDTC=put(icdate, yymmdd10.);
	RFPENDTC=put(lastdoc, yymmdd10.);
	DTHDTC='';
	DTHFL='';
	BRTHDTC=put(dob, yymmdd10.);

	if length(RFSTDTC)=10 then
		Age=floor((input(RFSTDTC, yymmdd10.)-input(Brthdtc, yymmdd10.))/365.25);
	else if length(RFSTDTC)=4 then
		AGE=floor((input(RFSTDTC, 4.)-year(input(BRTHDTC, yymmdd10.))));
	else
		AGE=.;

	if ^missing(AGE) then
		AGEU='YEARS';
	else
		AGEU='';
	SEX=put(gender, sex.);
	RACE=put(_race, race.);
	ARMCD=put(trt, armcd.);
	ARM=put(trt, arm.);
	ACTARMCD=put(trt, armcd.);
	ACTARM=put(trt, arm.);
	ARMNRS='';
	ACTARMUD='';
	COUNTRY='USA';
run;

proc sort data=DM out=sdtm.DM(label='Demographics');
	by studyid usubjid subjid;
run;