proc sql;
create table empty_xp
(
    STUDYID   char(15)   label="Study Identifier",
    DOMAIN    char(2)    label="Domain Abbreviation",
    USUBJID   char(25)   label="Unique Subject Identifier",
    XPSEQ     num        label="Sequence Number",
    XPTESTCD  char(8)    label="Pain Test Short Name",
    XPTEST    char(40)   label="Pain Test Name",
    XPORRES   char(200)  label="Result or Finding in Original Units",
    XPSTRESC  char(200)  label="Character Result/Finding in Std Format",
    XPSTRESN  num        label="Numeric Result/Finding in Std Format",
    EPOCH     char(40)   label="Epoch",
    VISITNUM  num        label="Visit Number",
    VISIT     char(40)   label="Visit Name",
    XPBLFL    char(2)    label="Baseline Flag",
    XPDTC     char(16)   label="Date/Time of Collection",
    XPDY      num        label="Study Day of Collection"
);
quit;

proc format fmtlib ;
  value pain 0="None" 1="Mild" 2="Moderate" 3="Severe";
  value visit 0="Baseline" 1="Month 3" 2="Month 6";
  run;

/* Create the new variable visitnumber visit name, usubjectid-- arrays- do loop  */
data trans (drop=randomizedt month3dt month6dt painbase pain3mo pain6mo);
set raw.pain;
length siteid $7 usubjid $25 visit $40 xpblfl $2;

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
	studyid='XYZ123';
	USUBJID=cats(studyid, siteid, put(subject, 3.)); 
	
	array dates{3} randomizedt month3dt month6dt;
	array scores{3} painbase pain3mo pain6mo;
	
	do i= 1 to 3;
	Visitnum= i-1;
	visit= put(visitnum,visit.);
	
	if visitnum=0 then 
	  XPBLFL="Y";
	  else XPBLFL=" ";
	  
	  if ^missing(dates{i}) and ^missing(scores{i}) then  do;
	    _xporres= scores{i};
	    _xpstresc= put(_xporres,pain.);
	    _xpstren=_xporres;
	    _xpdtc= put(dates{i},yymmdd10.);
	    output;
	    end;
	  end;
	  run;
	  
	  proc sql;
	  create table Pain_dm as
	  select a.*,b.rfstdtc
	  from trans as a
	  left join
	  sdtm.dm as b
	  on  a.usubjid=b.usubjid
	  order by usubjid,_xpdtc;
	  quit;
	  
	  /* 	Merge the data with SDTM.DM - RFSTDTC- Left join   */
	proc sql;
	 create table Pain_dm as
	 select  a.* , b.rfstdtc
	 
	 from trans as a
	 left join 
	 sdtm.dm as b
	 on a.usubjid=b.usubjid
	 order by usubjid, _xpdtc;
	 quit;

/* 	Push all the above info into the Empty Shell XP   */
data xp (keep=STUDYID DOMAIN USUBJID XPSEQ XPTESTCD XPTEST XPORRES XPSTRESC 
		XPSTRESN EPOCH VISITNUM VISIT XPBLFL XPDTC XPDY);
	set empty_xp pain_dm;
 by usubjid;
DOMAIN="XP";
   if first.usubjid then 
XPSEQ=.;
XPSEQ+1;

XPTESTCD = "XPAIN";
XPTEST= "Pain Score";
XPORRES= put(_xporres,1.);
XPSTRESC=_xpstresc;
XPSTRESN=_xpstren;
XPDTC=_xpdtc;
   if  input(xpdtc,yymmdd10.) < input(rfstdtc,yymmdd10.) then do;
      EPOCH = "Screening";
      XPDY = input(xpdtc,yymmdd10.) -input(rfstdtc,yymmdd10.);
      end;
      
   else   if  input(xpdtc,yymmdd10.) >= input(rfstdtc,yymmdd10.) then do;
      EPOCH = "Treatment";
      XPDY = input(xpdtc,yymmdd10.) -input(rfstdtc,yymmdd10.) +1;
      end;
      else do;
      EPOCH= " ";
       XPDY=.;
       end;
      
run;


proc sort data=xp out= sdtm.XP;
by  studyid usubjid xptestcd xpdtc;
