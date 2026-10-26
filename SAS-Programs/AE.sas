data empty_ae;
data empty_ae;
	length STUDYID    $15 DOMAIN     $2 USUBJID    $25 AESEQ 8 AETERM     $200 
		AELLT      $200 AELLTCD 8 AEDECOD    $200 AEPTCD 8 AEHLT      $200 AEHLTCD 8 
		AEHLGT     $200 AEHLGTCD 8 AEBODSYS   $200 AEBDSYCD 8 AESOC      $200 AESOCCD 
		8 AESEV      $20 AESER      $2 AEACN      $40 AEREL      $40 AESLIFE    $2 
		EPOCH      $40 AESTDTC    $16 AEENDTC    $16 AESTDY 8 AEENDY 8;
	label STUDYID="Study Identifier" DOMAIN="Domain Abbreviation" 
		USUBJID="Unique Subject Identifier" AESEQ="Sequence Number" 
		AETERM="Reported Term for the Adverse Event" AELLT="Lowest Level Term" 
		AELLTCD="Lowest Level Term Code" AEDECOD="Dictionary-Derived Term" 
		AEPTCD="Preferred Term Code" AEHLT="High Level Term" 
		AEHLTCD="High Level Term Code" AEHLGT="High Level Group Term" 
		AEHLGTCD="High Level Group Term Code" AEBODSYS="Body System or Organ Class" 
		AEBDSYCD="Body System or Organ Class Code" AESOC="Primary System Organ Class" 
		AESOCCD="Primary System Organ Class Code" AESEV="Severity" 
		AESER="Serious Event" AEACN="Action Taken with Study Treatment" 
		AEREL="Causality" AESLIFE="Is Life Threatening" EPOCH="Epoch" 
		AESTDTC="Start Date/Time of Adverse Event" 
		AEENDTC="End Date/Time of Adverse Event" 
		AESTDY="Study Day of Start of Adverse Event" 
		AEENDY="Study Day of End of Adverse Event";
	stop;
run;

run;

proc format;
	value aesev 1='MILD' 2='MODERATE' 3='SEVERE';
	value aerel 1='NOT RELATED' 2='POSSIBLY RELATED' 3='PROBABLY RELATED';
	value aeacn 1='DRUG INTERRUPTED' 2='DOSE REDUCED' 3='DOSE INCREASED' 
		4='DOSE NOT CHANGED' 5='UNKNOWN';
run;

data adverse;
	set raw.adverse;
	length siteid $7 studyid $15 usubjid $25;
	by subject;

	if subject > 700 then
		siteid='700';
	else if subject > 600 then
		siteid='600';
	else if subject > 500 then
		siteid='500';
	else if subject > 400 then
		siteid='400';
	else if subject > 300 then
		siteid='300';
	else if subject > 300 then
		siteid='300';
	else if subject > 200 then
		siteid='200';
	else if subject > 100 then
		siteid='100';
	else
		siteid='NA';
	studyid='XYZ123';
	usubjid=cats(studyid, siteid, put(subject, 3.));

	if first.subject then
		AESEQ=0;
	AESEQ+1;
run;

data adverse_dm;
	merge adverse(in=a) sdtm.dm(in=b keep=usubjid rfstdtc);
	by usubjid;

	if a;
run;

data ae(keep=STUDYID DOMAIN USUBJID AESEQ AETERM AELLT AELLTCD AEDECOD AEPTCD 
		AEHLT AEHLTCD AEHLGT AEHLGTCD AEBODSYS AEBDSYCD AESOC AESOCCD AESEV AESER 
		AEACN AEREL AESLIFE EPOCH AESTDTC AEENDTC AESTDY AEENDY);
	set empty_ae adverse_dm(rename=(aesev=_aesev aerel=_aerel));

	/* STUDYID */
	DOMAIN='AE';

	/* USUBJID */
	/* AESEQ */
	AETERM=strip(aetext);
	AELLT=strip(llterm);
	AELLTCD=input(lltcode, best.);
	AEDECOD=strip(prefterm);
	AEPTCD=input(ptcode, best.);
	AEHLT=strip(hlterm);
	AEHLTCD=input(hltcode, best.);
	AEHLGT=strip(hlgterm);
	AEHLGTCD=input(hlgtcod, best.);
	AEBODSYS=strip(bodysys);
	AEBDSYCD=input(soccode, best.);
	AESOC=strip(bodysys);
	AESOCCD=input(soccode, best.);
	AESEV=put(_aesev, aesev.);
	AESER=strip(serious);
	AEACN=put(aeaction, aeacn.);
	AEREL=put(_aerel, aerel.);
if serious="Y" then
AESLIFE="Y";
else AESLIFE="N";
if ^missing(aestart) and aestart < input(rfstdtc,yymmdd10.)
then EPOCH="Screening";
else if ^missing(aestart)
then EPOCH="Treatment";
else EPOCH=" ";
if ^missing(aestart) then
AESTDTC=put(aestart,yymmdd10.);
else AESTDTC=" ";
if ^missing(aeend) then
AEENDTC=put(aeend,yymmdd10.);
else AEENDTC=" ";
		if input(aestdtc, yymmdd10.) < input(rfstdtc, yymmdd10.) then
		AESTDY=input(aestdtc, yymmdd10.) - input(rfstdtc, yymmdd10.);
	else
		AESTDY=input(aestdtc, yymmdd10.) - input(rfstdtc, yymmdd10.)+1;

	if ^missing(aeendtc) and input(aeendtc, yymmdd10.) < input(rfstdtc, 
		yymmdd10.) then
			AEENDY=input(aeendtc, yymmdd10.) - input(rfstdtc, yymmdd10.);
	else if ^missing(AEendtc) then
		AEENDY=input(aeendtc, yymmdd10.) - input(rfstdtc, yymmdd10.)+1;
	else
		AEENDY=.;
		
run;

proc sort data=ae out=sdtm.ae(label='Adverse Events');
by studyid usubjid aeseq aedecod aestdtc;
run;
