* ================== Program: PQI_AREA_RISKADJ.SAS ==================;
*
*  TITLE:  AREA LEVEL RISK ADJUSTED RATES FOR AHRQ 
*          PREVENTION QUALITY INDICATORS
*
*  DESCRIPTION:
*         Calculates risk-adjusted and smoothed rates for
*         Prevention Quality Indicators across stratifiers.
*         Variables created by this program are EAPQxx, RAPQxx, 
*         LAPQxx, UAPQxx, SAPQxx, SNAPQxx, VAPQxx, XAPQxx
*         Output stratified by AGE, SEXCAT and POVCAT from
*         population file and PQI_AREA_MEASURES output.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*====================================================================;

 title2 'PROGRAM PQI_AREA_RISKADJ PART I';
 title3 'AHRQ PREVENTION QUALITY INDICATORS: CALCULATE ADJUSTED AREA RATES';

 * ------------------------------------------------------------------- ;
 * --- PREVENTION QUALITY INDICATOR (PQI) NAMING CONVENTION:       --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PREVENTION QUALITY          --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:                          --- ;
 * ---       (T) NUMERATOR ("TOP") - FROM PQI_AREA_MEASURES        --- ;
 * ---       (P) DENOMINATOR ("POP") - ADJUSTED FROM POPULATION FILE - ;
 * ---       (O) OBSERVED RATES (T/P)                              --- ;
 * ---       (E) EXPECTED RATE                                     --- ;
 * ---       (R) RISK-ADJUSTED RATE                                --- ;
 * ---       (L) LOWER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE     --- ;
 * ---       (U) UPPER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE     --- ;
 * ---       (S) SMOOTHED RATE (NOT REPORTED FOR STRATA)           --- ;
 * ---       (X) SMOOTHED RATE STANDARD ERROR (NOT REPORTED FOR STRATA);
 * --- THE SECOND LETTER IDENTIFIES THE PQI AS AREA (A) LEVEL      --- ;
 * --- INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS 'PQ'.        --- ;
 * --- THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.               --- ;
 * ------------------------------------------------------------------- ;

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR                               --- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE     --- ;
 * --- OUTPUT FROM PQI_AREA_MEASURES.                           --- ;
 * ---------------------------------------------------------------- ;

 * --- MACRO TO ADJUST AREA AGGREGATION BASED ON MAREA VALUE IN PQI_AREA_CONTROL --- ;
 
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

 data TEMP0 (keep=MAREA);
 set    OUTMSR.&OUTFILE_MEAS.;

 %CTY2MA

 run;

 * --- IDENTIFY UNIQUE MAREA VALUES IN PQI_AREA_MEASURES OUTPUT --- ;
 
 proc   Sort data=TEMP0 OUT=MAREA NODUPKEY;
 by     MAREA;
 run;

 * --- LOAD POPULATION FOR MAREA LEVEL AND YEAR IN PQI_AREA_CONTROL --- ;
 
 data QIPOP0;
    length FIPSTCO $5 SEXCAT POPCAT AGECAT RACECAT 3 
            
           POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
           POP_2005 POP_2006 POP_2007 POP_2008 POP_2009
           POP_2010 POP_2011 POP_2012 POP_2013 POP_2014
           POP_2015 POP_2016 POP_2017 POP_2018 POP_2019
           POP_2020 POP_2021 POP_2022 POP_2023 POP 8;

    infile POPFILE missover FIRSTOBS=2;

    input FIPSTCO SEXCAT POPCAT RACECAT 
           
          POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
          POP_2005 POP_2006 POP_2007 POP_2008 POP_2009
          POP_2010 POP_2011 POP_2012 POP_2013 POP_2014
          POP_2015 POP_2016 POP_2017 POP_2018 POP_2019
          POP_2020 POP_2021 POP_2022 POP_2023;

    %CTY2MA

    if POPCAT in (1,2,3,4)            then AGECAT = 0;
    else if POPCAT in (5,6,7,8)       then AGECAT = 1;
    else if POPCAT in (9,10,11,12,13) then AGECAT = 2;
    else if POPCAT in (14,15)         then AGECAT = 3;
    else                                   AGECAT = 4;

    POP = POP_&POPYEAR.;

 run;

 proc   SUMMARY data=QIPOP0 NWAY;
 class  MAREA POPCAT AGECAT SEXCAT RACECAT;
 var    POP;
 output OUT=QIPOP SUM=;
 run;

 proc   Sort data=QIPOP;
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;
 run;

 * --- LIMIT POPULATION TOTALS TO MAREA CODES FOUND IN PQI_AREA_MEASURES OUTPUT. --- ;

 data   QIPOP(keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 merge  MAREA(in=X) QIPOP(in=Y);
 by     MAREA;

 if X and Y;

 run;

 * ---------------------------------------------------------------- ;
 * --- PREVENTION QUALITY INDICATORS ADJUSTED RATES --------------- ;
 * ---------------------------------------------------------------- ;
 * AREA-LEVEL INDICATOR DENOMINATORS ARE ADJUSTED BASED ON THE  --- ;
 * COMBINATION OF COUNTY, AGE, SEX, AND RACE IN THE NUMERATOR.  --- ;
 * THE MOD3 MACRO ITERATES THROUGH EACH MEASURE IN THE          --- ;
 * PQI_AREA_MEASURES OUTPUT AND REDUCES THE AREA POPULATION BY THE  ;
 * NUMERATOR TOTAL. THE AREA POPULATION TOTALS ARE THEN ADJUSTED -- ;
 * BASED ON THE MEASURE RELEVANT POPULATION. ONLY VALID AREA    --- ;
 * CODES ARE RETURNED. THE MOD3 MACRO INPUTS ARE:               --- ;
 * --- N - AREA MEASURE NUMBER                                  --- ;
 * --- PQ - THE PREVENTION QUALITY INDICATOR NAME WITHOUT THE   --- ;
 *          PREFIX (A)                                          --- ;
 * ---------------------------------------------------------------- ;

 %MACRO MOD3(N,PQ);

 * --- THIS SET CREATES TEMP1 WHICH CONTAINS THE DEPENDENT      --- ;
 * --- VARIABLE (TPQ) AND INDEPENDENT VARIABLES USED IN         --- ;
 * --- REGRESSION.  IT APPENDS TO THE DISCHARGE DATA ONE        --- ;
 * --- OBSERVATION PER MAREA AND DEMOGRAPHIC GROUP.             --- ;

 data   TEMP_2;
 set    OUTMSR.&OUTFILE_MEAS. (keep=KEY FIPSTCO T&PQ. POPCAT AGECAT SEXCAT RACECAT);

 if T&PQ. in (1);

 %CTY2MA

 run;

 * --- SUM THE NUMERATOR 'T' FLAGS BY MAREA POPCAT AGECAT SEXCAT RACECAT --- ;
 
 proc   SUMMARY data=TEMP_2 NWAY;
 class  MAREA POPCAT AGECAT SEXCAT RACECAT;
 var    T&PQ.;
 output OUT=TEMP_3 N=TCOUNT;
 run;

 proc   Sort data=TEMP_3;
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;
 run;

 * --- REDUCE THE DENOMINATOR POPULATION BY THE SUM OF THE NUMERATOR COUNT --- ;

 data   TEMP_4(DROP=TCOUNT);
 merge  QIPOP(in=X keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP) 
        TEMP_3(keep=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT);
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;

 if X;

 if TCOUNT > 0 then PCOUNT = POP - TCOUNT;
 else PCOUNT = POP;

 if PCOUNT < 0 then PCOUNT = 0;

 if AGECAT in (0) then PCOUNT = 0;

 N = &N.;

 if N in (5) and AGECAT in (1) then PCOUNT = 0;
 if N in (15) and AGECAT in (2,3,4) then PCOUNT = 0;


 if PCOUNT = 0 then delete;

 run;

 * --- FOR NUMERATOR, RETAIN ONLY RECORDS WITH A VALID MAREA CODE --- ;

 data   TEMP_3(DROP=POP);
 merge  TEMP_3(in=X keep=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT)
        QIPOP(keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;

 if X;

 if POP < 0 then PCOUNT = 0;
 else if TCOUNT > 0 then PCOUNT = TCOUNT;
 else PCOUNT = 0;

 if PCOUNT = 0 then delete;

 run;

 * --- COMBINE THE NUMERATOR AND DENOMINATOR --- ;

 data   TEMP1;
 set    TEMP_3(in=X) TEMP_4;

 if X then T&PQ. = 1;
 else T&PQ. = 0;

 run;

 data   TEMP1;
 length FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14
        POVCAT1-POVCAT10 3;
 set    TEMP1;

 if SEXCAT in (2) then FEMALE = 1;
 else FEMALE = 0;

 array ARRY1{14} AGECAT1-AGECAT14;
 array ARRY2{14} FAGECAT1-FAGECAT14;

 do I = 1 TO 14;
    ARRY1(I) = 0; ARRY2(I) = 0;
 end;

 N = &N.;

 if N NOTIN (9) then ARRY1(POPCAT-4) = 1;
 if N NOTIN (9) then ARRY2(POPCAT-4) = FEMALE;

 array ARRY3{10} POVCAT1-POVCAT10;

 do I = 1 TO 10;
    ARRY3(I) = 0;
 end;

 PVIDX = put(MAREA,$POVCAT.);

 if PVIDX > 0 then ARRY3(PVIDX) = 1;

 /*remove PVIDX=0 counties for SES risk-adjusted rate calculation, this happens to CT in v2024*/
 %if &USE_SES = 1 %then %do; 
   if PVIDX = 0 then delete; 
 %end;
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


 *--- UPDATE EHAT TO EHAT*O_E ACCORDING TO CALIBRATION_OE_TO_REF_POP --- ;
 *--- MACRO FLAG. USE THE MODIFIED VALUE OF EHAT GOING FORWARD.      --- ; 

%if &Calibration_OE_to_ref_pop. = 1 %then %do;
 DATA TEMP1Y;  
    SET TEMP1Y; 
     * --- SWITCH OE RATIO BASED ON USE_SES FLAG --- ;
    %IF &USE_SES = 0 %THEN %DO ;
      %include MacLib(PQI_AREA_OE_Array_v2024.SAS);
    %END ;
    %ELSE %DO ;
      %include MacLib(PQI_AREA_OE_Array_SES_v2024.SAS);
    %END ;   
    
    * --- MAP MEASURE NUM TO ARRAY INDEX SUB_N --- ;
    if "&PQ." = "APQ01"      then SUB_N = 1;
    if "&PQ." = "APQ03"      then SUB_N = 2;
    if "&PQ." = "APQ05"      then SUB_N = 3;
    if "&PQ." = "APQ07"      then SUB_N = 4;
    if "&PQ." = "APQ08"      then SUB_N = 5;
    if "&PQ." = "APQ11"      then SUB_N = 6;
    if "&PQ." = "APQ12"      then SUB_N = 7;
    if "&PQ." = "APQ14"      then SUB_N = 8;
    if "&PQ." = "APQ15"      then SUB_N = 9;
    if "&PQ." = "APQ16"      then SUB_N = 10;
    if "&PQ." = "APQ90"      then SUB_N = 11;
    if "&PQ." = "APQ91"      then SUB_N = 12;
    if "&PQ." = "APQ92"      then SUB_N = 13;
    if "&PQ." = "APQ93"      then SUB_N = 14;

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
 class  MAREA AGECAT SEXCAT RACECAT;
 var    T&PQ. EHAT PHAT ONE;
 output OUT=R&PQ. SUM(T&PQ. EHAT PHAT ONE)=T&PQ. EHAT PHAT P&PQ.;
 WEIGHT PCOUNT;
 run;

 data   R&PQ.(keep=MAREA AGECAT SEXCAT RACECAT _TYPE_
                   E&PQ. R&PQ. L&PQ. U&PQ. S&PQ. X&PQ. VAR&PQ. SN&PQ.); 
 set    R&PQ.;

 if _TYPE_ &TYPELVLA;

 * --- SWITCH SIGNAL VARIANCE BASED ON USE_SES FLAG --- ;
 %IF &USE_SES = 0 %THEN %DO ;
   %include MacLib(PQI_AREA_Sigvar_Array_v2024.SAS);
 %END ;
 %ELSE %DO ;
   %include MacLib(PQI_AREA_Sigvar_Array_SES_v2024.SAS);
 %END ;

 if &N. = 1 then SUB_N = 1;
 
 if &N. = 3 then SUB_N = 2;
 if &N. = 5 then SUB_N = 3;
 if &N. = 7 then SUB_N = 4;
 if &N. = 8 then SUB_N = 5;
 
 if &N. = 11 then SUB_N = 6;
 if &N. = 12 then SUB_N = 7;
 if &N. = 14 then SUB_N = 8;
 if &N. = 15 then SUB_N = 9;
 if &N. = 16 then SUB_N = 10;
 if &N. = 90 then SUB_N = 11;
 if &N. = 91 then SUB_N = 12;
 if &N. = 92 then SUB_N = 13;
 if &N. = 93 then SUB_N = 14;

 E&PQ. = EHAT / P&PQ.;
 THAT = T&PQ. / P&PQ.;
 
 if _TYPE_ in (0,8) then do;
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


 if _TYPE_ in (0,8) then do;  
     if L&PQ. > 1 then L&PQ. = 1; 
     if U&PQ. > 1 then U&PQ. = 1;
     if R&PQ. > 1 then R&PQ. = 1;
     if S&PQ. > 1 then S&PQ. = 1;
 end;

 run;

 %end;
 %else %do;

 data   R&PQ.;
    MAREA='';AGECAT=.;SEXCAT=.;RACECAT=.;_TYPE_=0;E&PQ=.;R&PQ=.;L&PQ=.;U&PQ=.;S&PQ=.;X&PQ=.;VAR&PQ=.;SN&PQ=.; 
    output;
 run;
 
 %end;


 proc Sort data=R&PQ.;
   by MAREA AGECAT SEXCAT RACECAT;
 run; quit;

*-- DELETE TEMPORARY DATASETS IN PREPARATION FOR RISK ADJUSTMENT OF THE NEXT MEASURE;
 proc   DATASETS NOLIST;
 delete TEMP1 TEMP1Y TEMP2;
 run;

 %MEND;

 %MOD3(1,APQ01);
 %MOD3(3,APQ03);
 %MOD3(5,APQ05);
 %MOD3(7,APQ07);
 %MOD3(8,APQ08);
 %MOD3(11,APQ11);
 %MOD3(12,APQ12);
 %MOD3(14,APQ14);
 %MOD3(15,APQ15);
 %MOD3(16,APQ16);
 %MOD3(90,APQ90);
 %MOD3(91,APQ91);
 %MOD3(92,APQ92);
 %MOD3(93,APQ93);

 * --- MERGES THE MAREA ADJUSTED RATES FOR EACH PREVENTION QUALITY --- ;
 * --- INDICATOR.  PREFIX FOR THE ADJUSTED RATES IS R (RISK        --- ;
 * --- ADJUSTED).                                                  --- ;
 
 data   RISKADJ;
 merge  RAPQ01(keep=MAREA AGECAT SEXCAT RACECAT EAPQ01 RAPQ01 LAPQ01 UAPQ01 SAPQ01 SNAPQ01 VARAPQ01 XAPQ01 rename=(VARAPQ01=VAPQ01))
        RAPQ03(keep=MAREA AGECAT SEXCAT RACECAT EAPQ03 RAPQ03 LAPQ03 UAPQ03 SAPQ03 SNAPQ03 VARAPQ03 XAPQ03 rename=(VARAPQ03=VAPQ03))
        RAPQ05(keep=MAREA AGECAT SEXCAT RACECAT EAPQ05 RAPQ05 LAPQ05 UAPQ05 SAPQ05 SNAPQ05 VARAPQ05 XAPQ05 rename=(VARAPQ05=VAPQ05))
        RAPQ07(keep=MAREA AGECAT SEXCAT RACECAT EAPQ07 RAPQ07 LAPQ07 UAPQ07 SAPQ07 SNAPQ07 VARAPQ07 XAPQ07 rename=(VARAPQ07=VAPQ07))
        RAPQ08(keep=MAREA AGECAT SEXCAT RACECAT EAPQ08 RAPQ08 LAPQ08 UAPQ08 SAPQ08 SNAPQ08 VARAPQ08 XAPQ08 rename=(VARAPQ08=VAPQ08))
        RAPQ11(keep=MAREA AGECAT SEXCAT RACECAT EAPQ11 RAPQ11 LAPQ11 UAPQ11 SAPQ11 SNAPQ11 VARAPQ11 XAPQ11 rename=(VARAPQ11=VAPQ11))
        RAPQ12(keep=MAREA AGECAT SEXCAT RACECAT EAPQ12 RAPQ12 LAPQ12 UAPQ12 SAPQ12 SNAPQ12 VARAPQ12 XAPQ12 rename=(VARAPQ12=VAPQ12))       
        RAPQ14(keep=MAREA AGECAT SEXCAT RACECAT EAPQ14 RAPQ14 LAPQ14 UAPQ14 SAPQ14 SNAPQ14 VARAPQ14 XAPQ14 rename=(VARAPQ14=VAPQ14))
        RAPQ15(keep=MAREA AGECAT SEXCAT RACECAT EAPQ15 RAPQ15 LAPQ15 UAPQ15 SAPQ15 SNAPQ15 VARAPQ15 XAPQ15 rename=(VARAPQ15=VAPQ15))
        RAPQ16(keep=MAREA AGECAT SEXCAT RACECAT EAPQ16 RAPQ16 LAPQ16 UAPQ16 SAPQ16 SNAPQ16 VARAPQ16 XAPQ16 rename=(VARAPQ16=VAPQ16))
        RAPQ90(keep=MAREA AGECAT SEXCAT RACECAT EAPQ90 RAPQ90 LAPQ90 UAPQ90 SAPQ90 SNAPQ90 VARAPQ90 XAPQ90 rename=(VARAPQ90=VAPQ90))
        RAPQ91(keep=MAREA AGECAT SEXCAT RACECAT EAPQ91 RAPQ91 LAPQ91 UAPQ91 SAPQ91 SNAPQ91 VARAPQ91 XAPQ91 rename=(VARAPQ91=VAPQ91)) 
        RAPQ92(keep=MAREA AGECAT SEXCAT RACECAT EAPQ92 RAPQ92 LAPQ92 UAPQ92 SAPQ92 SNAPQ92 VARAPQ92 XAPQ92 rename=(VARAPQ92=VAPQ92))
        RAPQ93(keep=MAREA AGECAT SEXCAT RACECAT EAPQ93 RAPQ93 LAPQ93 UAPQ93 SAPQ93 SNAPQ93 VARAPQ93 XAPQ93 rename=(VARAPQ93=VAPQ93));
 by     MAREA AGECAT SEXCAT RACECAT;


 %macro label_qis(qi_num=, qi_name=);
   label 
   EA&qi_num.  = "&qi_name. (Expected rate)"
   RA&qi_num.  = "&qi_name. (Risk-adjusted rate)"
   LA&qi_num.  = "&qi_name. (Lower CL of risk-adjusted rate)"
   UA&qi_num.  = "&qi_name. (Upper CL of risk-adjusted rate)"
   SA&qi_num.  = "&qi_name. (Smoothed rate)"
   XA&qi_num.  = "&qi_name. (Standard error of the smoothed rate)"
   VA&qi_num.  = "&qi_name. (Variance of the risk-adjusted rate)"
   SNA&qi_num. = "&qi_name. (Reliability of the risk-adjusted rate)"
   ;
 %mend label_qis;
 
 %label_qis(qi_num=PQ01, qi_name=PQI 01 Diabetes Short-Term Complications Admission Rate);
 %label_qis(qi_num=PQ03, qi_name=PQI 03 Diabetes Long-Term Complications Admission Rate);
 %label_qis(qi_num=PQ05, qi_name=PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate);
 %label_qis(qi_num=PQ07, qi_name=PQI 07 Hypertension Admission Rate);
 %label_qis(qi_num=PQ08, qi_name=PQI 08 Heart Failure Admission Rate);
 %label_qis(qi_num=PQ11, qi_name=PQI 11 Community-Acquired Pneumonia Admission Rate);
 %label_qis(qi_num=PQ12, qi_name=PQI 12 Urinary Tract Infection Admission Rate);
 %label_qis(qi_num=PQ14, qi_name=PQI 14 Uncontrolled Diabetes Admission Rate);
 %label_qis(qi_num=PQ15, qi_name=PQI 15 Asthma in Younger Adults Admission Rate);
 %label_qis(qi_num=PQ16, qi_name=PQI 16 Lower-Extremity Amputation Among Patients with Diabetes Rate);
 %label_qis(qi_num=PQ90, qi_name=PQI 90 Prevention Quality Overall Composite);
 %label_qis(qi_num=PQ91, qi_name=PQI 91 Prevention Quality Acute Composite);
 %label_qis(qi_num=PQ92, qi_name=PQI 92 Prevention Quality Chronic Composite);
 %label_qis(qi_num=PQ93, qi_name=PQI 93 Prevention Quality Diabetes Composite);

 run;

*=======================================================================;
*  PART II:  MERGE AREA RATES FOR AHRQ PREVENTION QUALITY INDICATORS
*=======================================================================;

 title2 'PROGRAM PQI_AREA_RISKADJ  PART II';
 title3 'AHRQ PREVENTION QUALITY INDICATORS:  AREA-LEVEL MERGED FILES';

 * ---------------------------------------------------------------- ;
 * --- PREVENTION QUALITY INDICATOR MERGED RATES                --- ;
 * ---------------------------------------------------------------- ;
 data   OUTARSK.&OUTFILE_AREARISK.;
 merge  OUTAOBS.&OUTFILE_AREAOBS.(
            keep=MAREA AGECAT SEXCAT RACECAT _TYPE_ 
                 TAPQ01 TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ11 TAPQ12 TAPQ14-TAPQ16 TAPQ90-TAPQ93
                 PAPQ01 PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ11 PAPQ12 PAPQ14-PAPQ16 PAPQ90-PAPQ93 
                 OAPQ01 OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ11 OAPQ12 OAPQ14-OAPQ16 OAPQ90-OAPQ93)
        RISKADJ(
            keep=MAREA AGECAT SEXCAT RACECAT
                 EAPQ01 EAPQ03 EAPQ05 EAPQ07-EAPQ08 EAPQ11 EAPQ12 EAPQ14-EAPQ16 EAPQ90-EAPQ93
                 RAPQ01 RAPQ03 RAPQ05 RAPQ07-RAPQ08 RAPQ11 RAPQ12 RAPQ14-RAPQ16 RAPQ90-RAPQ93
                 LAPQ01 LAPQ03 LAPQ05 LAPQ07-LAPQ08 LAPQ11 LAPQ12 LAPQ14-LAPQ16 LAPQ90-LAPQ93
                 UAPQ01 UAPQ03 UAPQ05 UAPQ07-UAPQ08 UAPQ11 UAPQ12 UAPQ14-UAPQ16 UAPQ90-UAPQ93
                 SAPQ01 SAPQ03 SAPQ05 SAPQ07-SAPQ08 SAPQ11 SAPQ12 SAPQ14-SAPQ16 SAPQ90-SAPQ93
                 SNAPQ01 SNAPQ03 SNAPQ05 SNAPQ07-SNAPQ08 SNAPQ11 SNAPQ12 SNAPQ14-SNAPQ16 SNAPQ90-SNAPQ93
                 XAPQ01 XAPQ03 XAPQ05 XAPQ07-XAPQ08 XAPQ11 XAPQ12 XAPQ14-XAPQ16 XAPQ90-XAPQ93
                 VAPQ01 VAPQ03 VAPQ05 VAPQ07-VAPQ08 VAPQ11 VAPQ12 VAPQ14-VAPQ16 VAPQ90-VAPQ93);
 by     MAREA AGECAT SEXCAT RACECAT;

 array ARRY1{14} EAPQ01 EAPQ03 EAPQ05 EAPQ07-EAPQ08 EAPQ11 EAPQ12 EAPQ14-EAPQ16 EAPQ90-EAPQ93;
 array ARRY2{14} RAPQ01 RAPQ03 RAPQ05 RAPQ07-RAPQ08 RAPQ11 RAPQ12 RAPQ14-RAPQ16 RAPQ90-RAPQ93;
 array ARRY3{14} LAPQ01 LAPQ03 LAPQ05 LAPQ07-LAPQ08 LAPQ11 LAPQ12 LAPQ14-LAPQ16 LAPQ90-LAPQ93;
 array ARRY4{14} UAPQ01 UAPQ03 UAPQ05 UAPQ07-UAPQ08 UAPQ11 UAPQ12 UAPQ14-UAPQ16 UAPQ90-UAPQ93;
 array ARRY5{14} SAPQ01 SAPQ03 SAPQ05 SAPQ07-SAPQ08 SAPQ11 SAPQ12 SAPQ14-SAPQ16 SAPQ90-SAPQ93;
 array ARRY6{14} XAPQ01 XAPQ03 XAPQ05 XAPQ07-XAPQ08 XAPQ11 XAPQ12 XAPQ14-XAPQ16 XAPQ90-XAPQ93;
 array ARRY7{14} PAPQ01 PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ11 PAPQ12 PAPQ14-PAPQ16 PAPQ90-PAPQ93;
 array ARRY8{14} VAPQ01 VAPQ03 VAPQ05 VAPQ07-VAPQ08 VAPQ11 VAPQ12 VAPQ14-VAPQ16 VAPQ90-VAPQ93;
 array ARRY9{14} SNAPQ01 SNAPQ03 SNAPQ05 SNAPQ07-SNAPQ08 SNAPQ11 SNAPQ12 SNAPQ14-SNAPQ16 SNAPQ90-SNAPQ93;

 do I = 1 TO 14;
   if ARRY7(I) <= 2 then do;
      ARRY1(I) = .; ARRY2(I) = .; ARRY3(I) = .; ARRY4(I) = .;
      ARRY5(I) = .; ARRY6(I) = .; ARRY8(I) = .; ARRY9(I) = .;
   end;
 end;

 DROP I;

 format EAPQ01 EAPQ03 EAPQ05 EAPQ07 EAPQ08 EAPQ11 EAPQ12 
        EAPQ14 EAPQ15 EAPQ16 EAPQ90 EAPQ91 EAPQ92 EAPQ93
        LAPQ01 LAPQ03 LAPQ05 LAPQ07 LAPQ08 LAPQ11 LAPQ12
        LAPQ14 LAPQ15 LAPQ16 LAPQ90 LAPQ91 LAPQ92 LAPQ93
        OAPQ01 OAPQ03 OAPQ05 OAPQ07 OAPQ08 OAPQ11 OAPQ12
        OAPQ14 OAPQ15 OAPQ16 OAPQ90 OAPQ91 OAPQ92 OAPQ93
        RAPQ01 RAPQ03 RAPQ05 RAPQ07 RAPQ08 RAPQ11 RAPQ12
        RAPQ14 RAPQ15 RAPQ16 RAPQ90 RAPQ91 RAPQ92 RAPQ93
        SAPQ01 SAPQ03 SAPQ05 SAPQ07 SAPQ08 SAPQ11 SAPQ12
        SAPQ14 SAPQ15 SAPQ16 SAPQ90 SAPQ91 SAPQ92 SAPQ93
        SNAPQ01 SNAPQ03 SNAPQ05 SNAPQ07 SNAPQ08 SNAPQ11 SNAPQ12
        SNAPQ14 SNAPQ15 SNAPQ16 SNAPQ90 SNAPQ91 SNAPQ92 SNAPQ93
        UAPQ01 UAPQ03 UAPQ05 UAPQ07 UAPQ08 UAPQ11 UAPQ12
        UAPQ14 UAPQ15 UAPQ16 UAPQ90 UAPQ91 UAPQ92 UAPQ93
        VAPQ01 VAPQ03 VAPQ05 VAPQ07 VAPQ08 VAPQ11 VAPQ12
        VAPQ14 VAPQ15 VAPQ16 VAPQ90 VAPQ91 VAPQ92 VAPQ93
        XAPQ01 XAPQ03 XAPQ05 XAPQ07 XAPQ08 XAPQ11 XAPQ12
        XAPQ14 XAPQ15 XAPQ16 XAPQ90 XAPQ91 XAPQ92 XAPQ93 13.7
        TAPQ01 TAPQ03 TAPQ05 TAPQ07 TAPQ08 TAPQ11 TAPQ12
        TAPQ14 TAPQ15 TAPQ16 TAPQ90 TAPQ91 TAPQ92 TAPQ93 
        PAPQ01 PAPQ03 PAPQ05 PAPQ07 PAPQ08 PAPQ11 PAPQ12
        PAPQ14 PAPQ15 PAPQ16 PAPQ90 PAPQ91 PAPQ92 PAPQ93 13.0;

 run;

 * ---------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MAREA MERGED OUTPUT FILE           --- ;
 * ---------------------------------------------------------------- ;

 proc Contents data=OUTARSK.&OUTFILE_AREARISK. POSITION;
 run;

 proc Means data=OUTARSK.&OUTFILE_AREARISK.(WHERE=(_TYPE_ in (8))) N NMISS MIN MAX MEAN SUM NOLABELS;
 title4 'SUMMARY OF AREA-LEVEL RATES (_TYPE_=8)';
 run;

 * ---------------------------------------------------------------- ;
 * --- PRINT AREA MERGED OUTPUT FILE                            --- ;
 * ---------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PQ,TEXT);
 proc  PRINT data=OUTARSK.&OUTFILE_AREARISK. label SPLIT='*';
 var   MAREA AGECAT SEXCAT RACECAT 
       TAPQ&PQ. PAPQ&PQ. OAPQ&PQ. EAPQ&PQ. RAPQ&PQ. LAPQ&PQ. UAPQ&PQ. SAPQ&PQ. SNAPQ&PQ. VAPQ&PQ. XAPQ&PQ.;
 label MAREA    = "Metro Area Level"
       AGECAT   = "Population Age Categories"
       SEXCAT   = "Sex Categories"
       RACECAT  = "Race Categories"
       TAPQ&PQ. = "TAPQ&PQ.*(Numerator)"
       PAPQ&PQ. = "PAPQ&PQ.*(Population)"
       OAPQ&PQ. = "OAPQ&PQ.*(Observed rate)"
       EAPQ&PQ. = "EAPQ&PQ.*(Expected rate)"
       RAPQ&PQ. = "RAPQ&PQ.*(Risk-adjusted rate)"
       LAPQ&PQ. = "LAPQ&PQ.*(Lower CL of risk-adjusted rate)"
       UAPQ&PQ. = "UAPQ&PQ.*(Upper CL of risk-adjusted rate)"
       SAPQ&PQ. = "SAPQ&PQ.*(Smoothed rate)"
       SNAPQ&PQ. = "SNAPQ&PQ.*(Reliability of the risk-adjusted rate)"
       XAPQ&PQ. = "XAPQ&PQ.*(Standard error of the smoothed rate)"
       VAPQ&PQ. = "VAPQ&PQ.*(Variance of the risk-adjusted rate)"
       ;

 format AGECAT AGECAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
      TAPQ&PQ. PAPQ&PQ. COMMA13.0
        OAPQ&PQ. EAPQ&PQ. RAPQ&PQ. LAPQ&PQ. UAPQ&PQ. SAPQ&PQ. SNAPQ&PQ.  VAPQ&PQ. XAPQ&PQ. 8.6;

 title4 "FINAL OUTPUT";
 title5 "Indicator  &PQ.: &TEXT";

 run;

 %MEND PRT;

 %PRT(01,Diabetes Short-Term Complications Admission Rate);
 %PRT(03,Diabetes Long-Term Complications Admission Rate);
 %PRT(05,Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate);
 %PRT(07,Hypertension Admission Rate);
 %PRT(08,Heart Failure Admission Rate);
 %PRT(11,Community-Acquired Pneumonia Admission Rate);
 %PRT(12,Urinary Tract Infection Admission Rate);
 %PRT(14,Uncontrolled Diabetes Admission Rate);
 %PRT(15,Asthma in Younger Adults Admission Rate);
 %PRT(16,Lower-Extremity Amputation among Patients with Diabetes Rate);
 %PRT(90,Prevention Quality Overall Composite);
 %PRT(91,Prevention Quality Acute Composite);
 %PRT(92,Prevention Quality Chronic Composite);
 %PRT(93,Prevention Quality Diabetes Composite);

 %END;

 %MEND PRT2 ;

 %PRT2;

 * ---------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO TEXT FILE                   --- ;
 * ---------------------------------------------------------------- ;

 %MACRO TEXT;
 
 %macro scale_rates;
   
   %IF &SCALE_RATES = 1 %THEN %DO;
      ARRAY RATES OAPQ: EAPQ: RAPQ: LAPQ: UAPQ: SAPQ:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*100000;	
	  end;
	%END;
	
 %mend scale_rates;

 %IF &TXTARSK. = 1  %THEN %DO;
	%LET TYPEARN  = %sysfunc(tranwrd(&TYPELVLA.,%str(,),_));
	%LET TYPEARN2  = %sysfunc(compress(&TYPEARN.,'(IN )'));
	%let PQCSVREF  = %sysfunc(pathname(PQTXTARA));
	%let PQCSVRF2 =  %sysfunc(tranwrd(&PQCSVREF.,.TXT,_&TYPEARN2..TXT));

 data _NULL_;
 set OUTARSK.&OUTFILE_AREARISK;
 FILE "&PQCSVRF2." lrecl=2000;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_AREARISK data set created with the following CONTROL options:";
 put "&&MALEVL&MALEVL (MALEVL = &MALEVL)";
 put "Population year (POPYEAR) = &POPYEAR";
 put "&&Calibration_OE_to_ref_pop&Calibration_OE_to_ref_pop. (Calibration_OE_to_ref_pop = &Calibration_OE_to_ref_pop)";
 put "Output stratification includes TYPELVLA = &TYPELVLA";
 put "&&USE_SES&USE_SES (USE_SES = &USE_SES)"; 
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "MAREA" "," "Age"  "," "Sex"  "," "Race"  "," "Type" ","
 "TAPQ01" "," "TAPQ03" "," 
 "TAPQ05" "," "TAPQ07" "," "TAPQ08" ","
 "TAPQ11" "," "TAPQ12" ","
 "TAPQ14" "," "TAPQ15" "," "TAPQ16" ","
 "TAPQ90" "," "TAPQ91" "," "TAPQ92" "," "TAPQ93" ","
 "PAPQ01" "," "PAPQ03" "," 
 "PAPQ05" "," "PAPQ07" "," "PAPQ08" ","
  "PAPQ11" "," "PAPQ12" ","
 "PAPQ14" "," "PAPQ15" "," "PAPQ16" ","
 "PAPQ90" "," "PAPQ91" "," "PAPQ92" "," "PAPQ93" ","
 "OAPQ01" "," "OAPQ03" "," 
 "OAPQ05" "," "OAPQ07" "," "OAPQ08" ","
 "OAPQ11" "," "OAPQ12" ","
 "OAPQ14" "," "OAPQ15" "," "OAPQ16" ","
 "OAPQ90" "," "OAPQ91" "," "OAPQ92" "," "OAPQ93" ","
 "EAPQ01" "," "EAPQ03" "," 
 "EAPQ05" "," "EAPQ07" "," "EAPQ08" ","
 "EAPQ11" "," "EAPQ12" "," 
 "EAPQ14" "," "EAPQ15" "," "EAPQ16" ","
 "EAPQ90" "," "EAPQ91" "," "EAPQ92" "," "EAPQ93" ","
 "RAPQ01" "," "RAPQ03" "," 
 "RAPQ05" "," "RAPQ07" "," "RAPQ08" ","
 "RAPQ11" "," "RAPQ12" "," 
 "RAPQ14" "," "RAPQ15" "," "RAPQ16" ","
 "RAPQ90" "," "RAPQ91" "," "RAPQ92" "," "RAPQ93" ","
 "LAPQ01" "," "LAPQ03" "," 
 "LAPQ05" "," "LAPQ07" "," "LAPQ08" ","
 "LAPQ11" "," "LAPQ12" "," 
 "LAPQ14" "," "LAPQ15" "," "LAPQ16" ","
 "LAPQ90" "," "LAPQ91" "," "LAPQ92" "," "LAPQ93" ","
 "UAPQ01" "," "UAPQ03" "," 
 "UAPQ05" "," "UAPQ07" "," "UAPQ08" ","
 "UAPQ11" "," "UAPQ12" "," 
 "UAPQ14" "," "UAPQ15" "," "UAPQ16" ","
 "UAPQ90" "," "UAPQ91" "," "UAPQ92" "," "UAPQ93" ","
 "SAPQ01" "," "SAPQ03" "," 
 "SAPQ05" "," "SAPQ07" "," "SAPQ08" ","
 "SAPQ11" "," "SAPQ12" "," 
 "SAPQ14" "," "SAPQ15" "," "SAPQ16" ","
 "SAPQ90" "," "SAPQ91" "," "SAPQ92" "," "SAPQ93" ","
 "SNAPQ01" "," "SNAPQ03" "," 
 "SNAPQ05" "," "SNAPQ07" "," "SNAPQ08" ","
 "SNAPQ11" "," "SNAPQ12" "," 
 "SNAPQ14" "," "SNAPQ15" "," "SNAPQ16" ","
 "SNAPQ90" "," "SNAPQ91" "," "SNAPQ92" "," "SNAPQ93" ","
 "VAPQ01" "," "VAPQ03" "," 
 "VAPQ05" "," "VAPQ07" "," "VAPQ08" ","
 "VAPQ11" "," "VAPQ12" ","
 "VAPQ14" "," "VAPQ15" "," "VAPQ16" ","
 "VAPQ90" "," "VAPQ91" "," "VAPQ92" "," "VAPQ93"  ","
 "XAPQ01" "," "XAPQ03" "," 
 "XAPQ05" "," "XAPQ07" "," "XAPQ08" ","
 "XAPQ11" "," "XAPQ12" ","
 "XAPQ14" "," "XAPQ15" "," "XAPQ16" ","
 "XAPQ90" "," "XAPQ91" "," "XAPQ92" "," "XAPQ93"
  ;
 end;
 
 put MAREA  $5. "," AGECAT 3. "," SEXCAT 3. "," RACECAT 3.  "," _TYPE_ 2.  ","
 (TAPQ01 TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ11 TAPQ12 TAPQ14-TAPQ16 TAPQ90-TAPQ93) (7.0 ",")
  ","
 (PAPQ01 PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ11 PAPQ12 PAPQ14-PAPQ16 PAPQ90-PAPQ93) (13.0 ",")
 ","
 (OAPQ01 OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ11 OAPQ12 OAPQ14-OAPQ16 OAPQ90-OAPQ93) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (EAPQ01 EAPQ03 EAPQ05 EAPQ07-EAPQ08 EAPQ11 EAPQ12 EAPQ14-EAPQ16 EAPQ90-EAPQ93) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (RAPQ01 RAPQ03 RAPQ05 RAPQ07-RAPQ08 RAPQ11 RAPQ12 RAPQ14-RAPQ16 RAPQ90-RAPQ93) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (LAPQ01 LAPQ03 LAPQ05 LAPQ07-LAPQ08 LAPQ11 LAPQ12 LAPQ14-LAPQ16 LAPQ90-LAPQ93) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (UAPQ01 UAPQ03 UAPQ05 UAPQ07-UAPQ08 UAPQ11 UAPQ12 UAPQ14-UAPQ16 UAPQ90-UAPQ93) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (SAPQ01 SAPQ03 SAPQ05 SAPQ07-SAPQ08 SAPQ11 SAPQ12 SAPQ14-SAPQ16 SAPQ90-SAPQ93) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (SNAPQ01 SNAPQ03 SNAPQ05 SNAPQ07-SNAPQ08 SNAPQ11 SNAPQ12 SNAPQ14-SNAPQ16 SNAPQ90-SNAPQ93) (12.10 ",")
 ","
 (VAPQ01 VAPQ03 VAPQ05 VAPQ07-VAPQ08 VAPQ11 VAPQ12 VAPQ14-VAPQ16 VAPQ90-VAPQ93) (12.10 ",")
 ","
 (XAPQ01 XAPQ03 XAPQ05 XAPQ07-XAPQ08 XAPQ11 XAPQ12 XAPQ14-XAPQ16 XAPQ90-XAPQ93) (12.10 ",")
 ;
 run;

 %END;

 %MEND TEXT;

 %TEXT;
