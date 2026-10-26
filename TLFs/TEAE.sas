/*------------------------------------------------------------*
| 1. Get TEAE subjects
 *------------------------------------------------------------*/
data domain;
	set adam.adae;
	where SAFFL='Y' and TRTEMFL='Y';
run;

/*------------------------------------------------------------*
| 2. Count subjects with at least one TEAE by treatment
 *------------------------------------------------------------*/
proc sql;
	create table dock as select TRTA, count(distinct USUBJID) as COUNT, 
		'Number of Subjects with at Least One TEAE' as Characteristics from domain 
		group by TRTA;
quit;

/*------------------------------------------------------------*
| 3. Get Safety Population denominator by treatment
 *------------------------------------------------------------*/
proc sql;
	create table denom as select TRT01A as TRTA, count(*) as DENOM from adam.adsl 
		where SAFFL='Y' group by TRT01A;
quit;

/*------------------------------------------------------------*
| 4. Merge count and denominator
 *------------------------------------------------------------*/
proc sort data=dock;
	by TRTA;
run;

proc sort data=denom;
	by TRTA;
run;

data lota;
	merge dock denom;
	by TRTA;
	PCT=(COUNT/DENOM)*100;
	SCORE=cats(put(COUNT, 2.), ' (', put(PCT, 5.1), '%)');
run;

/*------------------------------------------------------------*
| 5. Create TOTAL row
 *------------------------------------------------------------*/
proc sql;
	create table total as select 'Total' as TRTA length=30, sum(COUNT) as COUNT, 
		sum(DENOM) as DENOM, 'Number of Subjects with at Least One TEAE' as 
		Characteristics from lota;
quit;

/*------------------------------------------------------------*
| 6. Calculate Total n (%)
 *------------------------------------------------------------*/
data total;
	set total;
	PCT=(COUNT/DENOM)*100;
	SCORE=cats(put(COUNT, 2.), ' (', put(PCT, 5.1), '%)');
run;

/*------------------------------------------------------------*
| 7. Combine treatment + Total
 *------------------------------------------------------------*/
data final;
	set lota total;
run;

/*------------------------------------------------------------*
| 8. Transpose
 *------------------------------------------------------------*/
proc sort data=final;
	by Characteristics;
run;

proc transpose data=final out=sortd(drop=_NAME_);
	by Characteristics;
	id TRTA;
	var SCORE;
run;

Data term1;
set sortd;
Term='Number of Subjects';
run;

/*============================================================*
| Count subjects with at least one TEAE by severity
 *============================================================*/
proc sql;
	create table new as select TRTA, AESEV, count(distinct USUBJID) as COUNT, 
		'Any TEAE' as Characteristics from domain where not missing(AESEV) group by 
		TRTA, AESEV;
quit;

/*============================================================*
| Get Safety Population denominator
 *============================================================*/
proc sql;
	create table denom as select TRT01A as TRTA, count(*) as DENOM from adam.adsl 
		where SAFFL='Y' group by TRT01A;
quit;

/*============================================================*
| Calculate n (%)
 *============================================================*/
proc sort data=new;
	by TRTA;
run;

proc sort data=denom;
	by TRTA;
run;

data comb_sev;
	merge new denom;
	by TRTA;
	PCT=(COUNT/DENOM)*100;
	SCORE=cats(put(COUNT, 2.), ' (', put(PCT, 5.1), '%)');
run;

/*============================================================*
| Create Total
 *============================================================*/
proc sql;
	create table total_sev as select 'Total' as TRTA length=30, AESEV, 
		count(distinct USUBJID) as COUNT, 'Any TEAE' as Characteristics from domain 
		where not missing(AESEV) group by AESEV;
quit;

/*============================================================*
| Total denominator
 *============================================================*/
proc sql;
	create table total_denom as select count(*) as DENOM from adam.adsl where 
		SAFFL='Y';
quit;

/*============================================================*
| Calculate Total n (%)
 *============================================================*/
data total_sev;
	if _n_=1 then
		set total_denom;
	set total_sev;
	PCT=(COUNT/DENOM)*100;
	SCORE=cats(put(COUNT, 2.), ' (', put(PCT, 5.1), '%)');
run;

/*============================================================*
| Combine treatment + Total
 *============================================================*/
data final_sev;
	set comb_sev total_sev;
run;

/*============================================================*
| Sort
 *============================================================*/
proc sort data=final_sev;
	by AESEV Characteristics;
run;

/*============================================================*
| Transpose
 *============================================================*/
proc transpose data=final_sev out=sortd_sev(drop=_NAME_);
	by AESEV Characteristics;
	id TRTA;
	var SCORE;
run;

data term2(drop=AESEV);
set sortd_sev;
TERM=AESEV;
run;

/* Serious Adverse Events */
data serious;
	set domain;

	if AESER='Y';
run;

/* SAE count by treatment */
proc sql;
	create table serab as select TRTA, count(distinct USUBJID) as Count, 
		'Serious Adverse Event' as Characteristics from serious group by TRTA;
quit;

/* Total SAE count */
proc sql;
	create table sertb as select 'Total' as TRTA length=30, count(distinct 
		USUBJID) as Count, 'Serious Adverse Event' as Characteristics from serious;
quit;

/* Safety population denominator by treatment */
proc sql;
	create table dmog as select TRT01A as TRTA, count(distinct USUBJID) as dmog, 
		'Serious Adverse Event' as Characteristics from adam.adsl where SAFFL='Y' 
		group by TRT01A;
quit;

/* Sort before merge */
proc sort data=serab;
	by TRTA;
run;

proc sort data=dmog;
	by TRTA;
run;

/* Treatment n (%) */
data sera;
	merge serab dmog;
	by TRTA;
	PCT=(Count/dmog)*100;
	Score=cats(put(Count, 2.), ' (', put(PCT, 5.1), '%)');
	keep TRTA SCORE CHARACTERISTICS;
run;

/* Total Safety Population denominator */
proc sql;
	create table dbad as select count(distinct USUBJID) as dbad from adam.adsl 
		where SAFFL='Y';
quit;

/* Total n (%) */
data cambo;
	if _n_=1 then
		set dbad;
	set sertb;
	PCT=(Count/dbad)*100;
	Score=cats(put(Count, 2.), ' (', put(PCT, 5.1), '%)');
	keep TRTA SCORE CHARACTERISTICS;
run;

/* Combine treatment + total */
data comb_fser;
	set sera cambo;
run;

/* Transpose */
proc transpose data=comb_fser out=final_ser(drop=_NAME_);
	by CHARACTERISTICS;
	id TRTA;
	var Score;
run;

Data term3;
set final_ser;
TERM='Any SAE';
run;

proc sql;
    create table rela as
    select TRTA,
           count(distinct USUBJID) as Count,
           'Relationship to study treatment' as Characteristics,
           AEREL
    from domain
    group by TRTA,AEREL;
quit;


proc sql;
    create table denom as
    select TRT01A as TRTA,
           count(*) as DENOM
    from adam.adsl
    where SAFFL='Y'
    group by TRT01A;
quit;


proc sort data=rela;
    by TRTA;
run;

proc sort data=denom;
    by TRTA;
run;


data mixpct;
    merge rela denom;
    by TRTA;

    PCT=(Count/denom)*100;

    Score=cats(
        put(Count,2.),
        ' (',
        put(PCT,5.1),
        '%)'
    );

    keep Characteristics AEREL TRTA SCORE;
run;


/* Total by relationship category */
proc sql;
    create table relb as
    select 'Total' as TRTA length=30,
           count(distinct USUBJID) as Count,
           'Relationship to study treatment' as Characteristics,
           AEREL
    from domain
    group by AEREL;
quit;


proc sql;
    create table dbad as
    select count(distinct USUBJID) as dbad
    from adam.adsl
    where SAFFL='Y';
quit;


/* Total n (%) */
data camba;
    if _n_=1 then
        set dbad;

    set relb;

    PCT=(Count/dbad)*100;

    Score=cats(
        put(Count,2.),
        ' (',
        put(PCT,5.1),
        '%)'
    );

    keep TRTA SCORE CHARACTERISTICS AEREL;
run;


/* Combine */
data fin_mix;
    set mixpct camba;
run;


/* Transpose */
proc sort data=fin_mix;
    by AEREL CHARACTERISTICS;
run;

proc transpose data=fin_mix out=relation(drop=_NAME_);
    by AEREL CHARACTERISTICS;
    id TRTA;
    var SCORE;
run;

data term4(drop=AEREL);
set relation;
TERM=AEREL;
run;

proc sql;
    create table acna as
    select TRTA,
           count(distinct USUBJID) as Count,
           'Action taken' as Characteristics,
           AEACN
    from domain
    group by TRTA,AEACN;
quit;


proc sql;
    create table denom as
    select TRT01A as TRTA,
           count(*) as DENOM
    from adam.adsl
    where SAFFL='Y'
    group by TRT01A;
quit;


proc sort data=ACNA;
    by TRTA;
run;

proc sort data=denom;
    by TRTA;
run;


data mixpctacn;
    merge acna denom;
    by TRTA;

    PCT=(Count/denom)*100;

    Score=cats(
        put(Count,2.),
        ' (',
        put(PCT,5.1),
        '%)'
    );

    keep Characteristics AEACN TRTA SCORE;
run;


/* Total by Action Taken category */
proc sql;
    create table ACNB as
    select 'Total' as TRTA length=30,
           count(distinct USUBJID) as Count,
           'Action taken' as Characteristics,
           AEACN
    from domain
    group by AEACN;
quit;


proc sql;
    create table dbad as
    select count(distinct USUBJID) as dbad
    from adam.adsl
    where SAFFL='Y';
quit;


/* Total n (%) */
data acnc;
    if _n_=1 then
        set dbad;

    set acnb;

    PCT=(Count/dbad)*100;

    Score=cats(
        put(Count,2.),
        ' (',
        put(PCT,5.1),
        '%)'
    );

    keep TRTA SCORE CHARACTERISTICS AEACN;
run;


/* Combine */
data fin_ACNmix;
    set mixpctacn acnc;
run;


/* Transpose */
proc sort data=fin_ACNmix;
    by AEACN CHARACTERISTICS;
run;

proc transpose data=fin_ACNmix out=ACTION(drop=_NAME_);
    by AEACN CHARACTERISTICS;
    id TRTA;
    var SCORE;
run;

Data term5(drop=AEACN);
set ACTION;
TERM=AEACN;
run;

Data TEAE;
set TERM1 TERM2 TERM3 TERM4 TERM5;
run;

data term1_teae;
    set TERM1;
    length section $30;
    SECTION='Number of Subjects';
    SECTIONN=1;
run;

data term2_teae;
    set TERM2;
    SECTION='Severity';
    SECTIONN=2;
run;

data term3_teae;
    set TERM3;
    SECTION='Seriousness';
    SECTIONN=3;
run;

data term4_teae;
    set TERM4;
    SECTION='Relationship to Study Treatment';
    SECTIONN=4;
run;

data term5_teae;
    set TERM5;
    SECTION='Action Taken';
    SECTIONN=5;
run;


data final_teae;
    set term1_teae
        term2_teae
        term3_teae
        term4_teae
        term5_teae;
run;


proc sort data=final_teae;
    by SECTIONN TERM;
run;


title 'Treatment-Emergent Adverse Events';

proc report data=final_teae nowd headline headskip;

    columns SECTIONN
             SECTION
             TERM
             'Analgezia HCL 30 mg'n
             Placebo
             Total;

    define SECTIONN /
        order
        noprint;

    define SECTION /
        group
        noprint;

    define TERM /
        display
        "Characteristics";

    define 'Analgezia HCL 30 mg'n /
        display
        "Analgezia HCL 30 mg";

    define Placebo /
        display
        "Placebo";

    define Total /
        display
        "Total";

    break before SECTION / skip;

    compute before SECTION;
        line SECTION $40.;
    endcomp;

run;

title;