/*------------------------------------------------------------*
 | STEP 1: Create population records
 *------------------------------------------------------------*/

data new;
    set adam.adsl;
    length PARAM $50;

    if RANDFL='Y' then do;
        PARAM='Randomized Subjects';
        PARAMN=1;
        output;
    end;

    if SAFFL='Y' then do;
        PARAM='Safety Population';
        PARAMN=2;
        output;
    end;

    if ITTFL='Y' then do;
        PARAM='Intent-to-treat Population';
        PARAMN=3;
        output;
    end;

    if RESPFL='Y' then do;
        PARAM='Responder Population';
        PARAMN=4;
        output;
    end;
run;


/*------------------------------------------------------------*
 | STEP 2: Sort
 *------------------------------------------------------------*/

proc sort data=new;
    by PARAMN TRT01A USUBJID;
run;


/*------------------------------------------------------------*
 | STEP 3: Count unique subjects by treatment
 *------------------------------------------------------------*/

data count;
    set new;
    by PARAMN TRT01A USUBJID;

    if first.USUBJID then output;

    keep PARAM PARAMN TRT01A USUBJID;
run;

proc sort data=count;
    by PARAMN TRT01A;
run;


/*------------------------------------------------------------*
 | STEP 4: Get treatment counts
 *------------------------------------------------------------*/

data count;
    set count;
    by PARAMN TRT01A;

    if first.TRT01A then N=0;
    N+1;

    if last.TRT01A then output;

    keep PARAM PARAMN TRT01A N;
run;


/*------------------------------------------------------------*
 | STEP 5: Create Total
 *------------------------------------------------------------*/

proc sort data=new;
    by PARAMN USUBJID;
run;

data total;
    set new;
    by PARAMN USUBJID;

    if first.USUBJID then output;

    keep PARAM PARAMN USUBJID;
run;

proc sort data=total;
    by PARAMN;
run;

data total;
    set total;
    by PARAMN;

    if first.PARAMN then N=0;
    N+1;

    if last.PARAMN then do;
        TRT01A='Total';
        output;
    end;

    keep PARAM PARAMN TRT01A N;
run;


/*------------------------------------------------------------*
 | STEP 6: Combine treatment + total
 *------------------------------------------------------------*/

data final;
    set count total;
run;

/*------------------------------------------------------------*
 | STEP 7: Create denominator
 *------------------------------------------------------------*/

proc sql;
    create table denom as
    select TRT01A,
           count(distinct USUBJID) as DENOM
    from adam.adsl
    group by TRT01A;

    insert into denom
    select 'Total' as TRT01A length=30,
           count(distinct USUBJID) as DENOM
    from adam.adsl;
quit;


/*------------------------------------------------------------*
 | STEP 8: Add percentage
 *------------------------------------------------------------*/

proc sort data=final;
    by TRT01A;
run;

proc sort data=denom;
    by TRT01A;
run;

data final;
    merge final denom;
    by TRT01A;

    PCT=(N/DENOM)*100;

    SCORE=cats(
        put(N, 2.),
        ' (',
        put(PCT, 5.1),
        '%)'
    );

    keep PARAM PARAMN TRT01A SCORE;
run;


/*------------------------------------------------------------*
 | STEP 9: Sort before transpose
 *------------------------------------------------------------*/

proc sort data=final;
    by PARAMN PARAM;
run;


/*------------------------------------------------------------*
 | STEP 10: Transpose
 *------------------------------------------------------------*/

proc transpose data=final
               out=pop_wide(drop=_NAME_);
    by PARAMN PARAM;
    id TRT01A;
    var SCORE;
run;


/*------------------------------------------------------------*
 | STEP 11: Final TLF
 *------------------------------------------------------------*/

title 'Table 14.1.1 — Subject Population Summary';

proc report data=pop_wide nowd headline headskip;

    columns PARAM
            'Analgezia HCL 30 mg'n
            Placebo
            Total;

    define PARAM /
        display
        "Population"
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

run;

title;