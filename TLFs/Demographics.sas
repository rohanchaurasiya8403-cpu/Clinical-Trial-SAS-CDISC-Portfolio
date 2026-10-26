data decoy;
	set adam.adsl;
	where SAFFL='Y';
run;

proc means data=decoy n mean std median min max noprint;
	class TRT01A;
	var AGE;
	output out=age_stat n=N mean=MEAN std=SD median=MEDIAN min=MIN max=MAX;
run;

data age_final;
	set age_stat;
	length PARAM $30 RESULT $30;
	SECTION='AGE';

	if TRT01A ne '' then
		do;
			PARAMN=1;
			PARAM='N';
			RESULT=put(N, best.);
			output;
			PARAMN=2;
			PARAM='Mean (SD)';
			RESULT=cats(put(MEAN, 5.1), ' (', put(SD, 5.1), ')');
			output;
			PARAMN=3;
			PARAM='Median';
			RESULT=put(MEDIAN, 5.1);
			output;
			PARAMN=4;
			PARAM='Min, Max';
			RESULT=cats(put(MIN, 5.1), ', ', put(MAX, 5.1));
			output;
		end;
	keep PARAMN PARAM TRT01A RESULT SECTION;
run;

proc sort data=age_final;
	by PARAMN PARAM SECTION;
run;

proc transpose data=age_final out=age_final(drop=_NAME_);
	by PARAMN PARAM SECTION;
	id TRT01A;
	var result;
run;

proc means data=decoy N noprint;
	class TRT01A AGEGR1;
	var AGE;
	output out=group N=N;
run;

data grp;
	set group;
	length PARAM $30 RESULT $30;

	/* Keep treatment + age-group rows only */
	if not missing(TRT01A) and not missing(AGEGR1);
	PARAM=AGEGR1;
	RESULT=put(N, 3.);
	keep PARAM TRT01A RESULT N;
run;

/* Get denominator for each treatment */
proc sql;
	create table denom as select TRT01A, count(AGE) as DENOM from decoy group by 
		TRT01A;
quit;

/* Sort before merge */
proc sort data=grp;
	by TRT01A;
run;

proc sort data=denom;
	by TRT01A;
run;

/* Calculate n (%) */
data rebox;
	merge grp denom;
	by TRT01A;
	PCT=(N / DENOM) * 100;
	RESULT=cats(put(N, 3.), ' (', put(PCT, 5.1), '%)');
	SECTION='GROUP';
	drop DENOM PCT N;
run;

/* Transpose */
proc sort data=rebox;
	by PARAM SECTION;
run;

proc transpose data=rebox out=grp_final(drop=_NAME_);
	by PARAM SECTION;
	id TRT01A;
	var RESULT;
run;

proc means data=decoy n nonobs;
	class TRT01A sex;
	var TRT01AN;
	output out=rambo n=n;
run;

data fita;
	set rambo;
	length PARAM $30 Result $30;
	Where ^missing(TRT01A) and ^missing(sex);
	PARAM=SEX;
	Result=put(n, 4.);
	keep TRT01A PARAM Result N;
run;

proc sql;
	create table sopa as select TRT01A, count(TRT01AN) as dosa from decoy group by 
		TRT01A;
	run;

proc sort data=sopa;
	by TRT01A;
run;

proc sort data=fita;
	by TRT01A;
run;

data sexa;
	merge fita sopa;
	by TRT01A;
	SECTION='SEX';
	PCT=(N / DOSA) * 100;
	RESULT=cats(put(N, 3.), ' (', put(PCT, 5.1), '%)');
	drop DOSA PCT N;
run;

proc sort data=sexa;
	by PARAM SECTION;
run;

proc transpose data=SEXA out=final_sex(drop=_Name_);
	by PARAM SECTION;
	id TRT01A;
	var Result;
run;

/* Get race counts */
proc means data=decoy n nonobs;
	class TRT01A Race;
	var TRT01AN;
	output out=raso n=N;
run;

/* Create Other variable */
data scum;
	set decoy;
	Other=RACEOTH;
run;

/* Count Other by treatment */
proc sql;
	create table dump as select TRT01A, count(Other) as N, 'Other' as PARAM 
		length=30, 'RACE' as SECTION from scum group by TRT01A;
quit;

/* Get treatment total */
proc sql;
	create table roma as select TRT01A, count(TRT01AN) as DOSA from decoy group by 
		TRT01A;
quit;

/* Race categories */
data raca;
	set raso;
	length PARAM $30 Result $30;
	where not missing(TRT01A) and not missing(RACE);
	PARAM=RACE;
run;

/* Calculate percentage for normal race categories */
proc sort data=raca;
	by TRT01A;
run;

proc sort data=roma;
	by TRT01A;
run;

data race;
	merge raca roma;
	by TRT01A;
	PCT=(N/DOSA)*100;
	Result=cats(put(N, 3.), ' (', put(PCT, 5.1), '%)');
	SECTION='RACE';
	keep TRT01A PARAM Result SECTION;
run;

/* Calculate percentage for Other */
proc sort data=dump;
	by TRT01A SECTION;
run;

data other_final;
	merge dump roma;
	by TRT01A;
	PCT=(N/DOSA)*100;
	Result=cats(put(N, 3.), ' (', put(PCT, 5.1), '%)');
	SECTION='RACE';
	keep TRT01A PARAM Result SECTION;
run;

/* Append Other to race categories */
data final_race;
	set race other_final;
run;

proc sort data=race;
	by PARAM SECTION;
run;

proc transpose data=race out=raceka;
	by PARAM SECTION;
	Id TRT01A;
	var Result;
run;

proc transpose data=other_final out=otherka;
	by PARAM SECTION;
	Id TRT01A;
	var Result;
run;

data fin_race(drop=_NAME_);
	set raceka otherka;
run;

/*------------------------------------------------------------*
 | COUNTRY
 *------------------------------------------------------------*/

proc means data=decoy n nonobs;
    class TRT01A Country;
    var TRT01AN;
    output out=cont n=N;
run;


/* Create country counts */

data countr;
    set cont;
    length PARAM $30 RESULT $30;

    where ^missing(TRT01A) and ^missing(Country);

    PARAM=Country;
    RESULT=put(N, 3.);

    keep TRT01A PARAM RESULT N;
run;


/* Get treatment denominator */

proc sql;
    create table soma as
    select TRT01A,
           count(TRT01AN) as SOMA
    from decoy
    group by TRT01A;
quit;


/* Sort before merge */

proc sort data=countr;
    by TRT01A;
run;

proc sort data=soma;
    by TRT01A;
run;


/* Calculate percentage */

data country;
    merge countr soma;
    by TRT01A;

    PCT=(N/SOMA)*100;

    RESULT=cats(
        put(N, 3.),
        ' (',
        put(PCT, 5.1),
        '%)'
    );

    SECTION='COUNTRY';

    keep TRT01A PARAM RESULT SECTION;
run;


/* Transpose */

proc sort data=country;
    by PARAM SECTION;
run;

proc transpose data=country
               out=fin_country(drop=_NAME_);
    by PARAM SECTION;
    id TRT01A;
    var RESULT;
run;

data final_dm(drop=PARAMN);
    length SECTION $30;

    set age_final
        grp_final
        final_sex
        fin_race
        fin_country;

    if SECTION='AGE' then do;
        SECTIONN=1;
        SECTION='Age (years)';
    end;

    else if SECTION='GROUP' then do;
        SECTIONN=2;
        SECTION='Age Group, n (%)';
    end;

    else if SECTION='SEX' then do;
        SECTIONN=3;
        SECTION='Sex, n (%)';
    end;

    else if SECTION='RACE' then do;
        SECTIONN=4;
        SECTION='Race, n (%)';
    end;

    else if SECTION='COUNTRY' then do;
        SECTIONN=5;
        SECTION='Country, n (%)';
    end;
run;

proc sort data=final_dm;
    by SECTIONN PARAM;
run;

title 'Demographics and Baseline Characteristics';

proc report data=final_dm nowd headline headskip;

    columns SECTIONN
             SECTION
             PARAM
             'Analgezia HCL 30 mg'n
             Placebo;

    define SECTIONN /
        order
        noprint;

    define SECTION /
        group
        noprint;

    define PARAM /
        display
        "Characteristics";

    define 'Analgezia HCL 30 mg'n /
        display
        "Analgezia HCL 30 mg";

    define Placebo /
        display
        "Placebo";

    break before SECTION / skip;

    compute before SECTION;
        line SECTION $30.;
    endcomp;

run;

title;