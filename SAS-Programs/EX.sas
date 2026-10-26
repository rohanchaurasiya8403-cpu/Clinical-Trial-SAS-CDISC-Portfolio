data Empty_ex;
    length
        STUDYID   $15
        DOMAIN    $2
        USUBJID   $25
        EXSEQ     8
        EXTRT     $200
        EXDOSE    8
        EXDOSU    $40
        EXDOSFRM  $80
        EPOCH     $40
        EXSTDTC   $16
        EXENDTC   $16
        EXSTDY    8
        EXENDY    8
    ;

    label
        STUDYID   = "Study Identifier"
        DOMAIN    = "Domain Abbreviation"
        USUBJID   = "Unique Subject Identifier"
        EXSEQ     = "Sequence Number"
        EXTRT     = "Name of Actual Treatment"
        EXDOSE    = "Dose"
        EXDOSU    = "Dose Units"
        EXDOSFRM  = "Dose Form"
        EPOCH     = "Epoch"
        EXSTDTC   = "Start Date/Time of Treatment"
        EXENDTC   = "End Date/Time of Treatment"
        EXSTDY    = "Study Day of Start of Treatment"
        EXENDY    = "Study Day of End of Treatment"
    ;
stop;
run;


data dosing_fixed;
	set raw.dosing;
	length startdate enddate $16. siteid $7 usubjid $25 studyid $15;
	by subject;

	if ^missing(startdt) then
		startdate=put(startdt, yymmdd10.);

	if missing(startdt) and missing(startmm) and missing(startdd) then
		startdate=put(startyy, 4.);

	if ^missing(enddt) then
		enddate=put(enddt, yymmdd10.);

	if missing(enddt) and missing(enddd) then
		enddate=cats(put(endyy, 4.), '-', put(endmm, z2.));

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
	else if subject >=300 then
		siteid='300';
	else if subject >=200 then
		siteid='200';
	else if subject >=100 then
		siteid='100';
	else
		siteid='NA';
	studyid='XYZ123';
	usubjid=cats(studyid, siteid, put(subject, 3.));

	if first.subject then
		exseq=0;
	exseq+1;
run;

data dosing_dm;
	merge dosing_fixed(in=a) sdtm.dm(keep=usubjid rfstdtc actarm);
	by usubjid;
	if a;
run;

data ex(keep=STUDYID DOMAIN USUBJID EXSEQ EXTRT EXDOSE EXDOSU EXDOSFRM 
		EPOCH EXSTDTC EXENDTC EXSTDY EXENDY);
	set empty_ex dosing_dm;

	/* STUDYID */
	DOMAIN='EX';

	/* USUBJID */
	/* EXSEQ */
	if trim(actarm)='Analgezia HCL 30 mg' then
		do;
			EXTRT='Analgezia HCL';
			EXDOSE=dailydose*30;
		end;
	else
		do;
			EXTRT='PLACEBO';
			EXDOSE=dailydose*0;
		end;
	EXDOSU='mg';
	EXDOSFRM='TABLET,COATED';
	EPOCH='TREATMENT';
	EXSTDTC=startdate;
	EXENDTC=enddate;

	if length(EXSTDTC)=10 then
		EXSTDY=(input(EXSTDTC, yymmdd10.)-input(RFSTDTC, yymmdd10.))+1;
	else
		EXSTDY=.;

	if length(EXENDTC)=10 then
		EXENDY=(input(EXENDTC, yymmdd10.)-input(RFSTDTC, yymmdd10.))+1;
	else
		EXENDY=.;
run;

proc sort data=ex out=sdtm.ex(label='Exposure');
by studyid usubjid exseq extrt exstdtc;
run;
