*=============== PROGRAM: PDI_AREA_RISKADJ.SAS ===================================;
*
*  TITLE: RISK ADJUSTED RATES PROGRAM FOR AHRQ PEDIATRIC QUALITY INDICATORS
*
*  DESCRIPTION:
*         Calculates risk-adjusted and smoothed rates for
*         Pediatric Area Quality Indicators across stratifiers.
*         Variables created by this program are EAPDxx, RAPDxx, 
*         LAPDxx, UAPDxx, SAPDxx, SNAPDxx, VAPDxx, XAPDxx
*         Output stratified by AGE, SEXCAT and POVCAT from
*         population file and PDI_AREA_MEASURES output.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*=================================================================================;

 title2 'PROGRAM PDI_AREA_RISKADJ PART I';
 title3 'AHRQ PEDIATRIC QUALITY INDICATORS: CALCULATE RISK-ADJUSTED AREA RATES';

 * ------------------------------------------------------------------ ;
 * --- PEDIATRIC QUALITY INDICATOR (PDI) NAMING CONVENTION:       --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PEDIATRIC QUALITY          --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:                         --- ;
 * ---      (T) NUMERATOR ("TOP") - FROM PDI_ALL_MEASURES         --- ;
 * ---      (P) DENOMINATOR ("POP") - FROM PDI_ALL_MEASURES       --- ;
 * ---      (O) OBSERVED RATES (T/P)                              --- ;
 * ---      (E) EXPECTED RATE                                     --- ;
 * ---      (V) VARIANCE                                          --- ;
 * ---      (R) RISK-ADJUSTED RATE                                --- ;
 * ---      (L) LOWER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE     --- ;
 * ---      (U) UPPER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE     --- ;
 * ---      (S) SMOOTHED RATE (NOT REPORTED FOR STRATA)           --- ;
 * ---      (X) SMOOTHED RATE STANDARD ERROR (NOT REPORTED FOR STRATA);
 * --- THE SECOND LETTER IDENTIFIES THE PDI AS AN AREA (A)        --- ;
 * --- LEVEL INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS 'PD'. --- ;
 * --- THE LAST TWO DIGITS ARE THE INDICATOR NUMBER               --- ;
 * ------------------------------------------------------------------ ;

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR                               --- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE     --- ;
 * --- OUTPUT FROM THE PDI_AREA_OBSERVED PROGRAM.               --- ;
 * ---------------------------------------------------------------- ;

 * --- MACRO TO ADJUST AREA AGGREGATION BASED ON MAREA VALUE IN PDI_ALL_CONTROL --- ;                                                                     

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

 data   TEMP0;
 set    OUTMSR.&OUTFILE_MEAS.;

 %CTY2MA

 run;

 * --- IDENTIFY UNIQUE MAREA VALUES IN PDI_ALL_MEASURES OUTPUT --- ;

 proc   Sort data=TEMP0 (keep=MAREA) out=MAREA nodupkey;
 by     MAREA;
 run;

 * --- LOAD POPULATION FOR MAREA LEVEL AND YEAR IN PDI_ALL_CONTROL --- ;                                                                         

 data QIPOP0;
    length FIPSTCO $5 SEXCAT POPCAT RACECAT 3 
            
           POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
           POP_2005 POP_2006 POP_2007 POP_2008 POP_2009 
           POP_2010 POP_2011 POP_2012 POP_2013 POP_2014
           POP_2015 POP_2016 POP_2017 POP_2018 POP_2019 
           POP_2020 POP_2021 POP_2022 POP_2023 POP 8;

    infile POPFILE missover firstobs=2;

    input FIPSTCO SEXCAT POPCAT RACECAT 
           
          POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
          POP_2005 POP_2006 POP_2007 POP_2008 POP_2009
          POP_2010 POP_2011 POP_2012 POP_2013 POP_2014
          POP_2015 POP_2016 POP_2017 POP_2018 POP_2019
          POP_2020 POP_2021 POP_2022 POP_2023;

    %CTY2MA

    POP = POP_&POPYEAR.;

    if POPCAT in (1,2,3,4);

 run;

 proc   Summary data=QIPOP0 nway;
 class  MAREA POPCAT SEXCAT RACECAT;
 var    POP;
 output out=QIPOP sum=;
 run;

 proc   Sort data=QIPOP;
 by     MAREA POPCAT SEXCAT RACECAT;
 run;

 * --- LIMIT POPULATION TOTALS TO MAREA CODES FOUND IN PDI_ALL_MEASURES OUTPUT. --- ;

 data   QIPOP(keep=MAREA POPCAT SEXCAT RACECAT POP);
 merge  MAREA(in=X) QIPOP(in=Y);
 by     MAREA;

 if X and Y;

 run;

 * -------------------------------------------------------------- ;
 * ---- PEDIATRIC QUALITY INDICATORS ADJUSTED RATES ------------- ;
 * -------------------------------------------------------------- ;
 * --- THIS STEP SELECTS THE OBSERVATIONS FROM THE PROGRAM    --- ;
 * --- PDI_AREA_OBSERVED OUTPUT FOR EACH PEDIATRIC QUALITY    --- ;
 * --- INDICATOR IN TURN. EACH ITERATION PASSES VARIABLES     --- ;
 * --- THAT CONTROL THE COVARIATES FOR THAT PEDIATRIC QUALITY --- ;
 * --- INDICATOR:                                             --- ;
 * --- N - OBSERVATION NUMBER FROM THE MEANS AND COVAR FILES  --- ;
 * ---     ALSO IDENTIFIES THE FORMAT USED TO INDEX COVARIATES -- ;
 * --- PD - THE PEDIATRIC QUALITY INDICATOR NAME WITHOUT THE  --- ;
 *          PREFIX (A)                                        --- ;
 * -------------------------------------------------------------- ;

 %MACRO MOD3(N,PD);

 * --- THIS SET CREATES TEMP1 WHICH CONTAINS THE DEPENDENT    --- ;
 * --- VARIABLE (TPD) AND INDEPENDENT VARIABLES USED IN       --- ;
 * --- REGRESSION.  IT APPENDS TO THE DISCHARGE DATA ONE      --- ;
 * --- OBSERVATION PER MAREA AND DEMOGRAPHIC GROUP.           --- ;

 data   TEMP_2;
 set    OUTMSR.&OUTFILE_MEAS.(keep=KEY FIPSTCO T&PD. POPCAT SEXCAT RACECAT);

 if T&PD. in (1);
 if POPCAT in (1,2,3,4);

 %CTY2MA

 run;

 * --- SUM THE NUMERATOR 'T' FLAGS BY MAREA POPCAT AGECAT SEXCAT RACECAT --- ;     

 proc   Summary data=TEMP_2 nway;
 class  MAREA POPCAT SEXCAT RACECAT;
 var    T&PD.;
 output out=TEMP_3 N=TCOUNT;
 run;

 proc   Sort data=TEMP_3;
 by     MAREA POPCAT SEXCAT RACECAT;
 run;

 *-- FOR ZERO, REDUCE THE WEIGHT BY THE NUMERATOR COUNT --* ;

 data   TEMP_4(drop=TCOUNT N);
 merge  QIPOP(in=X keep=MAREA POPCAT SEXCAT RACECAT POP) 
        TEMP_3(keep=MAREA POPCAT SEXCAT RACECAT TCOUNT);
 by     MAREA POPCAT SEXCAT RACECAT;

 if X;

 N = &N.;

 if POPCAT in (1) then do;
    if N = 14 then POP = POP * 0.60; *-- AGE < 2  ;
    if N = 15 then POP = .;          *-- AGE < 6  ;
    if N = 16 then POP = POP * 0.95; *-- AGEDAY < 90 ;
    if N = 18 then POP = POP * 0.95; *-- AGEDAY < 90 ;
    if N = 90 then POP = .;          *-- AGE < 6 ;
    if N = 91 then POP = .;          *-- AGE < 6 ;
    if N = 92 then POP = .;          *-- AGE < 6 ;
 end;
 else if POPCAT in (2) then do;
   if N = 15 then POP = POP * 0.80; *-- AGE < 6 ;
   if N = 90 then POP = POP * 0.80; *-- AGE < 6 ;
   if N = 91 then POP = POP * 0.80; *-- AGE < 6 ;
   if N = 92 then POP = POP * 0.80; *-- AGE < 6 ;
 end;

 if TCOUNT > 0 then PCOUNT = POP - TCOUNT;
 else PCOUNT = POP;

 if PCOUNT < 0 then PCOUNT = 0;

 if PCOUNT = 0 then delete;
 
 run;

 *-- FOR ONE, RETAIN ONLY RECORDS WITH A VALID FIPS CODE --* ;

 data   TEMP_3(drop=POP);
 merge  TEMP_3(in=X keep=MAREA POPCAT SEXCAT RACECAT TCOUNT)
        QIPOP(keep=MAREA POPCAT SEXCAT RACECAT POP);
 by     MAREA POPCAT SEXCAT RACECAT;

 if X;

 if POP < 0 then PCOUNT = 0;
 else if TCOUNT > 0 then PCOUNT = TCOUNT;
 else PCOUNT = 0;

 if PCOUNT = 0 then delete;
 
 run;

 *-- COMBINE THE NUMERATOR AND DENOMINATOR --* ;

 data   TEMP1;
 set    TEMP_3(in=X) TEMP_4;

 if X then T&PD. = 1;
 else T&PD. = 0;

 run;

 data   TEMP1;
 length FEMALE AGECAT1-AGECAT4 FAGECAT1-FAGECAT4 
        POVCAT1-POVCAT10 3;
 set    TEMP1;

 if SEXCAT in (2) then FEMALE = 1;
 else FEMALE = 0;

 array ARRY1{4} AGECAT1-AGECAT4;
 array ARRY2{4} FAGECAT1-FAGECAT4;

 do I = 1 TO 4;
    ARRY1(I) = 0; ARRY2(I) = 0;
 end;

 ARRY1(POPCAT) = 1;
 ARRY2(POPCAT) = FEMALE;

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

 * --- THIS DATA STEP READS THE REGRESSION COEFFICIENTS FOR    --- ;
 * --- EACH COVARIATE.                                         --- ;
 
%IF &USE_SES=0 %THEN %DO ;
    filename RACOEFFS "&AQIRADIR./&PD._Area_Covariates_v2024.csv";
 %END ;
 %ELSE %DO;
    filename RACOEFFS "&AQIRADIR./&PD._Area_Covariates_SES_v2024.csv";
%END ;

 * --- LOAD CSV PARAMTERS & SHAPE DATA --- ;
 data TEMP1_MODEL ;
   length variable $75 df estimate 8 ;
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

 * --- THIS PROC CALCULATES A PREDICTED PEDIATRIC QUALITY --- ;
 * --- INDICATOR FOR EACH OBSERVATION USING THE ACTUAL    --- ;
 * --- COVARIATES AND THE ESTIMATED COEFFICIENTS.         --- ;

 proc   SCORE data=TEMP1 SCORE=TEMP2 TYPE=PARMS out=TEMP1Y;
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
      %include MacLib(PDI_AREA_OE_Array_v2024.SAS);
    %END ;
    %ELSE %DO ;
      %include MacLib(PDI_AREA_OE_Array_SES_v2024.SAS);
    %END ;   
    *-- MAP MEASURE NUM TO ARRAY INDEX SUB_N --* ;
    if "&PD." = "APD14"      then SUB_N = 1;
    if "&PD." = "APD15"      then SUB_N = 2;
    if "&PD." = "APD16"      then SUB_N = 3;
    if "&PD." = "APD18"      then SUB_N = 4;
    if "&PD." = "APD90"      then SUB_N = 5;
    if "&PD." = "APD91"      then SUB_N = 6;
    if "&PD." = "APD92"      then SUB_N = 7;

    EHAT=EHAT*ARRYAOE(SUB_N);
    IF EHAT > 0.99 THEN EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT); 
    ONE=1;   
 RUN;
%end;
%else %if &Calibration_OE_to_ref_pop. = 0 %then %do; 
 PROC MEANS DATA=TEMP1Y noprint;
    VAR T&PD. EHAT;
    WEIGHT PCOUNT;
    OUTPUT OUT=OE&PD.(DROP=_TYPE_ _FREQ_) SUM(T&PD. EHAT)=T&PD. EHAT;
 RUN;

 DATA OE&PD.;
    SET OE&PD.;
    O_E&PD.=T&PD./EHAT;
 RUN;

 PROC PRINT DATA=OE&PD.;
 RUN;

 DATA OE&PD.;
    SET OE&PD.(KEEP=O_E&PD.);
 RUN;

 DATA TEMP1Y;  
    IF _N_=1 THEN SET OE&PD.;
    SET TEMP1Y;
    EHAT=EHAT*O_E&PD.;
    IF EHAT > 0.99 THEN EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT);    
    ONE=1;
 RUN;
%end;


 proc   Summary data=TEMP1Y;
 class  MAREA POPCAT SEXCAT RACECAT;
 var    T&PD. EHAT PHAT ONE;
 output out=R&PD. SUM(T&PD. EHAT PHAT ONE)=T&PD. EHAT PHAT P&PD.;
 weight PCOUNT;
 run;

 data   R&PD.(keep=MAREA POPCAT SEXCAT RACECAT _TYPE_
                   E&PD. R&PD. L&PD. U&PD. S&PD. X&PD. VAR&PD. SN&PD.);
 set    R&PD.;

 if _TYPE_ &TYPELVLA;

 * --- SWITCH SIGNAL VARIANCE BASED ON USE_SES FLAG --- ;
 %IF &USE_SES=0 %THEN %DO ;
    %include MacLib(PDI_AREA_Sigvar_Array_v2024.SAS);
 %END ;
 %ELSE %DO ;
    %include MacLib(PDI_AREA_Sigvar_Array_SES_v2024.SAS);
 %END ;
 
 if &N. = 14 then SUB_N = 1;
 if &N. = 15 then SUB_N = 2;
 if &N. = 16 then SUB_N = 3;
 if &N. = 18 then SUB_N = 4;
 if &N. = 90 then SUB_N = 5;
 if &N. = 91 then SUB_N = 6;
 if &N. = 92 then SUB_N = 7;
 if &N. = 60 then SUB_N = 8;

 E&PD. = EHAT / P&PD.;
 THAT = T&PD. / P&PD.;

 if _TYPE_ in (0,8) then do;
    R&PD.   = (THAT / E&PD.) * ARRYA3(SUB_N);
    SE&PD.  = (ARRYA3(SUB_N) / E&PD.) * (1 / P&PD.) * SQRT(PHAT);
    VAR&PD. = SE&PD.**2;
    SN&PD.  = ARRYA2(SUB_N) / (ARRYA2(SUB_N) + VAR&PD.);
    S&PD.   = (R&PD. * SN&PD.) + ((1 -  SN&PD.) * ARRYA3(SUB_N));
    X&PD.   = SQRT(ARRYA2(SUB_N)- (SN&PD. * ARRYA2(SUB_N)));
 end;
 else do;
    R&PD.   = (THAT / E&PD.);
    SE&PD.  = (1 / E&PD.) * (1 / P&PD.) * SQRT(PHAT);
    S&PD.   = .;
    X&PD.   = .;
 end;

 L&PD.   = R&PD. - (1.96 * SE&PD.);
 if L&PD. < 0 then L&PD. = 0;
 U&PD.   = R&PD. + (1.96 * SE&PD.);

 if _TYPE_ in (0,8) then do; 
     if L&PD. > 1 then L&PD. = 1; 
     if U&PD. > 1 then U&PD. = 1;
     if R&PD. > 1 then R&PD. = 1;
     if S&PD. > 1 then S&PD. = 1;
 end;

 run;

 %end;
 %else %do;

 data   R&PD.;
  
    MAREA='';POPCAT=.;SEXCAT=.;RACECAT=.;_TYPE_=0;_FREQ_=0;E&PD=.;R&PD=.;L&PD=.;U&PD=.;P&PD=.;S&PD=.;X&PD=.;VAR&PD=.;SN&PD=.; 
    output;
 run;

 %end;

 proc Sort data=R&PD.;
   by MAREA POPCAT SEXCAT RACECAT;
 run; quit;

 *-- DELETE TEMPORARY DATASETS IN PREPARATION FOR RISK ADJUSTMENT OF THE NEXT MEASURE;
 PROC DATASETS NOLIST;
 DELETE TEMP1 TEMP1Y TEMP2;
 run;
 %MEND;

 %MOD3(14,APD14);
 %MOD3(15,APD15);
 %MOD3(16,APD16);
 %MOD3(18,APD18);
 %MOD3(90,APD90);
 %MOD3(91,APD91);
 %MOD3(92,APD92);

 * --- MERGES THE MAREA ADJUSTED RATES FOR EACH PEDIATRIC   --- ;
 * --- QUALITY INDICATOR. PREFIX FOR THE ADJUSTED RATES IS  --- ;
 * --- R (RISK ADJUSTED).                                   --- ;

 data   RISKADJ;
 merge  RAPD14(keep=MAREA POPCAT SEXCAT RACECAT EAPD14 RAPD14 LAPD14 UAPD14 SAPD14 SNAPD14 VARAPD14 XAPD14 rename=(VARAPD14=VAPD14)) 
        RAPD15(keep=MAREA POPCAT SEXCAT RACECAT EAPD15 RAPD15 LAPD15 UAPD15 SAPD15 SNAPD15 VARAPD15 XAPD15 rename=(VARAPD15=VAPD15))
        RAPD16(keep=MAREA POPCAT SEXCAT RACECAT EAPD16 RAPD16 LAPD16 UAPD16 SAPD16 SNAPD16 VARAPD16 XAPD16 rename=(VARAPD16=VAPD16))
        RAPD18(keep=MAREA POPCAT SEXCAT RACECAT EAPD18 RAPD18 LAPD18 UAPD18 SAPD18 SNAPD18 VARAPD18 XAPD18 rename=(VARAPD18=VAPD18))
        RAPD90(keep=MAREA POPCAT SEXCAT RACECAT EAPD90 RAPD90 LAPD90 UAPD90 SAPD90 SNAPD90 VARAPD90 XAPD90 rename=(VARAPD90=VAPD90))
        RAPD91(keep=MAREA POPCAT SEXCAT RACECAT EAPD91 RAPD91 LAPD91 UAPD91 SAPD91 SNAPD91 VARAPD91 XAPD91 rename=(VARAPD91=VAPD91))
        RAPD92(keep=MAREA POPCAT SEXCAT RACECAT EAPD92 RAPD92 LAPD92 UAPD92 SAPD92 SNAPD92 VARAPD92 XAPD92 rename=(VARAPD92=VAPD92))
       ;
 by     MAREA POPCAT SEXCAT RACECAT;

 %macro label_qis(qi_num=, qi_name=);
   label 
   EA&qi_num. = "&qi_name. (Expected rate)"
   RA&qi_num. = "&qi_name. (Risk-adjusted rate)"
   LA&qi_num. = "&qi_name. (Lower CL of risk-adjusted rate)"
   UA&qi_num. = "&qi_name. (Upper CL of risk-adjusted rate)"
   SA&qi_num. = "&qi_name. (Smoothed rate)"
   XA&qi_num. = "&qi_name. (Standard error of the smoothed rate)"
   VA&qi_num. = "&qi_name. (Variance of the risk-adjusted rate)"
   SNA&qi_num. = "&qi_name. (Reliability of the risk-adjusted rate)"
   ;
 %mend label_qis;

 %label_qis(qi_num=PD14, qi_name=PDI 14 Asthma Admission Rate);
 %label_qis(qi_num=PD15, qi_name=PDI 15 Diabetes Short-Term Complications Admission Rate);
 %label_qis(qi_num=PD16, qi_name=PDI 16 Gastroenteritis Admission Rate);
 %label_qis(qi_num=PD18, qi_name=PDI 18 Urinary Tract Infection Admission Rate);
 %label_qis(qi_num=PD90, qi_name=PDI 90 Pediatric Quality Overall Composite);
 %label_qis(qi_num=PD91, qi_name=PDI 91 Pediatric Quality Acute Composite);
 %label_qis(qi_num=PD92, qi_name=PDI 92 Pediatric Quality Chronic Composite);

 run;

*===================================================================;
*  PART II:  MERGE AREA RATES FOR AHRQ PEDIATRIC QUALITY INDICATORS
*===================================================================;

 title2 'PROGRAM PDI_AREA_RISKADJ -  PART II';
 title3 'AHRQ PEDIATRIC QUALITY INDICATORS:  AREA-LEVEL MERGED FILES';

 * ---------------------------------------------------------------- ;
 * --- PEDIATRIC QUALITY INDICATOR MERGED RATES                 --- ;
 * ---------------------------------------------------------------- ;

 data   OUTARSK.&OUTFILE_AREARISK.;
 merge  OUTAOBS.&OUTFILE_AREAOBS.(
             keep=MAREA POPCAT SEXCAT RACECAT _TYPE_ 
                  TAPD14-TAPD16 TAPD18 TAPD90-TAPD92   
                  PAPD14-PAPD16 PAPD18 PAPD90-PAPD92   
                  OAPD14-OAPD16 OAPD18 OAPD90-OAPD92)
             RISKADJ(keep=MAREA POPCAT SEXCAT RACECAT
                          EAPD14-EAPD16 EAPD18 EAPD90-EAPD92 
                          RAPD14-RAPD16 RAPD18 RAPD90-RAPD92 
                          LAPD14-LAPD16 LAPD18 LAPD90-LAPD92 
                          UAPD14-UAPD16 UAPD18 UAPD90-UAPD92 
                          SAPD14-SAPD16 SAPD18 SAPD90-SAPD92 
                          SNAPD14-SNAPD16 SNAPD18 SNAPD90-SNAPD92 
                          XAPD14-XAPD16 XAPD18 XAPD90-XAPD92 
                          VAPD14-VAPD16 VAPD18 VAPD90-VAPD92);
 by     MAREA POPCAT SEXCAT RACECAT;

 array ARRY1{7} EAPD14-EAPD16 EAPD18 EAPD90-EAPD92;
 array ARRY2{7} RAPD14-RAPD16 RAPD18 RAPD90-RAPD92;
 array ARRY3{7} LAPD14-LAPD16 LAPD18 LAPD90-LAPD92;
 array ARRY4{7} UAPD14-UAPD16 UAPD18 UAPD90-UAPD92;
 array ARRY5{7} SAPD14-SAPD16 SAPD18 SAPD90-SAPD92;
 array ARRY6{7} XAPD14-XAPD16 XAPD18 XAPD90-XAPD92;
 array ARRY7{7} PAPD14-PAPD16 PAPD18 PAPD90-PAPD92;
 array ARRY8{7} VAPD14-VAPD16 VAPD18 VAPD90-VAPD92;
 array ARRY9{7} SNAPD14-SNAPD16 SNAPD18 SNAPD90-SNAPD92;

 do I = 1 TO 7;
   if ARRY7(I) <= 2 then do;
      ARRY1(I) = .; ARRY2(I) = .; ARRY3(I) = .; ARRY4(I) = .;
      ARRY5(I) = .; ARRY6(I) = .; ARRY8(I) = .; ARRY9(I) = .; 
   end;
 end;

 drop I;

 format EAPD14 EAPD15 EAPD16 EAPD18 EAPD90 EAPD91 EAPD92 
        LAPD14 LAPD15 LAPD16 LAPD18 LAPD90 LAPD91 LAPD92 
        OAPD14 OAPD15 OAPD16 OAPD18 OAPD90 OAPD91 OAPD92 
        RAPD14 RAPD15 RAPD16 RAPD18 RAPD90 RAPD91 RAPD92 
        SAPD14 SAPD15 SAPD16 SAPD18 SAPD90 SAPD91 SAPD92 
        SNAPD14 SNAPD15 SNAPD16 SNAPD18 SNAPD90 SNAPD91 SNAPD92 
        UAPD14 UAPD15 UAPD16 UAPD18 UAPD90 UAPD91 UAPD92 
        VAPD14 VAPD15 VAPD16 VAPD18 VAPD90 VAPD91 VAPD92 
        XAPD14 XAPD15 XAPD16 XAPD18 XAPD90 XAPD91 XAPD92 13.7
        TAPD14 TAPD15 TAPD16 TAPD18 TAPD90 TAPD91 TAPD92 
        PAPD14 PAPD15 PAPD16 PAPD18 PAPD90 PAPD91 PAPD92 13.0;

 run;

 * ---------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MAREA MERGED OUTPUT FILE           --- ;
 * ---------------------------------------------------------------- ;

 proc Contents data=OUTARSK.&OUTFILE_AREARISK. position;
 run;

 proc Means data=OUTARSK.&OUTFILE_AREARISK.(WHERE=(_TYPE_ in (8))) n nmiss min max mean sum nolabels;
 title4  'SUMMARY OF AREA-LEVEL RATES (_TYPE_=8)';
 run;

 * ---------------------------------------------------------------- ;
 * --- PRINT AREA MERGED OUTPUT FILE                            --- ;
 * ---------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PD,TEXT);
 proc   Print data=OUTARSK.&OUTFILE_AREARISK. label SPLIT='*';
 var    MAREA POPCAT SEXCAT RACECAT 
        TA&PD. PA&PD. OA&PD. EA&PD. RA&PD. LA&PD. UA&PD. SA&PD. SNA&PD. XA&PD.  VA&PD. ;
 label MAREA    = "Metro Area Level"
       POPCAT   = "Population Age Categories"
       SEXCAT   = "Sex Categories"
       RACECAT  = "Race Categories"
       TA&PD. = "TA&PD.*(Numerator)"
       PA&PD. = "PA&PD.*(Population)"
       OA&PD. = "OA&PD.*(Observed rate)"
       EA&PD. = "EA&PD.*(Expected rate)"
       RA&PD. = "RA&PD.*(Risk-adjusted rate)"
       LA&PD. = "LA&PD.*(Lower CL of risk-adjusted rate)"
       UA&PD. = "UA&PD.*(Upper CL of risk-adjusted rate)"
       SA&PD. = "SA&PD.*(Smoothed rate)"
       SNA&PD. = "SNA&PD.*(Reliability of the risk-adjusted rate)"
       XA&PD. = "XA&PD.*(Standard error of the smoothed rate)"
       VA&PD. = "VA&PD.*(Variance of the risk-adjusted rate)"
       ;
 FORMAT POPCAT POPCAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
      TA&PD. PA&PD. COMMA13.0
        OA&PD. EA&PD. RA&PD. LA&PD. UA&PD. SA&PD.  SNA&PD.  VA&PD. XA&PD. 8.6;

 title4 "FINAL OUTPUT";
 title5 "Indicator &PD.: &TEXT";
 run;

 %MEND PRT;

 %PRT(PD14,Asthma Admission Rate);
 %PRT(PD15,Diabetes Short-Term Complications Admission Rate);
 %PRT(PD16,Gastroenteritis Admission Rate);
 %PRT(PD18,Urinary Tract Infection Admission Rate);
 %PRT(PD90,Pediatric Quality Overall Composite);
 %PRT(PD91,Pediatric Quality Acute Composite);
 %PRT(PD92,Pediatric Quality Chronic Composite);

 %END;

 %MEND PRT2 ;

 %PRT2;

 * ---------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO TEXT FILE                   --- ;
 * ---------------------------------------------------------------- ;

 %MACRO TEXT;
 
 %macro scale_rates;
   
   %IF &SCALE_RATES = 1 %THEN %DO;
      ARRAY RATES OAPD: EAPD: RAPD: LAPD: UAPD: SAPD:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*100000;	
	  end;
	%END;
	
 %mend scale_rates;

 %IF &TXTARSK. = 1  %THEN %DO;

 data _NULL_;
 set OUTARSK.&OUTFILE_AREARISK;
 %scale_rates;
 FILE PDTXTARA LRECL=2000;
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
 put "MAREA" "," "Age"  "," "Sex"  "," "Race"  ","  "Type" ","
 "TAPD14" "," "TAPD15" "," "TAPD16" "," 
 "TAPD18" ","
 "TAPD90" "," "TAPD91" "," "TAPD92" ","
 "PAPD14" "," "PAPD15" "," "PAPD16" "," 
 "PAPD18" ","
 "PAPD90" "," "PAPD91" "," "PAPD92" ","
 "OAPD14" "," "OAPD15" "," "OAPD16" "," 
 "OAPD18" "," 
 "OAPD90" "," "OAPD91" "," "OAPD92" ","
 "EAPD14" "," "EAPD15" "," "EAPD16" "," 
 "EAPD18" ","
 "EAPD90" "," "EAPD91" "," "EAPD92" ","
 "RAPD14" "," "RAPD15" "," "RAPD16" "," 
 "RAPD18" ","
 "RAPD90" "," "RAPD91" "," "RAPD92" ","
 "LAPD14" "," "LAPD15" "," "LAPD16" "," 
 "LAPD18" ","
 "LAPD90" "," "LAPD91" "," "LAPD92" ","
 "UAPD14" "," "UAPD15" "," "UAPD16" "," 
 "UAPD18" ","
 "UAPD90" "," "UAPD91" "," "UAPD92" ","
 "SAPD14" "," "SAPD15" "," "SAPD16" "," 
 "SAPD18" ","
 "SAPD90" "," "SAPD91" "," "SAPD92" ","
 "SNAPD14" "," "SNAPD15" "," "SNAPD16" "," 
 "SNAPD18" ","
 "SNAPD90" "," "SNAPD91" "," "SNAPD92" ","
 "VAPD14" "," "VAPD15" "," "VAPD16" "," 
 "VAPD18" ","
 "VAPD90" "," "VAPD91" "," "VAPD92" "," 
 "XAPD14" "," "XAPD15" "," "XAPD16" "," 
 "XAPD18" ","
 "XAPD90" "," "XAPD91" "," "XAPD92"
 ;
 end;

 put MAREA  $5. "," POPCAT 3. "," SEXCAT 3. "," RACECAT 3. "," _TYPE_ 2. ","
 (TAPD14-TAPD16 TAPD18 TAPD90-TAPD92) (7.0 ",")
  ","
 (PAPD14-PAPD16 PAPD18 PAPD90-PAPD92) (13.0 ",")
 ","
 (OAPD14-OAPD16 OAPD18 OAPD90-OAPD92) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (EAPD14-EAPD16 EAPD18 EAPD90-EAPD92) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (RAPD14-RAPD16 RAPD18 RAPD90-RAPD92) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (LAPD14-LAPD16 LAPD18 LAPD90-LAPD92) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (UAPD14-UAPD16 UAPD18 UAPD90-UAPD92) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (SAPD14-SAPD16 SAPD18 SAPD90-SAPD92) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ","
 (SNAPD14-SNAPD16 SNAPD18 SNAPD90-SNAPD92) (12.10 ",")
 ","
 (VAPD14-VAPD16 VAPD18 VAPD90-VAPD92) (12.10 ",")
 ","
 (XAPD14-XAPD16 XAPD18 XAPD90-XAPD92) (12.10 ",")
 ;

run;

 %END;

 %MEND TEXT;

 %TEXT;
