* ================== Program: PQE_AREA_RISKADJ.SAS ==================;
*
*  TITLE:  AREA LEVEL RISK ADJUSTED RATES FOR AHRQ PREVENTION QUALITY 
*          INDICATORS IN EMERGENCY DEPARTMENT SETTINGS (PQE)
*
*  DESCRIPTION:
*         Calculates risk-adjusted and smoothed rates for
*         PQE across stratifiers.
*         Variables created by this program are EAQExx, RAQExx, 
*         LAQExx, UAQExx, SAQExx, SNAQExx, VAQExx, XAQExx
*         Output stratified by AGE, SEXCAT and POVCAT from
*         population file and PQE_AREA_MEASURES output.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*====================================================================;

 title2 'PQE_AREA_RISKADJ PROGRAM';
 title3 'AHRQ PREVENTION QUALITY INDICATORS IN ED SETTINGS (PQE): CALCULATE RISK-ADJUSTED AREA RATES';
 
*====================================================================================;
*  PART I: CALCULATE AREA RATES FOR AHRQ PREVENTION QUALITY INDICATORS IN ED SETTINGS
*====================================================================================;

 * ---------------------------------------------------------------- ;   
 * --- POPULATION GROUPS FOR EACH QI BASED ON 18 5-YEAR AGE RANGES  ;
 * ---------------------------------------------------------------- ;
 %LET POPCAT_AQE01 = 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18; /* 5+      */
 %LET POPCAT_AQE02 = 9,10,11,12,13,14,15,16,17,18;               /* 40+     */
 %LET POPCAT_AQE03 = 1,2,3,4,5,6,7,8,9,10,11,12,13;              /* 4m - 64 */
 %LET POPCAT_AQE04 = 2,3,4,5,6,7,8;                              /* 5 - 39  */
 %LET POPCAT_AQE05 = 5,6,7,8,9,10,11,12,13,14,15,16,17,18;       /* 18+     */

 * ------------------------------------------------------------------- ;
 * --- PREVENTION QUALITY INDICATORS IN ED SETTINGS (PQE)          --- ;
 * --- NAMING CONVENTION:                                          --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PREVENTION QUALITY          --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:                          --- ;
 * ---       (T) NUMERATOR ("TOP") - FROM PQE_AREA_MEASURES        --- ;
 * ---       (P) DENOMINATOR ("POP") - ADJUSTED FROM POPULATION FILE - ;
 * ---       (O) OBSERVED RATES (T/P)                              --- ;
 * ---       (E) EXPECTED RATE                                     --- ;
 * ---       (R) RISK-ADJUSTED RATE                                --- ;
 * ---       (L) LOWER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE     --- ;
 * ---       (U) UPPER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE     --- ;
 * ---       (S) SMOOTHED RATE (NOT REPORTED FOR STRATA)           --- ;
 * ---       (X) SMOOTHED RATE STANDARD ERROR (NOT REPORTED FOR STRATA);
 * --- THE SECOND LETTER IDENTIFIES THE PQE AS AREA (A) LEVEL      --- ;
 * --- INDICATOR. THE NEXT FOUR CHARACTERS ARE ALWAYS 'QE'.        --- ;
 * --- THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.               --- ;
 * ------------------------------------------------------------------- ;

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR                               --- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE     --- ;
 * --- OUTPUT BASED ON AREAS IN PQE_AREA_MEASURES OUTPUT.       --- ;
 * ---------------------------------------------------------------- ;

 /*MACRO TO ADJUST AREA AGGREGATION BASED ON MAREA VALUE IN PQE_AREA_CONTROL.*/

 %MACRO CTY2MA;
    %IF &MALEVL EQ 0 %THEN %DO;
        attrib MAREA length=$5
          label='FIPS State County Code';
        MAREA = FIPSTCO;
    %END;
    %ELSE %IF &MALEVL EQ 1 %THEN %DO;
        attrib MAREA length=$5
          label='MODIFIED FIPS';
        MAREA = input(put(FIPSTCO,$M1AREA.),$5.);
    %END;
    %ELSE %IF &MALEVL EQ 2 %THEN %DO;
        attrib MAREA length=$5
          label='OMB 1999 METRO AREA';
        MAREA = input(put(FIPSTCO,$M2AREA.),$5.);
    %END;
    %ELSE %IF &MALEVL EQ 3 %THEN %DO;
        attrib MAREA length=$5
          label='OMB 2003 METRO AREA';
        MAREA = input(put(FIPSTCO,$M3AREA.),$5.);
    %END;
 %MEND;

 data TEMP0;
    set OUTMSR.&OUTFILE_MEAS.  ; 
	
    * ------------------------------------------------------- ;
    * --- Exclude any record not in one of the PQEs       --- ;
    * -------------------------------------------------- ---- ;
    IF MIN(OF EXCLUDE:) = 0 ;  
	
    * ------------------------------------------------- ;
    * --- Limit ED visits to patients who reside    --- ;
    * --- in the same State as the ED, residents    --- ;
    * --- of the hospital state.                    --- ;
    * ------------------------------------------------- ;
    IF RESIDENT EQ 1 ;
              
    * --------------------------------------------------- ;
    * --- Call macro to define geographic of interest --- ;
    * --------------------------------------------------- ;
    %CTY2MA
 run;        

 /* IDENTIFY UNIQUE MAREA VALUES IN PQE_AREA_MEASURES OUTPUT. */
 
 proc   Sort data=TEMP0(keep=MAREA) out=MAREA nodupkey;
 by     MAREA;
 run;
 /* FOR COUNTY-LEVEL ANALYSIS, LOAD COUNTY-LEVEL POPULATION DATA.                      */
 /* POPULATION IS DETERMINED BY MAREA LEVEL AND YEAR SPECIFIED IN PQE_AREA_CONTROL.SAS */

    DATA QIPOP0;
        LENGTH FIPSTCO $5 SEXCAT POPCAT RACECAT 3 
               POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
               POP_2005 POP_2006 POP_2007 POP_2008 POP_2009
               POP_2010 POP_2011 POP_2012 POP_2013 POP_2014 
			   POP_2015 POP_2016 POP_2017 POP_2018 POP_2019 
			   POP_2020 POP_2021 POP_2022 POP_2023 POP 8
               STATE $2.
        ;
    
        INFILE POPFILE MISSOVER FIRSTOBS=2;
    
		INPUT FIPSTCO SEXCAT POPCAT RACECAT 
			   POP_2000 POP_2001 POP_2002 POP_2003 POP_2004 
			   POP_2005 POP_2006 POP_2007 POP_2008 POP_2009 
			   POP_2010 POP_2011 POP_2012 POP_2013 POP_2014 
			   POP_2015 POP_2016 POP_2017 POP_2018 POP_2019
			   POP_2020 POP_2021 POP_2022 POP_2023;
    
        %CTY2MA
    
        POP = POP_&POPYEAR.; 

        * --- For PQE 03 Acute ACSC, exclude age 3 month or younger (0-3 month) --- ;
        * --- assume uniform distribution in 0-4 year (0-59 month)              --- ;
        IF POPCAT=1 THEN POPX = ROUND(POP * 0.95);
        ELSE POPX = POP;

        STATE = FIPSTATE(INPUT(SUBSTR(FIPSTCO,1,2),2.0)) ;

       
    RUN;
/* END OF COUNTY LEVEL POPULATION */


 proc   Summary data=QIPOP0 nway;
 class  MAREA STATE POPCAT SEXCAT;
 var    POP POPX;
 output out=QIPOP sum=;
 run;

 proc   Sort data=QIPOP;
 by     MAREA STATE POPCAT SEXCAT;
 run;

 /* LIMIT POPULATION TOTALS TO MAREA CODES FOUND IN PQE_AREA_MEASURES OUTPUT. */

 data   QIPOP(keep=MAREA STATE POPCAT SEXCAT POP POPX);
 merge  MAREA(in=X) QIPOP(in=Y);
 by     MAREA;

 if X and Y;

 run;

 * ---------------------------------------------------------------- ;
 * - PREVENTION QUALITY INDICATORS IN ED SETTINGS ADJUSTED RATES  - ;
 * ---------------------------------------------------------------- ;
 * AREA-LEVEL INDICATOR DENOMINATORS ARE ADJUSTED BASED ON THE  --- ;
 * COMBINATION OF COUNTY, AGE, SEX IN THE NUMERATOR.            --- ;
 * THE MOD3 MACRO ITERATES THROUGH EACH MEASURE IN THE          --- ;
 * PQE_AREA_MEASURES OUTPUT AND REDUCES THE AREA POPULATION BY  --- ;
 * THE NUMERATOR TOTAL. THE AREA POPULATION TOTALS ARE THEN     --- ;
 * ADJUSTED BASED ON THE MEASURE RELEVANT POPULATION. ONLY      --- ;
 * VALID AREA CODES ARE RETURNED. THE MOD3 MACRO INPUTS ARE:    --- ;
 * --- N - AREA MEASURE NUMBER                                  --- ;
 * --- PQ - THE ED PREVENTION QUALITY INDICATOR NAME WITH THE   --- ;
 *          PREFIX (A)                                          --- ;
 * ---------------------------------------------------------------- ;

%MACRO MOD3(N,PQ);
                                                                   
 /* CREATE TEMPORARY TABLE WITH ALL DISCHARGES IN NUMERATOR FOR MEASURE N. */  
 
 data TEMP_2;
     set TEMP0 (KEEP=KEY FIPSTCO T&PQ. POPCAT SEXCAT);
     if T&PQ. IN (1);
                           
	%CTY2MA
 run;
    
 /* SUM THE NUMERATOR 'T' FLAGS BY MAREA POPCAT SEXCAT. */
 
 proc   Summary data=TEMP_2 NWAY;
 class  MAREA POPCAT SEXCAT;
 var    T&PQ.;
 output out=TEMP_3 N=TCOUNT;
 run;

 proc   Sort data=TEMP_3;
 by     MAREA POPCAT SEXCAT;
 run;
    
 /* REDUCE THE DENOMINATOR POPULATION BY THE SUM OF THE NUMERATOR COUNT. */
 
 data   TEMP_4(drop=TCOUNT);
 merge  %IF &PQ.=AQE03 %THEN %DO;
        QIPOP(in=X keep=MAREA STATE POPCAT SEXCAT POPX rename=(POPX=POP)) 
        %END;
        %ELSE %DO;
        QIPOP(in=X keep=MAREA STATE POPCAT SEXCAT POP) 
        %END;
        TEMP_3(keep=MAREA POPCAT SEXCAT TCOUNT);
 by     MAREA POPCAT SEXCAT;

 if X;

 if TCOUNT > 0 then PCOUNT = POP - TCOUNT;
 else PCOUNT = POP;

 if PCOUNT < 0 then PCOUNT = 0;

 if PCOUNT = 0 then delete;

 run;
  
 /* FOR NUMERATOR, RETAIN ONLY RECORDS WITH A VALID MAREA CODE. */
 
 data   TEMP_3(drop=POP);
 merge  TEMP_3(in=X keep=MAREA POPCAT SEXCAT TCOUNT)
        QIPOP(keep=MAREA STATE POPCAT SEXCAT POP);
 by     MAREA POPCAT SEXCAT;

 if X;

 if POP <= 0 then PCOUNT = 0;
 else if TCOUNT > 0 then PCOUNT = TCOUNT;
 else PCOUNT = 0;

 if PCOUNT = 0 then delete;

 run;
    
 /* COMBINE THE NUMERATOR AND DENOMINATOR */

 data   TEMP1;
 set    TEMP_3(in=X) TEMP_4;

 if POPCAT IN (&&POPCAT_&PQ.);

 if X then T&PQ. = 1;
 else T&PQ. = 0;

 ATTRIB ONE LENGTH=3 LABEL='DUMMY ONE';                      
 ONE = 1;   
 
 run;
 
data TEMP1;
	set TEMP1;
    %IF &PQ. EQ AQE05 %THEN %DO ;
        IF INDEX("&StatesWithVisitlink_", STRIP(STATE)) > 0 ;
    %END ;    
	if SEXCAT in (2) then FEMALE = 1;
	else FEMALE = 0;

	 ARRAY ARRY1{18} AGECAT1-AGECAT18;
	 ARRAY ARRY2{18} FAGECAT1-FAGECAT18;
	 ARRAY ARRY3{10} POVCAT1-POVCAT10;
	 do I = 1 to 18;
	    ARRY1(I) = 0; ARRY2(I) = 0;
	 end;

	 ARRY1(POPCAT) = 1;
	 ARRY2(POPCAT) = FEMALE;

	 do I = 1 to 10;
    	ARRY3(I) = 0;
	 end;
     
   PVIDX = put(MAREA,$POVCAT.);

   if PVIDX > 0 then ARRY3(PVIDX) = 1;

   /*remove PVIDX=0 counties for SES risk-adjusted rate calculation, this happens to CT in v2024*/
   %if &USE_SES = 1 %then %do; 
     if PVIDX = 0 then delete; 
   %end;
   drop I;
run;

 * --- THIS DATA STEP READS THE REGRESSION COEFFICIENTS FOR EACH --- ;
 * --- COVARIATE.                                                --- ;

 %IF &USE_SES=0 %THEN %DO ;
    filename RACOEFFS "&RADIR./&PQ._Area_Covariates_v2024.csv";
 %END ;
 %ELSE %DO;
    filename RACOEFFS "&RADIR./&PQ._Area_Covariates_SES_v2024.csv";
 %END ;

 * --- LOAD CSV PARAMTERS & SHAPE DATA --- ;
 data TEMP1_MODEL ;
   length variable $32 df estimate 8 ;
   infile RACOEFFS DSD DLM=',' LRECL=1024 FIRSTOBS=2;
   input variable df estimate ;
 run ;

 proc TRANSPOSE data=TEMP1_MODEL out=TEMP2_MODEL;
     id variable;
     var estimate;
 run ;

 data TEMP2;
   set TEMP2_MODEL;

   _NAME_ = "MHAT" ;
   _TYPE_ = "PARMS" ;
 run ;

 data _null_;
    set TEMP1_MODEL end=LAST;
    format vars $5000.;
    retain vars;

    if variable ne "Intercept" then  vars = trim(vars)||" "||trim(variable);
    if LAST then call symput("VARS_",vars);
run;

 * --- THIS STEP CALCULATES A PREDICTED PREVENTION QUALITY INDICATOR BY  --- ;
 * --- MULTIPLYING THE STRATIFIED NUMERATOR AND DENOMINATOR TOTALS BY    --- ;
 * --- THE MEASURE COEFFICIENTS FROM THE COVARIATES FILE.                --- ;

 proc   SCORE data=TEMP1 SCORE=TEMP2 TYPE=PARMS OUT=TEMP1Y;
 var    &VARS_.;
 run;

 %let dsid=%sysfunc(open(temp1y));
 %let dnum=%sysfunc(attrn(&dsid,nobs));
 %let drc=%sysfunc(close(&dsid));

 %if &dnum ne 0 %then %do;

 data   TEMP1Y;
 set    TEMP1Y;

 EHAT = EXP(MHAT)/(1 + EXP(MHAT));
 run;


 *--- UPDATE EHAT TO EHAT*OE ACCORDING TO CALIBRATION_OE_TO_REF_POP --- ;
 *--- MACRO FLAG. USE THE MODIFIED VALUE OF EHAT GOING FORWARD.     --- ; 

%if &Calibration_OE_to_ref_pop. = 1 %then %do;
 DATA TEMP1Y;  
    SET TEMP1Y; 
     * --- SWITCH OE RATIO BASED ON USE_SES FLAG --- ;
    %IF &USE_SES = 0 %THEN %DO ;
      %include MacLib(PQE_AREA_OE_Array_v2024.SAS);
    %END ;
    %ELSE %DO ;
      %include MacLib(PQE_AREA_OE_Array_SES_v2024.SAS);
    %END ;   
    
    * --- MAP MEASURE NUM TO ARRAY INDEX SUB_N --- ;
    if "&PQ." = "AQE01"      then SUB_N = 1;
    if "&PQ." = "AQE02"      then SUB_N = 2;
    if "&PQ." = "AQE03"      then SUB_N = 3;
    if "&PQ." = "AQE04"      then SUB_N = 4;
    if "&PQ." = "AQE05"      then SUB_N = 5;
    EHAT=EHAT*ARRYAOE(SUB_N);
    IF EHAT > 0.99 THEN EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT); 
    ONE=1;   
 RUN;
%end;
%else %if &Calibration_OE_to_ref_pop. = 0 %then %do; 
 PROC MEANS DATA=TEMP1Y noprint;
    VAR T&PQ. EHAT;
    WEIGHT PCOUNT;
    OUTPUT OUT=OE&PQ.(DROP=_TYPE_ _FREQ_) SUM(T&PQ. EHAT)=T&PQ. EHAT;
 RUN;

 DATA OE&PQ.;
    SET OE&PQ.;
    O_E&PQ.=T&PQ./EHAT;
 RUN;

 PROC PRINT DATA=OE&PQ.;
 RUN;

 DATA OE&PQ.;
    SET OE&PQ.(KEEP=O_E&PQ.);
 RUN;

 DATA TEMP1Y;  
    IF _N_=1 THEN SET OE&PQ.;
    SET TEMP1Y;
    EHAT=EHAT*O_E&PQ.;
    IF EHAT > 0.99 THEN EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT);    
    ONE=1;
 RUN;
%end;

 proc   SUMMARY data=TEMP1Y;
 class  MAREA POPCAT SEXCAT;
 var    T&PQ. EHAT PHAT ONE;
 output OUT=R&PQ. SUM(T&PQ. EHAT PHAT ONE)=T&PQ. EHAT PHAT P&PQ.;
 WEIGHT PCOUNT;
 run;

 data   R&PQ.(keep=MAREA POPCAT SEXCAT _TYPE_
                   E&PQ. R&PQ. L&PQ. U&PQ. S&PQ. X&PQ. VAR&PQ. SN&PQ.); 
 set    R&PQ.;

 if _TYPE_ in (&TYPELVLA);

  * --- SWITCH SIGNAL VARIANCE BASED ON USE_SES FLAG --- ;
 %IF &USE_SES = 0 %THEN %DO ;
   %include MacLib(PQE_AREA_Sigvar_Array_v2024.SAS);
 %END ;
 %ELSE %DO ;
   %include MacLib(PQE_AREA_Sigvar_Array_SES_v2024.SAS);
 %END ;

 if &N. = 1 then SUB_N = 1;
 if &N. = 2 then SUB_N = 2;
 if &N. = 3 then SUB_N = 3;
 if &N. = 4 then SUB_N = 4;
 if &N. = 5 then SUB_N = 5;
 
 E&PQ. = EHAT / P&PQ.;
 THAT = T&PQ. / P&PQ.;
 
 if _TYPE_ in (0,4) then do;
    R&PQ.   = (THAT / E&PQ.) * ARRYA3(SUB_N);
    SE&PQ.  = (ARRYA3(SUB_N) / E&PQ.) * (1 / P&PQ.) * SQRT(PHAT);
    VAR&PQ. = SE&PQ.**2;
    SN&PQ.  = ARRYA2(SUB_N) / (ARRYA2(SUB_N) + VAR&PQ.);
    S&PQ.   = (R&PQ. * SN&PQ.) + ((1 -  SN&PQ.) * ARRYA3(SUB_N));
    X&PQ.   = SQRT(ARRYA2(SUB_N)- (SN&PQ. * ARRYA2(SUB_N)));
 end;
 else do;
    R&PQ.   = (THAT / E&PQ.);
    SE&PQ.  = (1 / E&PQ.) * (1 / P&PQ.) * SQRT(PHAT);
    VAR&PQ. = SE&PQ.**2;
    SN&PQ.  = .;
    S&PQ.   = .;
    X&PQ.   = .;
 end;

 L&PQ.   = R&PQ. - (1.96 * SE&PQ.);
 if L&PQ. < 0 then L&PQ. = 0;
 U&PQ.   = R&PQ. + (1.96 * SE&PQ.);


 if _TYPE_ in (0,4) then do;  
     if L&PQ. > 1 then L&PQ. = 1; 
     if U&PQ. > 1 then U&PQ. = 1;
     if R&PQ. > 1 then R&PQ. = 1;
     if S&PQ. > 1 then S&PQ. = 1;
 end;

 run;

 %end;
 %else %do;

 data   R&PQ.;
    MAREA='';POPCAT=.;SEXCAT=.;_TYPE_=0;E&PQ=.;R&PQ=.;L&PQ=.;U&PQ=.;S&PQ=.;X&PQ=.;VAR&PQ=.;SN&PQ=.; 
    output;
 run;
 
 %end;

 proc Sort data=R&PQ.;
   by MAREA POPCAT SEXCAT;
 run; quit;

*-- DELETE TEMPORARY DATASETS IN PREPARATION FOR RISK ADJUSTMENT OF THE NEXT MEASURE;
 proc   DATASETS NOLIST;
 delete TEMP1 TEMP1Y TEMP2;
 run;


%MEND;
%MOD3(01, AQE01);
%MOD3(02, AQE02);
%MOD3(03, AQE03);
%MOD3(04, AQE04);
%MOD3(05, AQE05);

 * --- MERGES THE MAREA ADJUSTED RATES FOR EACH PREVENTION QUALITY --- ;
 * --- INDICATOR.  PREFIX FOR THE ADJUSTED RATES IS R (Risk        --- ;
 * --- Adjusted).                                                  --- ;
data   RISKADJ;
 merge   RAQE01(keep=MAREA POPCAT SEXCAT EAQE01 RAQE01 LAQE01 UAQE01 SAQE01 SNAQE01 VARAQE01 XAQE01 rename=(VARAQE01=VAQE01))
		 RAQE02(keep=MAREA POPCAT SEXCAT EAQE02 RAQE02 LAQE02 UAQE02 SAQE02 SNAQE02 VARAQE02 XAQE02 rename=(VARAQE02=VAQE02))
		 RAQE03(keep=MAREA POPCAT SEXCAT EAQE03 RAQE03 LAQE03 UAQE03 SAQE03 SNAQE03 VARAQE03 XAQE03 rename=(VARAQE03=VAQE03))
		 RAQE04(keep=MAREA POPCAT SEXCAT EAQE04 RAQE04 LAQE04 UAQE04 SAQE04 SNAQE04 VARAQE04 XAQE04 rename=(VARAQE04=VAQE04))
		 RAQE05(keep=MAREA POPCAT SEXCAT EAQE05 RAQE05 LAQE05 UAQE05 SAQE05 SNAQE05 VARAQE05 XAQE05 rename=(VARAQE05=VAQE05))
        ;
 by     MAREA POPCAT SEXCAT;


 %macro label_qis(qi_num=, qi_name=);
   label 
   E&qi_num.  = "&qi_name. (Expected rate)"
   R&qi_num.  = "&qi_name. (Risk-adjusted rate)"
   L&qi_num.  = "&qi_name. (Lower CL of risk-adjusted rate)"
   U&qi_num.  = "&qi_name. (Upper CL of risk-adjusted rate)"
   S&qi_num.  = "&qi_name. (Smoothed rate)"
   X&qi_num.  = "&qi_name. (Standard error of the smoothed rate)"
   V&qi_num.  = "&qi_name. (Variance of the risk-adjusted rate)"
   SN&qi_num. = "&qi_name. (Reliability of the risk-adjusted rate)"
   ;
 %mend label_qis;
 %label_qis(qi_num=AQE01, qi_name=PQE 01 Visits for Non-Traumatic Dental Conditions in ED);
 %label_qis(qi_num=AQE02, qi_name=PQE 02 Visits for Chronic Ambulatory Care Sensitive Conditions in ED);
 %label_qis(qi_num=AQE03, qi_name=PQE 03 Visits for Acute Ambulatory Care Sensitive Conditions in ED); 
 %label_qis(qi_num=AQE04, qi_name=PQE 04 Visits for Asthma in ED);
 %label_qis(qi_num=AQE05, qi_name=PQE 05 Visits for Back Pain in ED);

 run;

*=================================================================================;
*  PART II: MERGE AREA RATES FOR AHRQ PREVENTION QUALITY INDICATORS IN ED SETTINGS
*=================================================================================;
 
 * ------------------------------------------------------------------------- ;
 * --- PREVENTION QUALITY INDICATOR IN EMERGENCY DEPARTMENT MERGED RATES --- ;
 * ------------------------------------------------------------------------- ;
 data   OUTARSK.&OUTFILE_AREARISK.;
 merge  OUTAOBS.&OUTFILE_AREAOBS.(
            keep=MAREA POPCAT SEXCAT _TYPE_ 
                 TAQE01 TAQE02 TAQE03 TAQE04 TAQE05 
                 PAQE01 PAQE02 PAQE03 PAQE04 PAQE05  
                 OAQE01 OAQE02 OAQE03 OAQE04 OAQE05)
        RISKADJ(
            keep=MAREA POPCAT SEXCAT
                 EAQE01 EAQE02 EAQE03 EAQE04 EAQE05 
                 RAQE01 RAQE02 RAQE03 RAQE04 RAQE05 
                 LAQE01 LAQE02 LAQE03 LAQE04 LAQE05 
                 UAQE01 UAQE02 UAQE03 UAQE04 UAQE05 
                 SAQE01 SAQE02 SAQE03 SAQE04 SAQE05 
                 SNAQE01 SNAQE02 SNAQE03 SNAQE04 SNAQE05
                 XAQE01 XAQE02 XAQE03 XAQE04 XAQE05 
                 VAQE01 VAQE02 VAQE03 VAQE04 VAQE05);
 by     MAREA POPCAT SEXCAT;

 array ARRY1{5} EAQE01 EAQE02 EAQE03 EAQE04 EAQE05;
 array ARRY2{5} RAQE01 RAQE02 RAQE03 RAQE04 RAQE05;
 array ARRY3{5} LAQE01 LAQE02 LAQE03 LAQE04 LAQE05;
 array ARRY4{5} UAQE01 UAQE02 UAQE03 UAQE04 UAQE05;
 array ARRY5{5} SAQE01 SAQE02 SAQE03 SAQE04 SAQE05;
 array ARRY6{5} XAQE01 XAQE02 XAQE03 XAQE04 XAQE05;
 array ARRY7{5} PAQE01 PAQE02 PAQE03 PAQE04 PAQE05;
 array ARRY8{5} VAQE01 VAQE02 VAQE03 VAQE04 VAQE05;
 array ARRY9{5} SNAQE01 SNAQE02 SNAQE03 SNAQE04 SNAQE05;

 do I = 1 TO 5;
   if ARRY7(I) <= 2 then do;
      ARRY1(I) = .; ARRY2(I) = .; ARRY3(I) = .; ARRY4(I) = .;
      ARRY5(I) = .; ARRY6(I) = .; ARRY8(I) = .; ARRY9(I) = .;
   end;
 end;

 DROP I;

 format EAQE01 EAQE02 EAQE03 EAQE04 EAQE05 
        LAQE01 LAQE02 LAQE03 LAQE04 LAQE05
        OAQE01 OAQE02 OAQE03 OAQE04 OAQE05 
        RAQE01 RAQE02 RAQE03 RAQE04 RAQE05 
        SAQE01 SAQE02 SAQE03 SAQE04 SAQE05 
        SNAQE01 SNAQE02 SNAQE03 SNAQE04 SNAQE05 
        UAQE01 UAQE02 UAQE03 UAQE04 UAQE05
        VAQE01 VAQE02 VAQE03 VAQE04 VAQE05
        XAQE01 XAQE02 XAQE03 XAQE04 XAQE05 13.7
        TAQE01 TAQE02 TAQE03 TAQE04 TAQE05
        PAQE01 PAQE02 PAQE03 PAQE04 PAQE05 13.0;
 run;

 * ---------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MAREA MERGED OUTPUT FILE           --- ;
 * ---------------------------------------------------------------- ;

 proc Contents data=OUTARSK.&OUTFILE_AREARISK. POSITION;
 run;

 proc Means data=OUTARSK.&OUTFILE_AREARISK.(WHERE=(_TYPE_ in (4))) N NMISS MIN MAX MEAN SUM NOLABELS;
 title4 'SUMMARY OF AREA-LEVEL RATES (_TYPE_=4)';
 run;

 * ---------------------------------------------------------------- ;
 * --- PRINT AREA MERGED OUTPUT FILE                            --- ;
 * ---------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PQ,TEXT);
 proc  PRINT data=OUTARSK.&OUTFILE_AREARISK. label SPLIT='*';
 var   MAREA POPCAT SEXCAT 
       TAQE&PQ. PAQE&PQ. OAQE&PQ. EAQE&PQ. RAQE&PQ. LAQE&PQ. UAQE&PQ. SAQE&PQ. SNAQE&PQ. VAQE&PQ. XAQE&PQ.;
 label MAREA    = "Metro Area Level"
       POPCAT   = "Population Age Categories"
       SEXCAT   = "Sex Categories"
       TAQE&PQ. = "TAQE&PQ.*(Numerator)"
       PAQE&PQ. = "PAQE&PQ.*(Population)"
       OAQE&PQ. = "OAQE&PQ.*(Observed rate)"
       EAQE&PQ. = "EAQE&PQ.*(Expected rate)"
       RAQE&PQ. = "RAQE&PQ.*(Risk-adjusted rate)"
       LAQE&PQ. = "LAQE&PQ.*(Lower CL of risk-adjusted rate)"
       UAQE&PQ. = "UAQE&PQ.*(Upper CL of risk-adjusted rate)"
       SAQE&PQ. = "SAQE&PQ.*(Smoothed rate)"
       SNAQE&PQ.= "SNAQE&PQ.*(Reliability of the risk-adjusted rate)"
       XAQE&PQ. = "XAQE&PQ.*(Standard error of the smoothed rate)"
       VAQE&PQ. = "VAQE&PQ.*(Variance of the risk-adjusted rate)"
       ;

 format POPCAT POPCAT.   
        SEXCAT SEXCAT.
      TAQE&PQ. PAQE&PQ. COMMA13.0
        OAQE&PQ. EAQE&PQ. RAQE&PQ. LAQE&PQ. UAQE&PQ. SAQE&PQ. SNAQE&PQ.  VAQE&PQ. XAQE&PQ. 8.6;

 title4 "FINAL OUTPUT";
 title5 "Indicator  &PQ.: &TEXT";

 run;

 %MEND PRT;

 %PRT(01,Visits for Non-Traumatic Dental Conditions in ED);
 %PRT(02,Visits for Chronic Ambulatory Care Sensitive Conditions in ED);
 %PRT(03,Visits for Acute Ambulatory Care Sensitive Conditions in ED); 
 %PRT(04,Visits for Asthma in ED);
 %PRT(05,Visits for Back Pain in ED);

 %END;

 %MEND PRT2 ;

 %PRT2;

 * ---------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO TEXT FILE                   --- ;
 * ---------------------------------------------------------------- ;

 %MACRO TEXT;
 
 %macro scale_rates;
   
   %IF &SCALE_RATES = 1 %THEN %DO;
      ARRAY RATES OAQE: EAQE: RAQE: LAQE: UAQE: SAQE:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*100000;	
	  end;
	%END;
	
 %mend scale_rates;

 %IF &TXTARSK. = 1  %THEN %DO;
	%LET TYPEARN  = %sysfunc(tranwrd(%quote(&TYPELVLA.),%str(,),_));
	%LET TYPEARN2  = %sysfunc(compress(&TYPEARN.,'(IN )'));
	%let QECSVREF  = %sysfunc(pathname(QETXTARA));
	%let QECSVRF2 =  %sysfunc(tranwrd(&QECSVREF.,.TXT,_&TYPEARN2..TXT));

 data _NULL_;
 set OUTARSK.&OUTFILE_AREARISK;
 FILE "&QECSVRF2." lrecl=2000;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_AREARISK data set created with the following CONTROL options:";
 put "&&MALEVL&MALEVL (MALEVL = &MALEVL)";
 put "Population year (POPYEAR) = &POPYEAR";
 put "&&Calibration_OE_to_ref_pop&Calibration_OE_to_ref_pop. (Calibration_OE_to_ref_pop = &Calibration_OE_to_ref_pop)";
 put "States with valid revisit variables (StatesWithVisitlink_) = &StatesWithVisitlink_";
 put "Output stratification includes TYPELVLA = &TYPELVLA";
 put "&&USE_SES&USE_SES (USE_SES = &USE_SES)"; 
 put "Number of diagnoses evaluated = &NDX";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "MAREA" "," "Age" "," "Sex" "," "Type" ","
 "TAQE01" "," "TAQE02" "," "TAQE03" "," "TAQE04" "," "TAQE05" ","
 "PAQE01" "," "PAQE02" "," "PAQE03" "," "PAQE04" "," "PAQE05" ","
 "OAQE01" "," "OAQE02" "," "OAQE03" "," "OAQE04" "," "OAQE05" ","
 "EAQE01" "," "EAQE02" "," "EAQE03" "," "EAQE04" "," "EAQE05" ","
 "RAQE01" "," "RAQE02" "," "RAQE03" "," "RAQE04" "," "RAQE05" ","
 "LAQE01" "," "LAQE02" "," "LAQE03" "," "LAQE04" "," "LAQE05" ","
 "UAQE01" "," "UAQE02" "," "UAQE03" "," "UAQE04" "," "UAQE05" ","
 "SAQE01" "," "SAQE02" "," "SAQE03" "," "SAQE04" "," "SAQE05" ","
 "SNAQE01" "," "SNAQE02" "," "SNAQE03" "," "SNAQE04" "," "SNAQE05" ","
 "VAQE01" "," "VAQE02" "," "VAQE03" "," "VAQE04" "," "VAQE05" ","
 "XAQE01" "," "XAQE02" "," "XAQE03" "," "XAQE04" "," "XAQE05"
  ;
 end;
 
 put MAREA  $5. "," POPCAT 3. "," SEXCAT 3. "," _TYPE_ 2.  ","
 (TAQE01 TAQE02 TAQE03 TAQE04 TAQE05) (7.0 ",")
  ","
 (PAQE01 PAQE02 PAQE03 PAQE04 PAQE05) (13.0 ",")
 ","
 (OAQE01 OAQE02 OAQE03 OAQE04 OAQE05) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (EAQE01 EAQE02 EAQE03 EAQE04 EAQE05) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (RAQE01 RAQE02 RAQE03 RAQE04 RAQE05) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (LAQE01 LAQE02 LAQE03 LAQE04 LAQE05) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (UAQE01 UAQE02 UAQE03 UAQE04 UAQE05) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (SAQE01 SAQE02 SAQE03 SAQE04 SAQE05) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (SNAQE01 SNAQE02 SNAQE03 SNAQE04 SNAQE05) (12.10 ",")
 ","
 (VAQE01 VAQE02 VAQE03 VAQE04 VAQE05) (12.10 ",")
 ","
 (XAQE01 XAQE02 XAQE03 XAQE04 XAQE05) (12.10 ",")
 ;
 run;

 %END;

 %MEND TEXT;

 %TEXT;
