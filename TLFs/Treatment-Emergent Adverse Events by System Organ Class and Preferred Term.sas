/*------------------------------------------------------------*
| Select TEAE records
 *------------------------------------------------------------*/
data nokia;
    set adam.adae;
    where SAFFL='Y' and TRTEMFL='Y';
run;

/*------------------------------------------------------------*
| Count subjects by SOC, PT and Treatment
 *------------------------------------------------------------*/
proc sql;
    create table soc as
    select AEBODSYS,
           AEDECOD,
           TRTA,
           count(distinct USUBJID) as Count
    from nokia
    group by AEBODSYS,AEDECOD,TRTA;
quit;

/*------------------------------------------------------------*
| Treatment denominator
 *------------------------------------------------------------*/
proc sql;
    create table denom as
    select TRT01A as TRTA,
           count(distinct USUBJID) as DENOM
    from adam.adsl
    where SAFFL='Y'
    group by TRT01A;
quit;

/*------------------------------------------------------------*
| Calculate percentage for SOC/PT
 *------------------------------------------------------------*/
proc sort data=soc;
    by TRTA;
run;

proc sort data=denom;
    by TRTA;
run;

data mixsoc;
    merge soc denom;
    by TRTA;

    PCT=(Count/DENOM)*100;

    Score=cats(
        put(Count,2.),
        ' (',
        put(PCT,5.1),
        '%)'
    );

    keep AEBODSYS AEDECOD TRTA Score;
run;

/*------------------------------------------------------------*
| Create Total for SOC/PT
 *------------------------------------------------------------*/
proc sql;
    create table tsoc as
    select 'Total' as TRTA length=30,
           AEBODSYS,
           AEDECOD,
           count(distinct USUBJID) as Count
    from nokia
    group by AEBODSYS,AEDECOD;
quit;

/*------------------------------------------------------------*
| Total denominator
 *------------------------------------------------------------*/
proc sql;
    create table tdenom as
    select count(distinct USUBJID) as DENOM
    from adam.adsl
    where SAFFL='Y';
quit;

/*------------------------------------------------------------*
| Calculate Total percentage
 *------------------------------------------------------------*/
data total_pt;
    if _n_=1 then
        set tdenom;

    set tsoc;

    PCT=(Count/DENOM)*100;

    Score=cats(
        put(Count,2.),
        ' (',
        put(PCT,5.1),
        '%)'
    );

    keep AEBODSYS AEDECOD TRTA Score;
run;

/*------------------------------------------------------------*
| Combine Treatment + Total
 *------------------------------------------------------------*/
data finpc;
    set mixsoc total_pt;
run;

/*------------------------------------------------------------*
| Sort
 *------------------------------------------------------------*/
proc sort data=finpc;
    by AEBODSYS AEDECOD;
run;

/*------------------------------------------------------------*
| Transpose treatment columns
 *------------------------------------------------------------*/
proc transpose data=finpc
               out=finalsera(drop=_NAME_);

    by AEBODSYS AEDECOD;
    id TRTA;
    var Score;

run;

/*------------------------------------------------------------*
| Prepare report dataset
 *------------------------------------------------------------*/
data soc_report;
    set finalsera;

    length SECTION $200;
    length PARAM $200;

    SECTION=AEBODSYS;
    PARAM=AEDECOD;

    keep SECTION
         PARAM
         'Analgezia HCL 30 mg'n
         Placebo
         Total;
run;

/*------------------------------------------------------------*
| Sort by SOC and Preferred Term
 *------------------------------------------------------------*/
proc sort data=soc_report;
    by SECTION PARAM;
run;

/*------------------------------------------------------------*
| Final SOC / Preferred Term Report
 *------------------------------------------------------------*/
title 'Treatment-Emergent Adverse Events by System Organ Class and Preferred Term';

proc report data=soc_report nowd;

    columns SECTION
             PARAM
             'Analgezia HCL 30 mg'n
             Placebo
             Total;

    define SECTION /
        group
        noprint;

    define PARAM /
        display
        "System Organ Class / Preferred Term"
        style(column)=[just=left];

    define 'Analgezia HCL 30 mg'n /
        display
        "Analgezia HCL 30 mg"
        style(column)=[just=center];

    define Placebo /
        display
        "Placebo"
        style(column)=[just=center];

    define Total /
        display
        "Total"
        style(column)=[just=center];

    break before SECTION / skip;

    compute before SECTION;
        line SECTION $200.;
    endcomp;

run;

title;