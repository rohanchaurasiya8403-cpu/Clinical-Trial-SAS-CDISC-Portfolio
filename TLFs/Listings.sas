data ae_listing;
	set adam.adae;
	where SAFFL='Y' and TRTEMFL='Y';
	keep USUBJID TRTA AEBODSYS AEDECOD ASTDT AENDT AESEV AESER AEREL AEACN;
run;

proc sort data=ae_listing;
	by TRTA USUBJID ASTDT;
run;

title 'Listing of Treatment-Emergent Adverse Events';

proc report data=ae_listing nowd headline headskip;
	columns USUBJID TRTA AEBODSYS AEDECOD ASTDT AENDT AESEV AESER AEREL AEACN;
	define USUBJID / display "Subject";
	define TRTA / display "Treatment";
	define AEBODSYS / display "System Organ Class";
	define AEDECOD / display "Preferred Term";
	define ASTDT / display "Start Date" format=date9.;
	define AENDT / display "End Date" format=date9.;
	define AESEV / display "Severity";
	define AESER / display "Serious";
	define AEREL / display "Relationship";
	define AEACN / display "Action Taken";
run;

title;

data sae_listing;
	set adam.adae;
	where SAFFL='Y' and TRTEMFL='Y' and AESER='Y';
	keep USUBJID TRTA AEBODSYS AEDECOD ASTDT AENDT AESEV AESER AEREL AEACN;
run;

proc sort data=sae_listing;
	by TRTA USUBJID ASTDT;
run;

title 'Listing of Serious Adverse Events';

proc report data=sae_listing nowd;
	columns USUBJID TRTA AEBODSYS AEDECOD ASTDT AENDT AESEV AESER AEREL AEACN;
	define USUBJID / display "Subject";
	define TRTA / display "Treatment";
	define AEBODSYS / display "System Organ Class";
	define AEDECOD / display "Preferred Term";
	define ASTDT / display "Start Date" format=date9.;
	define AENDT / display "End Date" format=date9.;
	define AESEV / display "Severity";
	define AESER / display "Serious";
	define AEREL / display "Relationship";
	define AEACN / display "Action Taken";
run;

title;

data action_listing;
	set adam.adae;
	where SAFFL='Y' and TRTEMFL='Y';
	keep USUBJID TRTA AEBODSYS AEDECOD ASTDT AENDT AESEV AESER AEREL AEACN;
run;

proc sort data=action_listing;
	by AEACN USUBJID ASTDT;
run;

title 'Listing of Adverse Events by Action Taken';

proc report data=action_listing nowd;
	columns AEACN USUBJID TRTA AEBODSYS AEDECOD ASTDT AENDT AESEV AESER AEREL;
	define AEACN / display "Action Taken";
	define USUBJID / display "Subject";
	define TRTA / display "Treatment";
	define AEBODSYS / display "System Organ Class";
	define AEDECOD / display "Preferred Term";
	define ASTDT / display "Start Date" format=date9.;
	define AENDT / display "End Date" format=date9.;
	define AESEV / display "Severity";
	define AESER / display "Serious";
	define AEREL / display "Relationship";
run;

title;