data empty_lb;
length STUDYID $15 DOMAIN $2 USUBJID $25 LBSEQ 8 LBTESTCD $8
LBTEST $40 LBCAT $40 LBORRES $200 LBORRESU $40 LBORNRLO $40
LBORNRHI $40 LBSTRESC $200 LBSTRESN 8 LBSTRESU $40 LBSTNRLO 8
LBSTNRHI 8 LBNRIND $20 LBLOBXFL $2 LBBLFL $2 VISITNUM 8
VISIT $40 EPOCH $40 LBDTC $16 LBDY 8;
label STUDYID='Study Identifier' DOMAIN='Domain Abbreviation'
USUBJID='Unique Subject Identifier' LBSEQ='Sequence Number'
LBTESTCD='Lab Test or Examination Short Name'
LBTEST='Lab Test or Examination Name'
LBCAT='Category for Lab Test'
LBORRES='Result or Finding in Original Units'
LBORRESU='Original Units'
LBORNRLO='Reference Range Lower Limit in Orig Unit'
LBORNRHI='Reference Range Upper Limit in Orig Unit'
LBSTRESC='Character Result/Finding in Std Format'
LBSTRESN='Numeric Result/Finding in Standard Units'
LBSTRESU='Standard Units'
LBSTNRLO='Reference Range Lower Limit-Std Units'
LBSTNRHI='Reference Range Upper Limit-Std Units'
LBNRIND='Reference Range Indicator'
LBBLFL='Baseline Flag'
LBLOBXFL='Last Observation before Exposure Flag'
LBBLFL='Baseline Flag'
VISITNUM='Visit Number' VISIT='Visit Name' EPOCH='Epoch'
LBDTC='Date/Time of Specimen Collection'
LBDY='Study Day of Specimen Collection';
stop;
run;
 
proc format;
value visits 0='Baseline' 1='Month 3' 2='Month 6';
run;
 
proc sort data=raw.labs out=labsort;
by subject;
run;
 
data lab;
set labsort;
length siteid $7 studyid $15 usubjid $25;
by subject;
 
if subject >=500 then siteid='500';
else if subject >=400 then siteid='400';
else if subject >=300 then siteid='300';
else if subject >=200 then siteid='200';
else if subject >=100 then siteid='100';
else siteid='NA';
studyid='XYZ123';
usubjid=cats('XYZ123', siteid, put(subject, 3.));
 
if first.subject then lbseq=.;
lbseq+1;
run;
 
data lab_dm;
merge lab(in=a) sdtm.dm(in=b keep=usubjid rfstdtc);
by usubjid;
 
if a;
run;
 
data lb(keep=STUDYID DOMAIN USUBJID LBSEQ LBTESTCD LBTEST LBCAT LBORRES
LBORRESU LBORNRLO LBORNRHI LBSTRESC LBSTRESN LBSTRESU LBSTNRLO LBSTNRHI 
LBNRIND LBLOBXFL LBBLFL VISITNUM VISIT EPOCH LBDTC LBDY);
set empty_lb lab_dm;
 
/*STUDYID='XYZ123'*/;
DOMAIN='LB';
 
if labtest='ALBUMIN' then do;
LBtest='Albumin; Microalbumin';
LBtestCD='ALB';
end;
else if labtest='ALK. PHOS.' then do;
LBtest='Alkaline Phosphatase';
LBtestCD='ALP';
end;
else if labtest='ALT (SGPT)' then do;
LBtest='Alanine Aminotransferase; SGPT';
LBtestCD='ALT';
end;
else if labtest='AST (SGOT)' then do;
LBtest='Aspartate Aminotransferase; SGOT';
LBtestCD='AST';
end;
else if labtest='DIRECT BILI' then do;
LBtest='Direct Bilirubin';
LBtestCD='BILDIR';
end;
else if labtest='TOTAL BILI' then do;
LBtest='Bilirubin; Total Bilirubin';
LBtestCD='BILI';
end;
else if labtest='GGTP' then do;
LBtest='Gamma Glutamyl Transferase';
LBtestCD='GGT';
end;
else if labtest='HEMATOCRIT' then do;
LBtest='Hematocrit';
LBtestCD='HCT';
end;
else if labtest='HEMOGLOBIN' then do;
LBtest='Hemoglobin';
LBtestCD='HGB';
end;
else if labtest='TOTAL PROT' then do;
LBtest='Protein';
LBtestCD='PROT';
end;
else if labtest='GLUCOSE' then do;
LBtest='Glucose';
LbtestCD='GLUC';
end;
LBCAT=strip(labcat);
LBORRES=put(nresult, BEST.);
LBORRESU=strip(colunits);
LBORNRLO=put(lownorm, BEST.);
LBORNRHI=put(highnorm, BEST.);
LBSTRESC=put(nresult, BEST.);
LBSTRESN=nresult;
LBSTRESU=LBORRESU;
LBSTNRLO=lownorm;
LBSTNRHI=highnorm;
 
if (lbtestcd='GLUC' and lbcat='URINALYSIS' and (input(lborres, best.) 
> 0))then lbnrind='HIGH';
else if (lbtestcd='GLUC' and lbcat='URINALYSIS' and (input(lborres, best.) 
<=0)) then lbnrind='NORMAL';
else if lbstnrlo ne . and lbstresn ne . and round(lbstresn, .0000001) 
< round(lbstnrlo, .0000001) then lbnrind='LOW';
else if lbstnrhi ne . and lbstresn ne . and round(lbstresn, .0000001) 
> round(lbstnrhi, .0000001) then lbnrind='HIGH';
else if lbstnrhi ne . and lbstresn ne . then lbnrind='NORMAL';
VISITNUM=month;
VISIT=put(visitnum, visits.);
LBLOBXFL='';
 
if VISIT='Baseline' then LBBLFL='Y';
else LBBLFL=' ';
LBDTC=put(labdate, yymmdd10.);
 
if (input(LBDTC, yymmdd10.) < input(rfstdtc, yymmdd10.)) then do;
LBDY=input(lbdtc, yymmdd10.) - input(rfstdtc, yymmdd10.);
EPOCH='SCREENING';
end;
else if
(input(LBDTC, yymmdd10.) >=input(rfstdtc, yymmdd10.)) then do;
LBDY=input(lbdtc, yymmdd10.) - input(rfstdtc, yymmdd10.)+1;
EPOCH='TREATMENT';
end;
else do;
LBDY=.;
EPOCH='';
end;
run;
 
proc sort data=lb out=sdtm.LB(label='Laboratory Test Results');
by STUDYID USUBJID LBSEQ LBTESTCD VISITNUM;
run;