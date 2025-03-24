*======================= Program: IQI_HOSP_RISKADJ.SAS ==============================;
*
*  TITLE: HOSPITAL LEVEL RISK-ADJUSTED RATES FOR AHRQ INPATIENT QUALITY INDICATORS
*
*  DESCRIPTION:
*        Calculates risk-adjusted and smoothed rates for Inpatient Quality
*        Indicators, adjusting for: SEX, AGE, DXCCSRS, PRCCSRS, AND MDC.
*        Variables created by the program: RPIQxx, LPIQxx, UPIQxx, SPIQxx, XPIQxx, VPIQxx, SNPIQxx
*        Output stratified by HOSPID AGECAT SEXCAT PAYCAT RACECAT.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*  USER NOTE1: The AHRQ QI software does not support the calculation of weighted
*              estimates and standard errors using complex sampling designs.
*
*  USER NOTE2: Not all stratified risk adjustment rates are provided for strata 
*              containing PAYCAT or RACECAT.
*              Stratified risk adjustment rates are not provided for strata 
*              containing AGECAT or SEXCAT.
*
*====================================================================================;

title2 'PROGRAM IQI_HOSP_RISKADJ';
title3 'AHRQ INPATIENT QUALITY INDICATORS: CALCULATE RISK-ADJUSTED HOSPITAL RATES';

* ----------------------------------------------------------------------------------------------------------- ;
* INPATIENT QUALITY HOSPITAL-LEVEL UTILIZATION OR PROCESS MEASURES (IQI 21, 22 AND 33) ARE NOT RISK-ADJUSTED. ;
* FOR THESE INDICATORS, THE OBSERVED RATE IS THE APPLICABLE MEASURE OF PERFORMANCE.                           ;
* ----------------------------------------------------------------------------------------------------------- ;

* ---------------------------------------------------------------------- ;
* --- INPATIENT QUALITY INDICATOR (IQI) NAMING CONVENTION:           --- ;
* --- THE FIRST LETTER IDENTIFIES THE PATIENT SAFETY                 --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                             --- ;
* ---       (T) NUMERATOR ("TOP") - FROM IQI_HOSP_MEASURES           --- ;
* ---       (P) DENOMINATOR ("POP") - FROM IQI_HOSP_MEASURES         --- ;
* ---       (O) OBSERVED RATES (T/P)                                 --- ;
* ---       (E) EXPECTED RATE                                        --- ;
* ---       (V) VARIANCE                                             --- ;
* ---       (R) RISK-ADJUSTED RATE                                   --- ;
* ---       (L) LOWER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE        --- ;
* ---       (U) UPPER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE        --- ;
* ---       (S) SMOOTHED RATE (NOT REPORTED FOR STRATA)              --- ;
* ---       (X) SMOOTHED RATE STANDARD ERROR (NOT REPORTED FOR STRATA) - ;
* --- THE SECOND LETTER IDENTIFIES THE IQI AS A HOSPITAL (P)         --- ;
* --- LEVEL INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS 'IQ'.     --- ;
* --- THE LAST TWO DIGITS ARE THE INDICATOR NUMBER                   --- ;
* ---------------------------------------------------------------------- ;
* --- THE IQI_HOSP_REGVARS_v2024.SAS PROGRAM CREATES VARIABLES       --- ;
* --- USED FOR RISK ADJUSTMENT. THE USER MUST ENSURE THAT THE        --- ;
* --- IQI_HOSP_CONTROL PROGRAM INCLUDES THE CORRECT LOCATION FOR THE --- ;
* --- IQI_HOSP_REGVARS_v2024 SAS CODE.                               --- ;
*----------------------------------------------------------------------- ;

data &OUTFILE_MEAS.;
    set OUTHOBS.&OUTFILE_MEAS.;
    %include Maclib(IQI_HOSP_Regvars_v2024.sas);
run ;

%MACRO MOD3(IQ);

* --- CREATE AN INDICATOR-LEVEL FLAG FOR WHETHER RISK-ADJUSTED AND SMOOTHED RATES ARE SUPPRESSED DUE TO NO PRDAY --- ;
%let IQ_PRDAY = 08 09 11 12 30 31;
%let PRDAY_RA = 0;
%if &PRDAY. = 0 %then %do;
  %do i=1 %to %sysfunc(countw(&IQ_PRDAY., " "));
    %if %scan(&IQ_PRDAY.,&i.," ") = %substr(&IQ.,1,2) %then %let PRDAY_RA = 1;
  %end;
%end;

* --- DO NOT CALCULATE RISK-ADJUSTED AND SMOOTHED RATES IF CERTAIN FLAGS ARE SET IN THE CONTROL PROGRAM --- ;
%if &MDC_PROVIDED. = 0 or &PRDAY_RA. = 1 %then %let SUPPRESS_RA = 1;
  %else %let SUPPRESS_RA = 0;

*** Start discharge scoring for all but the overall stratified measures ;

 * --- PARAMETER FILE USED FOR SCORING --- ;
 filename RACOEFFS  "&RADIR./Gee_IQ&IQ._AGE_SEX.csv";

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

 data MODEL_IQ&IQ.;
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

 * --- APPLY PROC SCORE TO DATA --- ;
 proc Score data=&OUTFILE_MEAS. (where=(TPIQ&IQ. in (0,1))) score=MODEL_IQ&IQ. type=PARMS out=TEMP1Y&iq.;
   var &VARS_. ;
 run;

 * --- CALCULATE PREDICTED VALUES (EHAT) --- ;
 data TEMP1Y&iq.;
   set TEMP1Y&iq.;
   EHAT = EXP(MHAT)/(1 + EXP(MHAT));
 run;

*** End discharge scoring for all but the overall stratified measures ;

 %LET DSID=%SYSFUNC(OPEN(TEMP1Y&iq.));
 %IF &dsid. %THEN %LET DNUM=%SYSFUNC(ATTRN(&dsid,NOBS));
 %ELSE %LET DNUM=0;
 %LET DRC=%SYSFUNC(CLOSE(&dsid));

 %IF &dnum NE 0 %THEN %DO;

* --- EHAT IS CAPPED AT THE VALUE 0.99                                 --- ;
* --- IF THE FLAG, CALIBRATION_OE_TO_REF_POP = 1, SET EHAT TO EHAT*O_E --- ;
* --- AND USE THE MODIFIED VALUE OF EHAT GOING FORWARD.                --- ;
%if &Calibration_OE_to_ref_pop. = 1 %then %do;
 DATA TEMP1Y&iq.;  
    SET TEMP1Y&iq.;    
    
    %include maclib(IQI_HOSP_OE_Array_v2024.sas);
    
    * --- MAP MEASURE NUM TO ARRAY INDEX SUB_N --- ;
    if "&IQ." = "08"  then SUB_N = 1;
    if "&IQ." = "09"  then SUB_N = 2;
    if "&IQ." = "11"  then SUB_N = 3;
    if "&IQ." = "12"  then SUB_N = 4;
    if "&IQ." = "15"  then SUB_N = 5;
    if "&IQ." = "16"  then SUB_N = 6;
    if "&IQ." = "17"  then SUB_N = 7;
    if "&IQ." = "18"  then SUB_N = 8;
    if "&IQ." = "19"  then SUB_N = 9;
    if "&IQ." = "20"  then SUB_N = 10;
    if "&IQ." = "30"  then SUB_N = 11;
    if "&IQ." = "31"  then SUB_N = 12;
    
    EHAT=EHAT*ARRYOE(SUB_N);
    if EHAT > 0.99 then EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT);
    DUMMY = 1;
 RUN;
%end;

/* --- if flag set to 0, adjust EHAT using overall O/E ratio for current data --- */
%else %if &Calibration_OE_to_ref_pop. = 0 %then %do; 
 PROC MEANS DATA=TEMP1Y&iq. noprint;
    VAR TPIQ&IQ. EHAT;
    OUTPUT OUT=OE&IQ.(DROP=_TYPE_ _FREQ_) SUM(TPIQ&IQ. EHAT)=TPIQ&IQ. EHAT;
 RUN;
 
 DATA OE&IQ.;
    SET OE&IQ.;
    O_E&IQ.=TPIQ&IQ./EHAT;
 RUN;
 
 PROC PRINT DATA=OE&IQ.;
 RUN;
 
 DATA OE&IQ.;
    SET OE&IQ.(KEEP=O_E&IQ.);
 RUN;
 
 DATA TEMP1Y&iq.;  
    IF _N_=1 THEN SET OE&IQ.;
    SET TEMP1Y&iq.;
    
    EHAT=EHAT*O_E&IQ.;
    if EHAT > 0.99 then EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT);
    DUMMY = 1;
 RUN;
%end;

 * --- SUMMARIZE BY VARIOUS CLASSES --- ;

 proc   SUMMARY data=TEMP1Y&iq.;
 class  HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 var    TPIQ&IQ. EHAT PHAT;
 weight DUMMY;
 output out=RPIQ&IQ. sum(TPIQ&IQ. EHAT PHAT)=TPIQ&IQ. EHAT PHAT
                     sumwgt(TPIQ&IQ.)=PPIQ&IQ.
                     N=DENOM;
 run;


 * --- APPLY RISK ADJUSTMENT & SMOOTHING --- ;

 data   RPIQ&IQ.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT
                 EPIQ&IQ. RPIQ&IQ. LPIQ&IQ. UPIQ&IQ. SPIQ&IQ. SNPIQ&IQ. XPIQ&IQ. VPIQ&IQ.
                 TPIQ&IQ. PPIQ&IQ. OPIQ&IQ. 
                 );
 set    RPIQ&IQ.;

 if _TYPE_ &TYPELVLH;

 * --- LOAD SIGNAL AND NOISE ARRAYS FROM TEXT FILE --- ;

 %include maclib(IQI_HOSP_Sigvar_Array_v2024.sas);

 * --- MAP MEASURE NUM TO ARRAY INDEX SUB_N --- ;
 if "&IQ." = "08"  then SUB_N = 1;
 if "&IQ." = "09"  then SUB_N = 2;
 if "&IQ." = "11"  then SUB_N = 3;
 if "&IQ." = "12"  then SUB_N = 4;
 if "&IQ." = "15"  then SUB_N = 5;
 if "&IQ." = "16"  then SUB_N = 6;
 if "&IQ." = "17"  then SUB_N = 7;
 if "&IQ." = "18"  then SUB_N = 8;
 if "&IQ." = "19"  then SUB_N = 9;
 if "&IQ." = "20"  then SUB_N = 10;
 if "&IQ." = "30"  then SUB_N = 11;
 if "&IQ." = "31"  then SUB_N = 12;

 * --- T = NUMERATOR     --- ;
 * --- P = DENOMINATOR   --- ;
 * --- E = EXPECTED      --- ;
 * --- O = OBSERVED      --- ;
 * --- R = RISK ADJUSTED --- ;
 * --- L = LOWER CI      --- ;
 * --- U = UPPER CI      --- ;
 * --- S = SMOOTHED      --- ;
 * --- X = SMOOTHED SE   --- ;
 * --- V = VARIANCE      --- ;

 EPIQ&IQ. = EHAT / PPIQ&IQ.;
 THAT = TPIQ&IQ. / PPIQ&IQ.;
 OPIQ&IQ. = TPIQ&IQ. / PPIQ&IQ.;


 if _TYPE_ in (0,16) and &SUPPRESS_RA. = 0 then do;
    RPIQ&IQ.  = (THAT / EPIQ&IQ.) * ARRYP3(SUB_N);
    SE&IQ.    = (ARRYP3(SUB_N) / EPIQ&IQ.) * (1 / PPIQ&IQ.) * SQRT(PHAT);
    VPIQ&IQ.  = SE&IQ.**2;
    SNPIQ&IQ. = ARRYP2(SUB_N) / (ARRYP2(SUB_N) + VPIQ&IQ.);
    SPIQ&IQ.  = (RPIQ&IQ. * SNPIQ&IQ.) + ((1 -  SNPIQ&IQ.) * ARRYP3(SUB_N));
    XPIQ&IQ.  = SQRT(ARRYP2(SUB_N)- (SNPIQ&IQ. * ARRYP2(SUB_N)));
 end;
 else if _TYPE_ in (1,2,3,17,18,19) and &SUPPRESS_RA. = 0 then do;
    RPIQ&IQ.  = (THAT / EPIQ&IQ.);
    SE&IQ.    = (1 / EPIQ&IQ.) * (1 / PPIQ&IQ.) * SQRT(PHAT);
    VPIQ&IQ.  = SE&IQ.**2;
    SNPIQ&IQ. = .;
    SPIQ&IQ.  = .;
    XPIQ&IQ.  = .;
 end;
 else do;
    EPIQ&IQ.  = .;
    RPIQ&IQ.  = .;
    SE&IQ.    = .;
    VPIQ&IQ.  = .;
    SNPIQ&IQ. = .;
    SPIQ&IQ.  = .;
    XPIQ&IQ.  = .;
    LPIQ&IQ.  = .;
    UPIQ&IQ.  = .;
 end;

 if not missing(RPIQ&IQ.) then do;
   LPIQ&IQ.   = RPIQ&IQ. - (1.96 * SE&IQ.);
   if LPIQ&IQ. < 0 then LPIQ&IQ. = 0;
   UPIQ&IQ.   = RPIQ&IQ. + (1.96 * SE&IQ.);

   if _TYPE_ in (0,16) then do;
     if LPIQ&IQ. > 1 then LPIQ&IQ. = 1; 
     if UPIQ&IQ. > 1 then UPIQ&IQ. = 1;
     if RPIQ&IQ. > 1 then RPIQ&IQ. = 1;
     if SPIQ&IQ. > 1 then SPIQ&IQ. = 1;
   end;
 end;

 run;

 %END;

 %ELSE %DO;

 data RPIQ&IQ.;
    length HOSPID &HOSPID_TYP.. AGECAT SEXCAT RACECAT PAYCAT 3;
    call missing(HOSPID); _TYPE_=0; AGECAT=.; SEXCAT=.; RACECAT=.; PAYCAT=.;
    EPIQ&IQ=.; RPIQ&IQ=.; SE&IQ.=.; VPIQ&IQ=.; SNPIQ&IQ.=.; SPIQ&IQ=.; XPIQ&IQ=.; LPIQ&IQ=.; UPIQ&IQ=.;
    TPIQ&IQ=.; PPIQ&IQ=.; OPIQ&IQ.=.;
    output;
 run;

 %END;

 proc SORT data=RPIQ&IQ.;
   by _TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 run; quit;

 proc   DATASETS NOLIST;
 delete TEMP1 TEMP1_MODEL TEMP2_MODEL;
 run;


 %MEND MOD3;


%MOD3(08) ;
%MOD3(09) ;
%MOD3(11) ;
%MOD3(12) ;
%MOD3(15) ;
%MOD3(16) ;
%MOD3(17) ;
%MOD3(18) ;
%MOD3(19) ;
%MOD3(20) ;
%MOD3(30) ;
%MOD3(31) ;


 * ------------------------------------------------------------------ ;
 * --- MERGE THE HOSPITAL ADJUSTED RATES FOR EACH INDICATOR       --- ;
 * ------------------------------------------------------------------ ;

 proc sort data=OUTHOBS.&OUTFILE_HOSPOBS. out=&OUTFILE_HOSPOBS.;
   by _TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 run;

 data OUTHRISK.&OUTFILE_HOSPRISK.;
 merge  RPIQ08
        RPIQ09 
        &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ09_WITH_CANCER    PPIQ09_WITH_CANCER    OPIQ09_WITH_CANCER    where=(PPIQ09_WITH_CANCER >0))
        &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ09_WITHOUT_CANCER PPIQ09_WITHOUT_CANCER OPIQ09_WITHOUT_CANCER where=(PPIQ09_WITHOUT_CANCER >0))
        RPIQ11 
        &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ11_OPEN_RUPTURED   PPIQ11_OPEN_RUPTURED   OPIQ11_OPEN_RUPTURED   where=(PPIQ11_OPEN_RUPTURED >0))
        &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ11_OPEN_UNRUPTURED PPIQ11_OPEN_UNRUPTURED OPIQ11_OPEN_UNRUPTURED where=(PPIQ11_OPEN_UNRUPTURED >0))
        &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ11_ENDO_RUPTURED   PPIQ11_ENDO_RUPTURED   OPIQ11_ENDO_RUPTURED   where=(PPIQ11_ENDO_RUPTURED >0))
        &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ11_ENDO_UNRUPTURED PPIQ11_ENDO_UNRUPTURED OPIQ11_ENDO_UNRUPTURED where=(PPIQ11_ENDO_UNRUPTURED >0))
        RPIQ12 
        RPIQ15 
        RPIQ16 
        RPIQ17 
        &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ17_HEMSTROKE_SUBARACH PPIQ17_HEMSTROKE_SUBARACH OPIQ17_HEMSTROKE_SUBARACH where=(PPIQ17_HEMSTROKE_SUBARACH >0))
        &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ17_HEMSTROKE_INTRACER PPIQ17_HEMSTROKE_INTRACER OPIQ17_HEMSTROKE_INTRACER where=(PPIQ17_HEMSTROKE_INTRACER >0))
        &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ17_ISCHEMSTROKE       PPIQ17_ISCHEMSTROKE       OPIQ17_ISCHEMSTROKE       where=(PPIQ17_ISCHEMSTROKE >0))
        RPIQ18 
        RPIQ19 
        RPIQ20 
        RPIQ30 
        RPIQ31;
 by _TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT;

 %macro label_qis(strat_flag=, qi_num=, qi_name=);
   label
   PP&qi_num. = "&qi_name. (Population)"
   OP&qi_num. = "&qi_name. (Observed rate)"
   ;

   %if &strat_flag. = 0 %then %do;
     label
     EP&qi_num. = "&qi_name. (Expected rate)"
     RP&qi_num. = "&qi_name. (Risk-adjusted rate)"
     LP&qi_num. = "&qi_name. (Lower CL of risk-adjusted rate)"
     UP&qi_num. = "&qi_name. (Upper CL of risk-adjusted rate)"
     VP&qi_num. = "&qi_name. (Variance of the risk-adjusted rate)"
     SNP&qi_num. = "&qi_name. (Reliability of the risk-adjusted rate)"
     SP&qi_num. = "&qi_name. (Smoothed rate)"
     XP&qi_num. = "&qi_name. (Standard error of the smoothed rate)"
     ;
   %end;

 %mend label_qis;

 %label_qis(strat_flag=0, qi_num=IQ08,                    qi_name=IQI 08 Esophageal Resection Mortality Rate);
 %label_qis(strat_flag=0, qi_num=IQ09,                    qi_name=IQI 09 Pancreatic Resection Mortality Rate);
 %label_qis(strat_flag=1, qi_num=IQ09_WITH_CANCER,        qi_name=IQI 09 Pancreatic Resection Mortality Rate Stratum: Presence of Pancreatic Cancer);
 %label_qis(strat_flag=1, qi_num=IQ09_WITHOUT_CANCER,     qi_name=IQI 09 Pancreatic Resection Mortality Rate Stratum: Absence of Pancreatic Cancer);
 %label_qis(strat_flag=0, qi_num=IQ11,                    qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate);
 %label_qis(strat_flag=1, qi_num=IQ11_OPEN_RUPTURED,      qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_OPEN_RUPTURED: Open Repair of Ruptured AAA);
 %label_qis(strat_flag=1, qi_num=IQ11_OPEN_UNRUPTURED,    qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_OPEN_UNRUPTURED: Open Repair of Unruptured AAA);
 %label_qis(strat_flag=1, qi_num=IQ11_ENDO_RUPTURED,      qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_ENDO_RUPTURED: Endovascular Repair of Ruptured AAA);
 %label_qis(strat_flag=1, qi_num=IQ11_ENDO_UNRUPTURED,    qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_ENDO_UNRUPTURED: Endovascular Repair of Unruptured AAA);
 %label_qis(strat_flag=0, qi_num=IQ12,                    qi_name=IQI 12 Coronary Artery Bypass Graft (CABG) Mortality Rate);
 %label_qis(strat_flag=0, qi_num=IQ15,                    qi_name=IQI 15 Acute Myocardial Infarction (AMI) Mortality Rate);
 %label_qis(strat_flag=0, qi_num=IQ16,                    qi_name=IQI 16 Heart Failure Mortality Rate);
 %label_qis(strat_flag=0, qi_num=IQ17,                    qi_name=IQI 17 Acute Stroke Mortality Rate);
 %label_qis(strat_flag=1, qi_num=IQ17_HEMSTROKE_SUBARACH, qi_name=IQI 17 Acute Stroke Mortality Rate Stratum_HEMSTROKE_SUBARACH: Subarachnoid Hemorrhage);
 %label_qis(strat_flag=1, qi_num=IQ17_HEMSTROKE_INTRACER, qi_name=IQI 17 Acute Stroke Mortality Rate Stratum_HEMSTROKE_INTRACER: Intracerebral Hemorrhage);
 %label_qis(strat_flag=1, qi_num=IQ17_ISCHEMSTROKE,       qi_name=IQI 17 Acute Stroke Mortality Rate Stratum_ISCHEMSTROKE: Ischemic Stroke);
 %label_qis(strat_flag=0, qi_num=IQ18,                    qi_name=IQI 18 Gastrointestinal Hemorrhage Mortality Rate);
 %label_qis(strat_flag=0, qi_num=IQ19,                    qi_name=IQI 19 Hip Fracture Mortality Rate);
 %label_qis(strat_flag=0, qi_num=IQ20,                    qi_name=IQI 20 Pneumonia Mortality Rate);
 %label_qis(strat_flag=0, qi_num=IQ30,                    qi_name=IQI 30 Percutaneous Coronary Intervention (PCI) Mortality Rate);
 %label_qis(strat_flag=0, qi_num=IQ31,                    qi_name=IQI 31 Carotid Endarterectomy Mortality Rate);


 %include maclib(IQI_HOSP_Sigvar_Array_v2024.sas);

 array ARRY1{12} EPIQ08-EPIQ09 EPIQ11 EPIQ12 EPIQ15-EPIQ17 EPIQ18-EPIQ20 EPIQ30-EPIQ31;
 array ARRY2{12} RPIQ08-RPIQ09 RPIQ11 RPIQ12 RPIQ15-RPIQ17 RPIQ18-RPIQ20 RPIQ30-RPIQ31;
 array ARRY3{12} LPIQ08-LPIQ09 LPIQ11 LPIQ12 LPIQ15-LPIQ17 LPIQ18-LPIQ20 LPIQ30-LPIQ31;
 array ARRY4{12} UPIQ08-UPIQ09 UPIQ11 UPIQ12 UPIQ15-UPIQ17 UPIQ18-UPIQ20 UPIQ30-UPIQ31;
 array ARRY5{12} SPIQ08-SPIQ09 SPIQ11 SPIQ12 SPIQ15-SPIQ17 SPIQ18-SPIQ20 SPIQ30-SPIQ31;
 array ARRY6{12} XPIQ08-XPIQ09 XPIQ11 XPIQ12 XPIQ15-XPIQ17 XPIQ18-XPIQ20 XPIQ30-XPIQ31;
 array ARRY7{12} VPIQ08-VPIQ09 VPIQ11 VPIQ12 VPIQ15-VPIQ17 VPIQ18-VPIQ20 VPIQ30-VPIQ31;
 array ARRY8{12} PPIQ08-PPIQ09 PPIQ11 PPIQ12 PPIQ15-PPIQ17 PPIQ18-PPIQ20 PPIQ30-PPIQ31;
 array ARRY9{12} SNPIQ08-SNPIQ09 SNPIQ11 SNPIQ12 SNPIQ15-SNPIQ17 SNPIQ18-SNPIQ20 SNPIQ30-SNPIQ31;

 do I = 1 TO 12;
   if ARRY8(I) <= 2 then do;
      ARRY1(I) = .; ARRY2(I) = .; ARRY3(I) = .; ARRY4(I) = .;
      ARRY5(I) = .; ARRY6(I) = .; ARRY7(I) = .; ARRY9(I) = .;
   end;
 end;

 drop I;

 format EPIQ08  EPIQ09 EPIQ11 EPIQ12 EPIQ15 EPIQ16 EPIQ17 EPIQ18 EPIQ19 EPIQ20 EPIQ30 EPIQ31
        LPIQ08  LPIQ09 LPIQ11 LPIQ12 LPIQ15 LPIQ16 LPIQ17 LPIQ18 LPIQ19 LPIQ20 LPIQ30 LPIQ31
        OPIQ08  OPIQ09 OPIQ09_WITH_CANCER OPIQ09_WITHOUT_CANCER OPIQ11 OPIQ11_OPEN_RUPTURED OPIQ11_OPEN_UNRUPTURED OPIQ11_ENDO_RUPTURED OPIQ11_ENDO_UNRUPTURED OPIQ12 OPIQ15 OPIQ16
        OPIQ17  OPIQ17_HEMSTROKE_SUBARACH OPIQ17_HEMSTROKE_INTRACER OPIQ17_ISCHEMSTROKE OPIQ18 OPIQ19 OPIQ20 OPIQ30 OPIQ31

        RPIQ08  RPIQ09 RPIQ11 RPIQ12 RPIQ15 RPIQ16 RPIQ17 RPIQ18 RPIQ19 RPIQ20 RPIQ30 RPIQ31
		SPIQ08  SPIQ09 SPIQ11 SPIQ12 SPIQ15 SPIQ16 SPIQ17 SPIQ18 SPIQ19 SPIQ20 SPIQ30 SPIQ31
        SNPIQ08  SNPIQ09 SNPIQ11 SNPIQ12 SNPIQ15 SNPIQ16 SNPIQ17 SNPIQ18 SNPIQ19 SNPIQ20 SNPIQ30 SNPIQ31
        UPIQ08  UPIQ09 UPIQ11 UPIQ12 UPIQ15 UPIQ16 UPIQ17 UPIQ18 UPIQ19 UPIQ20 UPIQ30 UPIQ31
        VPIQ08  VPIQ09 VPIQ11 VPIQ12 VPIQ15 VPIQ16 VPIQ17 VPIQ18 VPIQ19 VPIQ20 VPIQ30 VPIQ31
        XPIQ08  XPIQ09 XPIQ11 XPIQ12 XPIQ15 XPIQ16 XPIQ17 XPIQ18 XPIQ19 XPIQ20 XPIQ30 XPIQ31 13.7

        TPIQ08  TPIQ09  TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER
        TPIQ11  TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED TPIQ12 TPIQ15  TPIQ16 TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE TPIQ18
        TPIQ19  TPIQ20  TPIQ30 TPIQ31

        PPIQ08  PPIQ09  PPIQ09_WITH_CANCER PPIQ09_WITHOUT_CANCER PPIQ11 PPIQ11_OPEN_RUPTURED PPIQ11_OPEN_UNRUPTURED PPIQ11_ENDO_RUPTURED PPIQ11_ENDO_UNRUPTURED PPIQ12 PPIQ15 PPIQ16
        PPIQ17  PPIQ17_HEMSTROKE_SUBARACH PPIQ17_HEMSTROKE_INTRACER PPIQ17_ISCHEMSTROKE PPIQ18 PPIQ19  PPIQ20 PPIQ30  PPIQ31 13.0;

 run;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF HOSPITAL-LEVEL MERGED FILE --------- ;
 * -------------------------------------------------------------- ;

 proc Contents data=OUTHRISK.&OUTFILE_HOSPRISK. position;
 run;

 ***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;
 proc Means data=OUTHRISK.&OUTFILE_HOSPRISK. (where=(_TYPE_ in (16))) n nmiss min max mean sum nolabels;
 title4 "SUMMARY OF HOSPITAL-LEVEL RATES (_TYPE_=16)";
 run;

 * -------------------------------------------------------------- ;
 * --- PRINT HOSPITAL MERGED FILE ------------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(STRAT_FLAG, IQ,TEXT,VOLUME,STRATA);

 proc  PRINT data=OUTHRISK.&OUTFILE_HOSPRISK. label SPLIT='*';
 %IF   &VOLUME = 0 AND &STRATA=0 %THEN %DO;
 var   HOSPID AGECAT SEXCAT PAYCAT RACECAT
       TPIQ&IQ. PPIQ&IQ. OPIQ&IQ. %IF &STRAT_FLAG.=0 %THEN %DO; EPIQ&IQ. RPIQ&IQ. LPIQ&IQ. UPIQ&IQ. SPIQ&IQ. XPIQ&IQ. %END;;
 label HOSPID  = "Hospital Identification Number"
       AGECAT  = "Age Categories"
       SEXCAT  = "Sex Categories"
       PAYCAT  = "Patient Primary Payer"
       RACECAT = "Race Categories"
       TPIQ&IQ.   = "TPIQ&IQ.*(Numerator)"
       PPIQ&IQ.   = "PPIQ&IQ.*(Population)"
       OPIQ&IQ.   = "OPIQ&IQ.*(Observed rate)"
       %IF &STRAT_FLAG.=0 %THEN %DO; 
       EPIQ&IQ.   = "EPIQ&IQ.*(Expected rate)"
       RPIQ&IQ.   = "RPIQ&IQ.*(Risk-Adjusted rate)"
       LPIQ&IQ.   = "LPIQ&IQ.*(Lower CL of risk-adjusted rate)"
       UPIQ&IQ.   = "UPIQ&IQ.*(Upper CL of risk-adjusted rate)"
       SPIQ&IQ.   = "SPIQ&IQ.*(Smoothed rate)"
       XPIQ&IQ.   = "XPIQ&IQ.*(Standard Error of the smoothed rate)"
       %END;
       ;
 format AGECAT AGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
        TPIQ&IQ. PPIQ&IQ. 13.0 OPIQ&IQ. %IF &STRAT_FLAG.=0 %THEN %DO; EPIQ&IQ. RPIQ&IQ. LPIQ&IQ. UPIQ&IQ. SPIQ&IQ. XPIQ&IQ. %END; 8.6;
 %END;
 %ELSE %IF &STRATA=1 %THEN %DO;
 var   HOSPID AGECAT SEXCAT PAYCAT RACECAT
       TPIQ&IQ. PPIQ&IQ. OPIQ&IQ. %IF &STRAT_FLAG.=0 %THEN %DO; EPIQ&IQ. RPIQ&IQ. LPIQ&IQ. UPIQ&IQ. %END;;
 label HOSPID  = "Hospital Identification Number"
       AGECAT  = "Age Categories"
       SEXCAT  = "Sex Categories"
       PAYCAT  = "Patient Primary Payer"
       RACECAT = "Race Categories"
       TPIQ&IQ.   = "TPIQ&IQ.*(Numerator)"
       PPIQ&IQ.   = "PPIQ&IQ.*(Population)"
       OPIQ&IQ.   = "OPIQ&IQ.*(Observed rate)"
       %IF &STRAT_FLAG.=0 %THEN %DO; 
       EPIQ&IQ.   = "EPIQ&IQ.*(Expected rate)"
       RPIQ&IQ.   = "RPIQ&IQ.*(Risk-Adjusted rate)"
       LPIQ&IQ.   = "LPIQ&IQ.*(Lower CL of risk-adjusted rate)"
       UPIQ&IQ.   = "UPIQ&IQ.*(Upper CL of risk-adjusted rate)"
       %END;
       ;
 format AGECAT AGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
        TPIQ&IQ. PPIQ&IQ. 13.0 OPIQ&IQ. %IF &STRAT_FLAG.=0 %THEN %DO; EPIQ&IQ. RPIQ&IQ. LPIQ&IQ. UPIQ&IQ. %END; 8.6;
 %END;

 %ELSE %IF &VOLUME=1 %THEN %DO;
 var   HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ&IQ.;
 label HOSPID  	  = "Hospital Identification Number"
       AGECAT     = "Age Categories"
       SEXCAT     = "Sex Categories"
       PAYCAT     = "Patient Primary Payer"
       RACECAT    = "Race Categories"
       TPIQ&IQ.   = "TPIQ&IQ.*(Numerator)"
       ;
 format AGECAT AGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
        TPIQ&IQ. 13.0;
 %END;
 title4 "FINAL OUTPUT";
 title5 "INDICATOR  &IQ.: &TEXT";

 run;

 %MEND PRT;

 %PRT(0, 08, ESOPHAGEAL RESECTION MORTALITY RATE,0,0);
 %PRT(0, 09, PANCREATIC RESECTION MORTALITY RATE,0,0);
 %PRT(1, 09_WITH_CANCER, PANCREATIC RESECTION MORTALITY RATE STR_WITH_CANCER – WITH PANCR CANCER,0,1);
 %PRT(1, 09_WITHOUT_CANCER, PANCREATIC RESECTION MORTALITY RATE STR_WITHOUT_CANCER – WITHOUT PANCR CANCER,0,1);
 %PRT(0, 11, ABDOMINAL AORTIC ANEURYSM (AAA) REPAIR MORTALITY RATE,0,0);
 %PRT(1, 11_OPEN_RUPTURED, ABDOMINAL AORTIC ANEURYSM (AAA) REPAIR MORTALITY RATE STR_OPEN_RUPTURED – OPEN REPAIR RUPTURED AAA,0,1);
 %PRT(1, 11_OPEN_UNRUPTURED, ABDOMINAL AORTIC ANEURYSM (AAA) REPAIR MORTALITY RATE STR_OPEN_UNRUPTURED – OPEN REPAIR UNRUPTURED AAA,0,1);
 %PRT(1, 11_ENDO_RUPTURED, ABDOMINAL AORTIC ANEURYSM (AAA) REPAIR MORTALITY RATE STR_ENDO_RUPTURED – ENDOVASC REPAIR RUPTURED AAA,0,1);
 %PRT(1, 11_ENDO_UNRUPTURED, ABDOMINAL AORTIC ANEURYSM (AAA) REPAIR MORTALITY RATE STR_ENDO_UNRUPTURED – ENDOVASC REPAIR UNRUPTURED AAA,0,1);
 %PRT(0, 12, CORONARY ARTERY BYPASS GRAFT (CABG) MORTALITY RATE,0,0);
 %PRT(0, 15, ACUTE MYOCARDIAL INFARCTION (AMI) MORTALITY RATE,0,0);
 %PRT(0, 16, HEART FAILURE MORTALITY RATE,0,0);
 %PRT(0, 17, ACUTE STROKE MORTALITY RATE,0,0);
 %PRT(1, 17_HEMSTROKE_SUBARACH, ACUTE STROKE MORTALITY RATE STR_HEMSTROKE_SUBARACH – SUBARACHNOID,0,1);
 %PRT(1, 17_HEMSTROKE_INTRACER, ACUTE STROKE MORTALITY RATE STR_HEMSTROKE_INTRACER – INTRACEREBRAL,0,1);
 %PRT(1, 17_ISCHEMSTROKE, ACUTE STROKE MORTALITY RATE STR_ISCHEMSTROKE – ISCHEMIC,0,1);
 %PRT(0, 18, GASTROINTESTINAL HEMORRHAGE MORTALITY RATE,0,0);
 %PRT(0, 19, HIP FRACTURE MORTALITY RATE,0,0);
 %PRT(0, 20, PNEUMONIA MORTALITY RATE,0,0);
 %PRT(0, 30, PERCUTANEOUS CORONARY INTERVENTION (PCI) MORTALITY RATE,0,0);
 %PRT(0, 31, CAROTID ENDARTERECTOMY MORTALITY RATE,0,0);


 %END;

 %MEND PRT2;

 %PRT2;

 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS                           --- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXT;
 
 %macro scale_rates;
   
   %IF &SCALE_RATES = 1 %THEN %DO;
      ARRAY RATES OPPS: EPPS: RPPS: LPPS: UPPS: SPPS:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*1000;	
	  end;
	%END;
	
%mend scale_rates;

 %IF &TXTHRISK. = 1 %THEN %DO;
    %LET TYPEPRN  = %sysfunc(tranwrd(&TYPELVLH.,%str(,),_));
    %LET TYPEPRN2  = %sysfunc(compress(&TYPEPRN.,'(IN )'));
    %let IQCSVREF = %sysfunc(pathname(IQTXTHRA));
    %let IQCSVRF2 =  %sysfunc(tranwrd(&IQCSVREF.,.TXT,_&TYPEPRN2..TXT));

 data _NULL_;
 set OUTHRISK.&OUTFILE_HOSPRISK.;
 %scale_rates;
 file "&IQCSVRF2." lrecl=4000;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_HOSPRISK data set created with the following CONTROL options:";
 put "&&Calibration_OE_to_ref_pop&Calibration_OE_to_ref_pop. (Calibration_OE_to_ref_pop = &Calibration_OE_to_ref_pop)";
 put "&&MDC_PROVIDED&MDC_PROVIDED. (MDC_PROVIDED = &MDC_PROVIDED)";
 put "&&PRDAY&PRDAY. (PRDAY = &PRDAY)";
 put "Output stratification includes TYPELVLH = &TYPELVLH";
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put
 "HOSP ID" ","  "AGE"     "," "SEX"     "," "PAYER"   "," "RACE"  "," "TYPE" ","
 "TPIQ08"  ","  "TPIQ09"  "," "TPIQ09_WITH_CANCER" "," "TPIQ09_WITHOUT_CANCER" ","
 "TPIQ11"  ","  "TPIQ11_OPEN_RUPTURED" "," "TPIQ11_OPEN_UNRUPTURED" "," "TPIQ11_ENDO_RUPTURED" "," "TPIQ11_ENDO_UNRUPTURED" ","
 "TPIQ12"  ","  "TPIQ15"  "," "TPIQ16"  ","
 "TPIQ17"  ","  "TPIQ17_HEMSTROKE_SUBARACH" "," "TPIQ17_HEMSTROKE_INTRACER" "," "TPIQ17_ISCHEMSTROKE" "," "TPIQ18"  "," "TPIQ19"  ","
 "TPIQ20"  ","  "TPIQ30"  "," "TPIQ31"  "," 
 "PPIQ08"  ","  "PPIQ09"  "," "PPIQ09_WITH_CANCER" "," "PPIQ09_WITHOUT_CANCER" ","
 "PPIQ11"  ","  "PPIQ11_OPEN_RUPTURED" "," "PPIQ11_OPEN_UNRUPTURED" "," "PPIQ11_ENDO_RUPTURED" "," "PPIQ11_ENDO_UNRUPTURED" ","
 "PPIQ12"  ","  "PPIQ15"  "," "PPIQ16"  ","
 "PPIQ17"  ","  "PPIQ17_HEMSTROKE_SUBARACH" "," "PPIQ17_HEMSTROKE_INTRACER" "," "PPIQ17_ISCHEMSTROKE" "," "PPIQ18"  ","
 "PPIQ19"  ","  "PPIQ20"  "," "PPIQ30"  "," "PPIQ31"  "," 
 "OPIQ08"  ","  "OPIQ09"  "," "OPIQ09_WITH_CANCER" "," "OPIQ09_WITHOUT_CANCER" ","
 "OPIQ11"  ","  "OPIQ11_OPEN_RUPTURED" "," "OPIQ11_OPEN_UNRUPTURED" "," "OPIQ11_ENDO_RUPTURED" "," "OPIQ11_ENDO_UNRUPTURED" ","
 "OPIQ12"  ","  "OPIQ15"  "," "OPIQ16"  ","
 "OPIQ17"  ","  "OPIQ17_HEMSTROKE_SUBARACH" "," "OPIQ17_HEMSTROKE_INTRACER" "," "OPIQ17_ISCHEMSTROKE" "," "OPIQ18"  ","
 "OPIQ19"  ","  "OPIQ20"  "," "OPIQ30"  "," "OPIQ31"  "," 
 "EPIQ08"  ","  "EPIQ09"  "," "EPIQ11"  "," "EPIQ12"  ","  "EPIQ15"  "," "EPIQ16"  "," "EPIQ17"  ","  "EPIQ18"  "," "EPIQ19"  ","  "EPIQ20"  "," "EPIQ30"  "," "EPIQ31"  "," 
 "RPIQ08"  ","  "RPIQ09"  "," "RPIQ11"  "," "RPIQ12"  ","  "RPIQ15"  "," "RPIQ16"  "," "RPIQ17"  ","  "RPIQ18"  "," "RPIQ19"  ","  "RPIQ20"  "," "RPIQ30"  "," "RPIQ31"  "," 
 "LPIQ08"  ","  "LPIQ09"  "," "LPIQ11"  "," "LPIQ12"  ","  "LPIQ15"  "," "LPIQ16"  "," "LPIQ17"  ","  "LPIQ18"  "," "LPIQ19"  ","  "LPIQ20"  "," "LPIQ30"  "," "LPIQ31"  "," 
 "UPIQ08"  ","  "UPIQ09"  "," "UPIQ11"  "," "UPIQ12"  ","  "UPIQ15"  "," "UPIQ16"  "," "UPIQ17"  ","  "UPIQ18"  "," "UPIQ19"  ","  "UPIQ20"  "," "UPIQ30"  "," "UPIQ31"  "," 
 "SPIQ08"  ","  "SPIQ09"  "," "SPIQ11"  "," "SPIQ12"  ","  "SPIQ15"  "," "SPIQ16"  "," "SPIQ17"  ","  "SPIQ18"  "," "SPIQ19"  ","  "SPIQ20"  "," "SPIQ30"  "," "SPIQ31"  "," 
 "SNPIQ08"  ","  "SNPIQ09"  "," "SNPIQ11"  "," "SNIQ12"  ","  "SNPIQ15"  "," "SNPIQ16"  "," "SNPIQ17"  ","  "SNPIQ18"  "," "SNPIQ19"  ","  "SNPIQ20"  "," "SNPIQ30"  "," "SNPIQ31"  "," 
 "XPIQ08"  ","  "XPIQ09"  "," "XPIQ11"  "," "XPIQ12"  ","  "XPIQ15"  "," "XPIQ16"  "," "XPIQ17"  ","  "XPIQ18"  "," "XPIQ19"  ","  "XPIQ20"  "," "XPIQ30"  "," "XPIQ31"  "," 
 ;
 end;
 put HOSPID 13. "," AGECAT 3.  "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPIQ08-TPIQ09 TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER TPIQ11 TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED
  TPIQ12 TPIQ15-TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE TPIQ18-TPIQ20  TPIQ30-TPIQ31) (7.0 ",") ","
 (PPIQ08-PPIQ09 PPIQ09_WITH_CANCER PPIQ09_WITHOUT_CANCER PPIQ11  PPIQ11_OPEN_RUPTURED PPIQ11_OPEN_UNRUPTURED PPIQ11_ENDO_RUPTURED PPIQ11_ENDO_UNRUPTURED
  PPIQ12 PPIQ15-PPIQ17 PPIQ17_HEMSTROKE_SUBARACH PPIQ17_HEMSTROKE_INTRACER PPIQ17_ISCHEMSTROKE PPIQ18-PPIQ20   PPIQ30-PPIQ31) (13.0 ",") ","
 (OPIQ08-OPIQ09 OPIQ09_WITH_CANCER OPIQ09_WITHOUT_CANCER OPIQ11  OPIQ11_OPEN_RUPTURED OPIQ11_OPEN_UNRUPTURED OPIQ11_ENDO_RUPTURED OPIQ11_ENDO_UNRUPTURED
  OPIQ12 OPIQ15-OPIQ17 OPIQ17_HEMSTROKE_SUBARACH OPIQ17_HEMSTROKE_INTRACER OPIQ17_ISCHEMSTROKE OPIQ18-OPIQ20   OPIQ30-OPIQ31) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");  ","
 (EPIQ08-EPIQ09 EPIQ11 EPIQ12 EPIQ15-EPIQ17 EPIQ18-EPIQ20 EPIQ30-EPIQ31) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");  ","
 (RPIQ08-RPIQ09 RPIQ11 RPIQ12 RPIQ15-RPIQ17 RPIQ18-RPIQ20 RPIQ30-RPIQ31) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");  ","
 (LPIQ08-LPIQ09 LPIQ11 LPIQ12 LPIQ15-LPIQ17 LPIQ18-LPIQ20 LPIQ30-LPIQ31) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");  ","
 (UPIQ08-UPIQ09 UPIQ11 UPIQ12 UPIQ15-UPIQ17 UPIQ18-UPIQ20 UPIQ30-UPIQ31) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");  ","
 (SPIQ08-SPIQ09 SPIQ11 SPIQ12 SPIQ15-SPIQ17 SPIQ18-SPIQ20 SPIQ30-SPIQ31) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");  ","
 (SNPIQ08-SNPIQ09 SNPIQ11 SNPIQ12 SNPIQ15-SNPIQ17 SNPIQ18-SNPIQ20 SNPIQ30-SNPIQ31) (12.10 ",")  ","
 (XPIQ08-XPIQ09 XPIQ11 XPIQ12 XPIQ15-XPIQ17 XPIQ18-XPIQ20 XPIQ30-XPIQ31) (12.10 ",")
 ;

run;

%END;

%MEND TEXT;

%TEXT;

