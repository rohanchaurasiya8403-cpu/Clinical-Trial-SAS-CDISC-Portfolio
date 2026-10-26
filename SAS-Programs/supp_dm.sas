data empty_suppdm;
	length STUDYID   $15 RDOMAIN   $2 USUBJID   $25 IDVAR     $8 IDVARVAL  $200 
		QNAM      $8 QLABEL    $40 QVAL      $200 QORIG     $20 QEVAL     $8;
	label STUDYID="Study Identifier" RDOMAIN="Related Domain Abbreviation" 
		USUBJID="Unique Subject Identifier" IDVAR="Identifying Variable" 
		IDVARVAL="Identifying Variable Value" QNAM="Qualifier Variable Name" 
		QLABEL="Qualifier Variable Label" QVAL="Data Value" QORIG="Origin" 
		QEVAL="Evaluator";
	stop;
run;

data empty_suppdm;
	set work.empty_suppdm;
run;

data suppDM(keep=STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG 
		QEVAL);
	set empty_suppdm raw.demographic;
	STUDYID='XYZ123';
	RDOMAIN='DM';

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
	usubjid=cats(studyid, siteid, put(subject, 3.));
	IDVAR='';
	IDVARVAL='';
	QORIG='CRF';
	QEVAL='';

	if ^missing(orace) then
		do;
			QNAM='ORACE';
			QLABEL='Other Race';
			QVAL=trim(orace);
			output;
		end;

	if ^missing(randdt) then
		do;
			QNAM='RANDTC';
			QLABEL='Randomization Date';
			QVAL=put(randdt, yymmdd10.);
			output;
		end;
	
run;

proc sort data=suppDM out=sdtm.suppdm(label='Supplemental Qualifiers for Demographics');
by Studyid Usubjid;
run;