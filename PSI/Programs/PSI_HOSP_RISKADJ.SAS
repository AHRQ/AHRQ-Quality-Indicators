*========================== Program: PSI_HOSP_RISKADJ.SAS ==========================;
*
*  TITLE: HOSPITAL LEVEL RISK-ADJUSTED RATES FOR AHRQ PATIENT SAFETY INDICATORS
*
*  DESCRIPTION:
*        Calculates risk-adjusted and smoothed rates for Patient Safety
*        Indicators, adjusting for: SEX, AGE, DRG, MDC AND COMORBIDITY.
*        Variables created by the program: EPPSxx, RPPSxx,LPPSxx, UPPSxx, 
*        SPPSxx, XPPSxx, VPPSxx, SNPPSxx
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
*===================================================================================;
 title2 'PROGRAM PSI_HOSP_RISKADJ';
 title3 'AHRQ PATIENT SAFETY INDICATORS: CALCULATE RISK-ADJUSTED HOSPITAL RATES';
 
* ------------------------------------------------------------------- ;
* --- PATIENT SAFETY INDICATOR (PSI) NAMING CONVENTION:              --- ;
* --- THE FIRST LETTER IDENTIFIES THE PATIENT SAFETY                 --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                             --- ;
* ---       (T) NUMERATOR ("TOP") - FROM PSI_HOSP_MEASURES           --- ;
* ---       (P) DENOMINATOR ("POP") - FROM PSI_HOSP_MEASURES         --- ;
* ---       (O) OBSERVED RATES (T/P)                                 --- ;
* ---       (E) EXPECTED RATE                                        --- ;
* ---       (V) VARIANCE                                             --- ;
* ---       (R) RISK-ADJUSTED RATE                                   --- ;
* ---       (L) LOWER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE        --- ;
* ---       (U) UPPER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE        --- ;
* ---       (S) SMOOTHED RATE (NOT REPORTED FOR STRATA)              --- ;
* ---       (X) SMOOTHED RATE STANDARD ERROR (NOT REPORTED FOR STRATA) - ;
* ---       (SN)RELIABILITY                                          --- ;
* --- THE SECOND LETTER IDENTIFIES THE PSI AS A HOSPITAL (P)         --- ;
* --- LEVEL INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS 'PS'.     --- ;
* --- THE LAST TWO DIGITS ARE THE INDICATOR NUMBER                   --- ;
* ---------------------------------------------------------------------- ;

*----------------------------------------------------------------------- ;
*--- THE PSI_HOSP_REGVARS_v2024.SAS PROGRAM CREATES VARIABLES        --- ;
*--- USED FOR RISK ADJUSTMENT. THE USER MUST ENSURE THAT THE         --- ;
*--- PSI_HOSP_CONTROL PROGRAM INCLUDES THE CORRECT LOCATION FOR      --- ;
*--- THE PSI_HOSP_REGVARS_v2024 SAS CODE.                            --- ;
*----------------------------------------------------------------------- ;

data &OUTFILE_MEAS.;
     set OUTMSR.&OUTFILE_MEAS.;
     %include MacLib(PSI_HOSP_Regvars_v2024.sas);
run ;

%MACRO MOD3(PS);

* --- CREATE AN INDICATOR-LEVEL FLAG FOR WHETHER RISK-ADJUSTED AND SMOOTHED RATES ARE SUPPRESSED DUE TO NO PRDAY --- ;
%let PS_PRDAY = 04 09 10 11 12 14 15;
%let PRDAY_RA = 0;
%if &PRDAY. = 0 %then %do;
  %do i=1 %to %sysfunc(countw(&PS_PRDAY., " "));
    %if %scan(&PS_PRDAY.,&i.," ") = %substr(&PS.,1,2) %then %let PRDAY_RA = 1;
  %end;
%end;

* --- DO NOT CALCULATE RISK-ADJUSTED AND SMOOTHED RATES IF CERTAIN FLAGS ARE SET IN THE CONTROL PROGRAM --- ;
%if &MDC_PROVIDED. = 0 or &PRDAY_RA. = 1 %then %let SUPPRESS_RA = 1;
  %else %let SUPPRESS_RA = 0;

*** Start discharge scoring for all but the overall stratified measure, PSI04 ;
%if &ps. ^= 04 %then %do; 

 * --- PARAMETER FILE USED FOR SCORING --- ;
 filename RACOEFFS  "&RADIR./Gee_PS&PS._AGE_SEX.csv";


 * --- LOAD CSV PARAMTERS & SHAPE DATA --- ;
 data TEMP1_MODEL ;
   length VARIABLE $30 DF ESTIMATE 8 ;
   infile RACOEFFS DSD DLM=',' LRECL=1024 FIRSTOBS=2;
   input VARIABLE DF ESTIMATE ;
 run ;
 data TEMP1_MODEL ;
    set TEMP1_MODEL ;
    variable=tranwrd(variable,"*","_");
 run;

 proc TRANSPOSE data=TEMP1_MODEL out=TEMP2_MODEL;
 	id variable;
   	var ESTIMATE;
 run ;

 data MODEL_PS&PS.;
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
 proc Score data=&OUTFILE_MEAS. (where=(TPPS&PS. in (0,1))) score=MODEL_PS&PS. type=PARMS out=TEMP1Y&ps.;
   var &VARS_. ;
 run;

 * --- CALCULATE PREDICTED VALUES (EHAT) --- ;
 data TEMP1Y&ps.;
   set TEMP1Y&ps.;
   EHAT = EXP(MHAT)/(1 + EXP(MHAT));
 RUN;

 %END; *** End discharge scoring for all but the overall stratified measure, PSI04 ;

%LET DSID=%SYSFUNC(OPEN(TEMP1Y&ps.));
%IF &dsid. %THEN %LET DNUM=%SYSFUNC(ATTRN(&dsid,NOBS));
%ELSE %LET DNUM=0;
%LET DRC=%SYSFUNC(CLOSE(&dsid));

 %IF &DNUM NE 0 %THEN %DO;

* --- EHAT IS CAPPED AT THE VALUE 0.99                                 --- ;
* --- IF THE FLAG, CALIBRATION_OE_TO_REF_POP = 1, SET EHAT TO EHAT*O_E --- ;
* --- AND USE THE MODIFIED VALUE OF EHAT GOING FORWARD.                --- ;

%if &ps.^=04 and &Calibration_OE_to_ref_pop. = 1 %then %do;
 DATA TEMP1Y&ps.;  
    SET TEMP1Y&ps.;    
    %include MacLib(PSI_HOSP_OE_Array_v2024.sas);
    
    * --- MAP MEASURE NUM TO ARRAY INDEX SUB_N --- ;
    if "&PS." = "02"              then SUB_N = 1;
    if "&PS." = "03"              then SUB_N = 2;
    if "&PS." = "04_DVT_PE"       then SUB_N = 3;
    if "&PS." = "04_PNEUMONIA"    then SUB_N = 4;
    if "&PS." = "04_SEPSIS"       then SUB_N = 5;
    if "&PS." = "04_SHOCK"        then SUB_N = 6;
    if "&PS." = "04_GIHEMORRHAGE" then SUB_N = 7;
    if "&PS." = "06"              then SUB_N = 8;
    if "&PS." = "07"              then SUB_N = 9;
    if "&PS." = "08"              then SUB_N = 10;
    if "&PS." = "09"              then SUB_N = 11;
    if "&PS." = "10"              then SUB_N = 12;
    if "&PS." = "11"              then SUB_N = 13;
    if "&PS." = "12"              then SUB_N = 14;
    if "&PS." = "13"              then SUB_N = 15;
    if "&PS." = "14"              then SUB_N = 16;
    if "&PS." = "15"              then SUB_N = 17;

    EHAT=EHAT*ARRYOE(SUB_N);
    if EHAT > 0.99 then EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT);    
 RUN;
%end;
/* --- if flag set to 0, adjust EHAT using overall O/E ratio for current data --- */
%else %if &ps.^=04 and &Calibration_OE_to_ref_pop. = 0 %then %do; 
 PROC MEANS DATA=TEMP1Y&ps. noprint;
    VAR TPPS&PS. EHAT;
    OUTPUT OUT=OE&PS.(DROP=_TYPE_ _FREQ_) SUM(TPPS&PS. EHAT)=TPPS&PS. EHAT;
 RUN;
 
 DATA OE&PS.;
    SET OE&PS.;
    O_E&PS.=TPPS&PS./EHAT;
 RUN;
 
 PROC PRINT DATA=OE&PS.;
 RUN;
 
 DATA OE&PS.;
    SET OE&PS.(KEEP=O_E&PS.);
 RUN;
 
 DATA TEMP1Y&ps.;  
    IF _N_=1 THEN SET OE&PS.;
    SET TEMP1Y&ps.;
    EHAT=EHAT*O_E&PS.;
    if EHAT > 0.99 then EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT);    
 RUN;
%end;

 * --- SUMMARIZE BY VARIOUS CLASSES --- ;
 proc Summary data=TEMP1Y&ps.;
    class HOSPID AGECAT SEXCAT PAYCAT RACECAT;
    var   TPPS&PS. PPPS&PS. EHAT PHAT;
    output out=RPPS&PS. sum(TPPS&PS. PPPS&PS. EHAT PHAT)=TPPS&PS. PPPS&PS. EHAT PHAT
           n=DENOM;
 run;

 * --- APPLY RISK ADJUSTMENT & SMOOTHING --- ;
 data RPPS&PS.(KEEP=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT
                    EPPS&PS. RPPS&PS. LPPS&PS. UPPS&PS. SPPS&PS. XPPS&PS. VPPS&PS.
                    TPPS&PS. PPPS&PS. OPPS&PS. SNPPS&PS. );
   set RPPS&PS.;

   if _TYPE_ &TYPELVLH;

 * --- LOAD SIGNAL AND NOISE ARRAYS FROM TEXT FILE --- ;
 %include MacLib(PSI_HOSP_Sigvar_Array_v2024.sas);

 * --- MAP MEASURE NUM TO ARRAY INDEX SUB_N --- ;
 if "&PS." = "02"              then SUB_N = 1;
 if "&PS." = "03"              then SUB_N = 2;
 if "&PS." = "04"              then SUB_N = 3;
 if "&PS." = "04_DVT_PE"       then SUB_N = 4;
 if "&PS." = "04_PNEUMONIA"    then SUB_N = 5;
 if "&PS." = "04_SEPSIS"       then SUB_N = 6;
 if "&PS." = "04_SHOCK"        then SUB_N = 7;
 if "&PS." = "04_GIHEMORRHAGE" then SUB_N = 8;
 if "&PS." = "06"              then SUB_N = 9;
 if "&PS." = "07"              then SUB_N = 10;
 if "&PS." = "08"              then SUB_N = 11;
 if "&PS." = "09"              then SUB_N = 12;
 if "&PS." = "10"              then SUB_N = 13;
 if "&PS." = "11"              then SUB_N = 14;
 if "&PS." = "12"              then SUB_N = 15;
 if "&PS." = "13"              then SUB_N = 16;
 if "&PS." = "14"              then SUB_N = 17;
 if "&PS." = "15"              then SUB_N = 18;

 * --- T = NUMERATOR     --- ;
 * --- P = DENOMINATOR   --- ;
 * --- E = EXPECTED      --- ;
 * --- R = RISK ADJUSTED --- ;
 * --- L = LOWER CI      --- ;
 * --- U = UPPER CI      --- ;
 * --- S = SMOOTHED      --- ;
 * --- X = SMOOTHED SE   --- ;
 * --- V = VARIANCE      --- ;
 * --- SN = RELIABILITY  --- ;

 EPPS&PS. = EHAT / PPPS&PS.;
 THAT = TPPS&PS. / PPPS&PS.;
 OPPS&PS. = TPPS&PS. / PPPS&PS.;

 if _TYPE_ in (0,16) and &SUPPRESS_RA. = 0 then do;
    RPPS&PS.  = (THAT / EPPS&PS.) * ARRYP3(SUB_N);
    SE&PS.    = (ARRYP3(SUB_N) / EPPS&PS.) * (1 / PPPS&PS.) * sqrt(PHAT);
    VPPS&PS.  = SE&PS.**2;
    SNPPS&PS. = ARRYP2(SUB_N) / (ARRYP2(SUB_N) + VPPS&PS.);
    SPPS&PS.  = (RPPS&PS. * SNPPS&PS.) + ((1 -  SNPPS&PS.) * ARRYP3(SUB_N));
    XPPS&PS.  = sqrt(ARRYP2(SUB_N)- (SNPPS&PS. * ARRYP2(SUB_N)));
 end;
 else if _TYPE_ in (1,2,3,17,18,19) and &SUPPRESS_RA. = 0 then do;
    RPPS&PS.  = (THAT / EPPS&PS.);
    SE&PS.    = (1 / EPPS&PS.) * (1 / PPPS&PS.) * sqrt(PHAT);
    VPPS&PS.  = SE&PS.**2;
    SNPPS&PS. = .;
    SPPS&PS.  = .;
    XPPS&PS.  = .;
 end;
 else do;
    EPPS&PS.  = .;
    RPPS&PS.  = .;
    SE&PS.    = .;
    VPPS&PS.  = .;
    SNPPS&PS. = .;
    SPPS&PS.  = .;
    XPPS&PS.  = .;
    LPPS&PS.  = .; 
    UPPS&PS.  = .;
 end;

 if not missing(RPPS&PS.) then do;
   LPPS&PS. = RPPS&PS. - (1.96 * SE&PS.);
   if LPPS&PS. < 0 then LPPS&PS. = 0;
   UPPS&PS. = RPPS&PS. + (1.96 * SE&PS.);

   if _TYPE_ in (0,16) then do;
     if LPPS&PS. > 1 then LPPS&PS. = 1; 
     if UPPS&PS. > 1 then UPPS&PS. = 1;
     if RPPS&PS. > 1 then RPPS&PS. = 1;
     if SPPS&PS. > 1 then SPPS&PS. = 1;
   end;
 end;

 run;

 %END;

 %ELSE %DO;

 data RPPS&PS.;
   length HOSPID &HOSPID_TYP.. AGECAT SEXCAT PAYCAT RACECAT 3;
          call missing(HOSPID); _TYPE_=0; AGECAT=.; SEXCAT=.; PAYCAT=.; RACECAT=.;
          EPPS&PS=.; RPPS&PS=.; SE&PS.=.; VPPS&PS=.; SNPPS&PS.=.; SPPS&PS=.; XPPS&PS=.; LPPS&PS=.; UPPS&PS=.;
          TPPS&PS=.; PPPS&PS=.; OPPS&PS=.;
    output;
 run;

 %END;

 proc Sort data=RPPS&PS.;
   by _TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 run; quit;

 proc Datasets NOLIST;
   delete TEMP1 TEMP1Y TEMP1_MODEL TEMP2_MODEL;
 run;


%MEND MOD3;

%MOD3(02) ;
%MOD3(03) ;
%MOD3(04_DVT_PE) ;
%MOD3(04_PNEUMONIA) ;
%MOD3(04_SEPSIS) ;
%MOD3(04_SHOCK) ;
%MOD3(04_GIHEMORRHAGE) ;

* --- CONCATENATE SCORED DISCHARGES FOR MEASURE PSI 04 --- ;
* --- THIS APPLIES RISK - ADJUSTMENT FROM INDIVIDUAL   --- ;
* --- STRATA TO THE OVERALL MEASURE                    --- ;

data TEMP1Y04;
set TEMP1Y04_DVT_PE
    TEMP1Y04_PNEUMONIA
    TEMP1Y04_SEPSIS
    TEMP1Y04_SHOCK
    TEMP1Y04_GIHEMORRHAGE;
run;

%MOD3(04);
%MOD3(06);
%MOD3(07);
%MOD3(08);
%MOD3(09);
%MOD3(10);
%MOD3(11);
%MOD3(12);
%MOD3(13);
%MOD3(14) ;
%MOD3(15);


 * ------------------------------------------------------------------ ;
 * --- MERGE THE HOSPITAL ADJUSTED RATES FOR EACH INDICATOR (PS.) --- ;
 * ------------------------------------------------------------------ ;

proc sort data=OUTHOBS.&OUTFILE_HOSPOBS. out=&OUTFILE_HOSPOBS.;
   by _TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT;
run;
data OUTHRISK.&OUTFILE_HOSPRISK. (drop=SPPS04_DVT_PE SPPS04_PNEUMONIA SPPS04_SEPSIS SPPS04_SHOCK SPPS04_GIHEMORRHAGE 
                                       XPPS04_DVT_PE XPPS04_PNEUMONIA XPPS04_SEPSIS XPPS04_SHOCK XPPS04_GIHEMORRHAGE);* drop all stratified smoothed and smoothed error variables;
 merge RPPS02
       RPPS03
       RPPS04
       RPPS04_DVT_PE
       RPPS04_PNEUMONIA
       RPPS04_SEPSIS
       RPPS04_SHOCK
       RPPS04_GIHEMORRHAGE
       RPPS06
       RPPS07
       RPPS08
       RPPS09
       RPPS10
       RPPS11
       RPPS12
       RPPS13
       RPPS14
       &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPPS14_OPEN    PPPS14_OPEN    OPPS14_OPEN    where=(PPPS14_OPEN >0))
       &OUTFILE_HOSPOBS.(keep=_TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT TPPS14_NONOPEN PPPS14_NONOPEN OPPS14_NONOPEN where=(PPPS14_NONOPEN >0))
       RPPS15;
 by _TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT;

 %macro label_qis(flag=, qi_num=, qi_name=);
   label
   PP&qi_num. = "&qi_name. (Population)"
   OP&qi_num. = "&qi_name. (Observed rate)"

   %IF &flag. = 0 OR &flag. = 1  %THEN %DO;
   EP&qi_num. = "&qi_name. (Expected rate)"
   RP&qi_num. = "&qi_name. (Risk-adjusted rate)"
   LP&qi_num. = "&qi_name. (Lower CL of risk-adjusted rate)"
   UP&qi_num. = "&qi_name. (Upper CL of risk-adjusted rate)"
   VP&qi_num. = "&qi_name. (Variance of the risk-adjusted rate)"
   SNP&qi_num. = "&qi_name. (Reliability of the risk-adjusted rate)"
   %END;
   ;

   %IF &flag. = 1 %THEN %DO;
    label
    SP&qi_num. = "&qi_name. (Smoothed rate)"
    XP&qi_num. = "&qi_name. (Standard error of the smoothed rate)"
    ;
   %END;

 %mend label_qis;
 
 %label_qis(flag=1, qi_num=PS02,              qi_name=PSI 02 Death Rate in Low-Mortality Diagnosis Related Groups (DRGs));
 %label_qis(flag=1, qi_num=PS03,              qi_name=PSI 03 Pressure Ulcer Rate);
 %label_qis(flag=1, qi_num=PS04,              qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications);
 %label_qis(flag=0, qi_num=PS04_DVT_PE,       qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Deep Vein Thrombosis/Pulmonary Embolism (DVT/PE));
 %label_qis(flag=0, qi_num=PS04_PNEUMONIA,    qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Pneumonia);
 %label_qis(flag=0, qi_num=PS04_SEPSIS,       qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Sepsis);
 %label_qis(flag=0, qi_num=PS04_SHOCK,        qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Shock/Cardiac Arrest);
 %label_qis(flag=0, qi_num=PS04_GIHEMORRHAGE, qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Gastrointestinal (GI) Hemorrhage/Acute Ulcer);
 %label_qis(flag=1, qi_num=PS06,              qi_name=PSI 06 Iatrogenic Pneumothorax Rate);
 %label_qis(flag=1, qi_num=PS07,              qi_name=PSI 07 Central Venous Catheter-Related Blood Stream Infection Rate);
 %label_qis(flag=1, qi_num=PS08,              qi_name=PSI 08 In-Hospital Fall-Associated Fracture Rate);
 %label_qis(flag=1, qi_num=PS09,              qi_name=PSI 09 Postoperative Hemorrhage or Hematoma Rate);
 %label_qis(flag=1, qi_num=PS10,              qi_name=PSI 10 Postoperative Acute Kidney Injury Requiring Dialysis Rate);
 %label_qis(flag=1, qi_num=PS11,              qi_name=PSI 11 Postoperative Respiratory Failure Rate);
 %label_qis(flag=1, qi_num=PS12,              qi_name=PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate);
 %label_qis(flag=1, qi_num=PS13,              qi_name=PSI 13 Postoperative Sepsis Rate);
 %label_qis(flag=1, qi_num=PS14,              qi_name=PSI 14 Postoperative Wound Dehiscence Rate);
 %label_qis(flag=2, qi_num=PS14_OPEN,         qi_name=PSI 14 Postoperative Wound Dehiscence Rate Stratum: Open Approach);
 %label_qis(flag=2, qi_num=PS14_NONOPEN,      qi_name=PSI 14 Postoperative Wound Dehiscence Rate Stratum: Non-Open Approach);
 %label_qis(flag=1, qi_num=PS15,              qi_name=PSI 15 Abdominopelvic Accidental Puncture or Laceration Rate);

 array ARRY1{18} EPPS02  EPPS03  EPPS04  EPPS04_DVT_PE  EPPS04_PNEUMONIA  EPPS04_SEPSIS  EPPS04_SHOCK  EPPS04_GIHEMORRHAGE  EPPS06  EPPS07  EPPS08-EPPS14 EPPS15;
 array ARRY2{18} RPPS02  RPPS03  RPPS04  RPPS04_DVT_PE  RPPS04_PNEUMONIA  RPPS04_SEPSIS  RPPS04_SHOCK  RPPS04_GIHEMORRHAGE  RPPS06  RPPS07  RPPS08-RPPS14 RPPS15;
 array ARRY3{18} LPPS02  LPPS03  LPPS04  LPPS04_DVT_PE  LPPS04_PNEUMONIA  LPPS04_SEPSIS  LPPS04_SHOCK  LPPS04_GIHEMORRHAGE  LPPS06  LPPS07  LPPS08-LPPS14 LPPS15;
 array ARRY4{18} UPPS02  UPPS03  UPPS04  UPPS04_DVT_PE  UPPS04_PNEUMONIA  UPPS04_SEPSIS  UPPS04_SHOCK  UPPS04_GIHEMORRHAGE  UPPS06  UPPS07  UPPS08-UPPS14 UPPS15;
 array ARRY5{18} SPPS02  SPPS03  SPPS04  SPPS04_DVT_PE  SPPS04_PNEUMONIA  SPPS04_SEPSIS  SPPS04_SHOCK  SPPS04_GIHEMORRHAGE  SPPS06  SPPS07  SPPS08-SPPS14 SPPS15;
 array ARRY6{18} XPPS02  XPPS03  XPPS04  XPPS04_DVT_PE  XPPS04_PNEUMONIA  XPPS04_SEPSIS  XPPS04_SHOCK  XPPS04_GIHEMORRHAGE  XPPS06  XPPS07  XPPS08-XPPS14 XPPS15;
 array ARRY7{18} VPPS02  VPPS03  VPPS04  VPPS04_DVT_PE  VPPS04_PNEUMONIA  VPPS04_SEPSIS  VPPS04_SHOCK  VPPS04_GIHEMORRHAGE  VPPS06  VPPS07  VPPS08-VPPS14 VPPS15;
 array ARRY8{18} PPPS02  PPPS03  PPPS04  PPPS04_DVT_PE  PPPS04_PNEUMONIA  PPPS04_SEPSIS  PPPS04_SHOCK  PPPS04_GIHEMORRHAGE  PPPS06  PPPS07  PPPS08-PPPS14 PPPS15;
 array ARRY9{18} SNPPS02 SNPPS03 SNPPS04 SNPPS04_DVT_PE SNPPS04_PNEUMONIA SNPPS04_SEPSIS SNPPS04_SHOCK SNPPS04_GIHEMORRHAGE SNPPS06 SNPPS07 SNPPS08-SNPPS14 SNPPS15;

 do I = 1 TO 18;
    if ARRY8(I) <= 2 then do;
       ARRY1(I) = .;
       ARRY2(I) = .;
       ARRY3(I) = .;
       ARRY4(I) = .;
       ARRY5(I) = .;
       ARRY6(I) = .;
       ARRY7(I) = .;
       ARRY9(I) = .;
    end;
 end;

 drop I;

 format EPPS02  EPPS03  EPPS04  EPPS04_DVT_PE  EPPS04_PNEUMONIA  EPPS04_SEPSIS  EPPS04_SHOCK  EPPS04_GIHEMORRHAGE  EPPS06  EPPS07  EPPS08-EPPS14 EPPS15
        LPPS02  LPPS03  LPPS04  LPPS04_DVT_PE  LPPS04_PNEUMONIA  LPPS04_SEPSIS  LPPS04_SHOCK  LPPS04_GIHEMORRHAGE  LPPS06  LPPS07  LPPS08-LPPS14 LPPS15
        OPPS02  OPPS03  OPPS04  OPPS04_DVT_PE  OPPS04_PNEUMONIA  OPPS04_SEPSIS  OPPS04_SHOCK  OPPS04_GIHEMORRHAGE  OPPS06  OPPS07  OPPS08-OPPS14 OPPS14_OPEN OPPS14_NONOPEN OPPS15
        RPPS02  RPPS03  RPPS04  RPPS04_DVT_PE  RPPS04_PNEUMONIA  RPPS04_SEPSIS  RPPS04_SHOCK  RPPS04_GIHEMORRHAGE  RPPS06  RPPS07  RPPS08-RPPS14 RPPS15
        SPPS02  SPPS03  SPPS04  SPPS04_DVT_PE  SPPS04_PNEUMONIA  SPPS04_SEPSIS  SPPS04_SHOCK  SPPS04_GIHEMORRHAGE  SPPS06  SPPS07  SPPS08-SPPS14 SPPS15
        UPPS02  UPPS03  UPPS04  UPPS04_DVT_PE  UPPS04_PNEUMONIA  UPPS04_SEPSIS  UPPS04_SHOCK  UPPS04_GIHEMORRHAGE  UPPS06  UPPS07  UPPS08-UPPS14 UPPS15
        VPPS02  VPPS03  VPPS04  VPPS04_DVT_PE  VPPS04_PNEUMONIA  VPPS04_SEPSIS  VPPS04_SHOCK  VPPS04_GIHEMORRHAGE  VPPS06  VPPS07  VPPS08-VPPS14 VPPS15
        XPPS02  XPPS03  XPPS04  XPPS04_DVT_PE  XPPS04_PNEUMONIA  XPPS04_SEPSIS  XPPS04_SHOCK  XPPS04_GIHEMORRHAGE  XPPS06  XPPS07  XPPS08-XPPS14 XPPS15
		SNPPS02 SNPPS03 SNPPS04 SNPPS04_DVT_PE SNPPS04_PNEUMONIA SNPPS04_SEPSIS SNPPS04_SHOCK SNPPS04_GIHEMORRHAGE SNPPS06 SNPPS07 SNPPS08-SNPPS14 SNPPS15 13.7

		TPPS02  TPPS03  TPPS04  TPPS04_DVT_PE  TPPS04_PNEUMONIA  TPPS04_SEPSIS  TPPS04_SHOCK  TPPS04_GIHEMORRHAGE  TPPS06  TPPS07  TPPS08-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15
		PPPS02  PPPS03  PPPS04  PPPS04_DVT_PE  PPPS04_PNEUMONIA  PPPS04_SEPSIS  PPPS04_SHOCK  PPPS04_GIHEMORRHAGE  PPPS06  PPPS07  PPPS08-PPPS14 PPPS14_OPEN PPPS14_NONOPEN PPPS15  13.0;
 run;

* -------------------------------------------------------------- ;
* --- CONTENTS AND MEANS OF HOSPITAL-LEVEL MERGED FILE --------- ;
* -------------------------------------------------------------- ;

proc Contents data=OUTHRISK.&OUTFILE_HOSPRISK. position;
run; quit;


** --- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS --**;
proc Means data=OUTHRISK.&OUTFILE_HOSPRISK. (WHERE=(_TYPE_ IN (16))) n nmiss min max mean nolabels;
   var TPPS02 TPPS03  TPPS04  TPPS04_DVT_PE  TPPS04_PNEUMONIA  TPPS04_SEPSIS  TPPS04_SHOCK  TPPS04_GIHEMORRHAGE  TPPS06  TPPS07 TPPS08-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15;
   title  'SUMMARY OF PATIENT SAFETY QUALITY HOSPITAL-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=16';
run; quit;

proc Means data=OUTHRISK.&OUTFILE_HOSPRISK. (WHERE=(_TYPE_ IN (16))) n nmiss min max mean nolabels;
   var PPPS02 PPPS03  PPPS04  PPPS04_DVT_PE  PPPS04_PNEUMONIA  PPPS04_SEPSIS  PPPS04_SHOCK  PPPS04_GIHEMORRHAGE  PPPS06  PPPS07 PPPS08-PPPS14 PPPS14_OPEN PPPS14_NONOPEN PPPS15;
   title  'SUMMARY OF PATIENT SAFETY HOSPITAL-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=16';
run; quit;

proc Means data=OUTHRISK.&OUTFILE_HOSPRISK. (WHERE=(_TYPE_ IN (16))) n nmiss min max mean nolabels;
   var OPPS02  OPPS03  OPPS04  OPPS04_DVT_PE  OPPS04_PNEUMONIA  OPPS04_SEPSIS  OPPS04_SHOCK  OPPS04_GIHEMORRHAGE  OPPS06  OPPS07  OPPS08-OPPS14 OPPS14_OPEN OPPS14_NONOPEN OPPS15
       EPPS02  EPPS03  EPPS04  EPPS04_DVT_PE  EPPS04_PNEUMONIA  EPPS04_SEPSIS  EPPS04_SHOCK  EPPS04_GIHEMORRHAGE  EPPS06  EPPS07  EPPS08-EPPS14 EPPS15
       RPPS02  RPPS03  RPPS04  RPPS04_DVT_PE  RPPS04_PNEUMONIA  RPPS04_SEPSIS  RPPS04_SHOCK  RPPS04_GIHEMORRHAGE  RPPS06  RPPS07  RPPS08-RPPS14 RPPS15
       SPPS02  SPPS03  SPPS04  SPPS06  SPPS07 SPPS08-SPPS15;
   title  'SUMMARY OF PATIENT SAFETY HOSPITAL-LEVEL INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=16';
run; quit;


* -------------------------------------------------------------- ;
* --- PRINT HOSPITAL MERGED FILE ------------------------------- ;
* -------------------------------------------------------------- ;

%MACRO PRT2;

%IF &PRINT. = 1 %THEN %DO;

%MACRO PRT(FLAG,PS,TEXT,VOLUME,STRATA);

proc PRINT data=OUTHRISK.&OUTFILE_HOSPRISK. label SPLIT='*';
%IF   &VOLUME = 0 AND &STRATA=0 %THEN %DO;
var HOSPID TPPS&PS. PPPS&PS. OPPS&PS. %IF &FLAG.=1 %THEN %DO; EPPS&PS. RPPS&PS. LPPS&PS. UPPS&PS. SPPS&PS. XPPS&PS. %END;;
label HOSPID  = "Hospital Identification Number"
      TPPS&PS. = "TPPS&PS.*(Numerator)"
      PPPS&PS. = "PPPS&PS.*(Population)"
      OPPS&PS. = "OPPS&PS.*(Observed rate)"
      %IF &FLAG.=1 %THEN %DO; 
      EPPS&PS. = "EPPS&PS.*(Expected rate)"
      RPPS&PS. = "RPPS&PS.*(Risk-adjusted rate)"
      LPPS&PS. = "LPPS&PS.*(Lower CL of risk-adjusted rate)"
      UPPS&PS. = "UPPS&PS.*(Upper CL OF risk-adjusted rate)"
      SPPS&PS. = "SPPS&PS.*(Smoothed rate)"
      XPPS&PS. = "XPPS&PS.*(Standard error of the smoothed rate)"
      %END;
      ;
format TPPS&PS. PPPS&PS. 13.0 OPPS&PS. 
       %IF &FLAG.=1 %THEN %DO; RPPS&PS. EPPS&PS. SPPS&PS. XPPS&PS. %END; 8.6
	  ;
%END;
%ELSE %IF &VOLUME. = 1 %THEN %DO;
var HOSPID TPPS&PS. ;
label HOSPID  = "HOSPID"
      TPPS&PS. = "TPPS&PS.*(NUMERATOR)"
      ;
format TPPS&PS. 13.0 ;
%END;
%ELSE %IF &STRATA. = 1 %THEN %DO;
var HOSPID TPPS&PS. PPPS&PS. OPPS&PS. %IF &FLAG.=1 %THEN %DO; EPPS&PS. RPPS&PS. LPPS&PS. UPPS&PS. %END;;
label HOSPID  = "Hospital Identification Number"
      TPPS&PS. = "TPPS&PS.*(Numerator)"
      PPPS&PS. = "PPPS&PS.*(Population)"
      OPPS&PS. = "OPPS&PS.*(Observed rate)"
      %IF &FLAG.=1 %THEN %DO; 
      EPPS&PS. = "EPPS&PS.*(Expected rate)"
      RPPS&PS. = "RPPS&PS.*(Risk-adjusted rate)"
      LPPS&PS. = "LPPS&PS.*(Lower CL of risk-adjusted rate)"
      UPPS&PS. = "UPPS&PS.*(Upper CL OF risk-adjusted rate)"
      %END;
      ;
format TPPS&PS. PPPS&PS. 13.0 OPPS&PS. 
       %IF &FLAG.=1 %THEN %DO; RPPS&PS. EPPS&PS. %END; 8.6;
	   ;
%END;
title4 "FINAL OUTPUT";
title5 "INDICATOR &PS.: &TEXT";

run;

%MEND PRT;

%PRT(1,02,Death Rate in Low-Mortality Diagnosis Related Groups (DRGs),0,0);
%PRT(1,03,Pressure Ulcer Rate,0,0);
%PRT(1,04,Death Rate among Surgical Inpatients with Serious Treatable Complications,0,0);
%PRT(1,04_DVT_PE,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Deep Vein Thrombosis/Pulmonary Embolism (DVT/PE),0,1);
%PRT(1,04_PNEUMONIA,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Pneumonia,0,1);
%PRT(1,04_SEPSIS,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Sepsis,0,1);
%PRT(1,04_SHOCK,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Shock/Cardiac Arrest,0,1);
%PRT(1,04_GIHEMORRHAGE,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Gastrointestinal (GI) Hemorrhage/Acute Ulcer,0,1);
%PRT(1,06,Iatrogenic Pneumothorax Rate,0,0);
%PRT(1,07,Central Venous Catheter-Related Blood Stream Infection Rate,0,0);
%PRT(1,08,In-Hospital Fall-Associated Fracture Rate,0,0);
%PRT(1,09,Postoperative Hemorrhage or Hematoma Rate,0,0);
%PRT(1,10,Postoperative Acute Kidney Injury Requiring Dialysis Rate,0,0);
%PRT(1,11,Postoperative Respiratory Failure Rate,0,0);
%PRT(1,12,Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate,0,0);
%PRT(1,13,Postoperative Sepsis Rate,0,0);
%PRT(1,14,Postoperative Wound Dehiscence Rate,0,0);
%PRT(2,14_OPEN,Postoperative Wound Dehiscence Rate Stratum: Open Approach,0,1);
%PRT(2,14_NONOPEN,Postoperative Wound Dehiscence Rate Stratum: Non-Open Approach,0,1);
%PRT(1,15,Abdominopelvic Accidental Puncture or Laceration Rate,0,0);
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
	%let PSCSVREF = %sysfunc(pathname(PSTXTHRA));
	%let PSCSVRF2 =  %sysfunc(tranwrd(&PSCSVREF.,.TXT,_&TYPEPRN2..TXT));
 data _NULL_;
 set OUTHRISK.&OUTFILE_HOSPRISK.;
 %scale_rates;
 file  "&PSCSVRF2." lrecl=4500 ;
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
 "TPPS02" "," "TPPS03" "," "TPPS04" "," "TPPS04_DVT_PE" "," "TPPS04_PNEUMONIA" "," "TPPS04_SEPSIS" "," "TPPS04_SHOCK" "," "TPPS04_GIHEMORRHAGE" ","
 "TPPS06" "," "TPPS07" "," "TPPS08"  "," "TPPS09"  "," "TPPS10"  "," "TPPS11"  "," "TPPS12" ","
 "TPPS13" "," "TPPS14" "," "TPPS14_OPEN" "," "TPPS14_NONOPEN" "," "TPPS15"  ","
 
 "PPPS02" "," "PPPS03" "," "PPPS04" "," "PPPS04_DVT_PE" "," "PPPS04_PNEUMONIA" "," "PPPS04_SEPSIS" "," "PPPS04_SHOCK" "," "PPPS04_GIHEMORRHAGE" ","
 "PPPS06" "," "PPPS07" "," "PPPS08" "," "PPPS09"  "," "PPPS10"  "," "PPPS11"  "," "PPPS12"  ","
 "PPPS13" "," "PPPS14" "," "PPPS14_OPEN" "," "PPPS14_NONOPEN" "," "PPPS15"  ","
 
 "OPPS02" "," "OPPS03" "," "OPPS04" "," "OPPS04_DVT_PE" "," "OPPS04_PNEUMONIA" "," "OPPS04_SEPSIS" "," "OPPS04_SHOCK" "," "OPPS04_GIHEMORRHAGE" ","
 "OPPS06" "," "OPPS07" "," "OPPS08" "," "OPPS09"  "," "OPPS10"  "," "OPPS11"  "," "OPPS12"  ","
 "OPPS13" "," "OPPS14" "," "OPPS14_OPEN" "," "OPPS14_NONOPEN" "," "OPPS15"  ","
 
 "EPPS02" "," "EPPS03" "," "EPPS04" "," "EPPS04_DVT_PE" "," "EPPS04_PNEUMONIA" "," "EPPS04_SEPSIS" "," "EPPS04_SHOCK" "," "EPPS04_GIHEMORRHAGE" ","
 "EPPS06" "," "EPPS07" "," "EPPS08" "," "EPPS09"  "," "EPPS10"  "," "EPPS11"  "," "EPPS12"  ","
 "EPPS13" "," "EPPS14" "," "EPPS15"  ","
 
 "RPPS02" "," "RPPS03" "," "RPPS04" "," "RPPS04_DVT_PE" "," "RPPS04_PNEUMONIA" "," "RPPS04_SEPSIS" "," "RPPS04_SHOCK" "," "RPPS04_GIHEMORRHAGE" ","
 "RPPS06" "," "RPPS07" "," "RPPS08" "," "RPPS09"  "," "RPPS10"  "," "RPPS11"  "," "RPPS12"  ","
 "RPPS13" "," "RPPS14" "," "RPPS15"  ","
 
 "LPPS02" "," "LPPS03" "," "LPPS04" "," "LPPS04_DVT_PE" "," "LPPS04_PNEUMONIA" "," "LPPS04_SEPSIS" "," "LPPS04_SHOCK" "," "LPPS04_GIHEMORRHAGE" ","
 "LPPS06" "," "LPPS07" "," "LPPS08" "," "LPPS09"  "," "LPPS10"  "," "LPPS11"  "," "LPPS12"  ","
 "LPPS13" "," "LPPS14" "," "LPPS15"  ","
 
 "UPPS02" "," "UPPS03" "," "UPPS04" "," "UPPS04_DVT_PE" "," "UPPS04_PNEUMONIA" "," "UPPS04_SEPSIS" "," "UPPS04_SHOCK" "," "UPPS04_GIHEMORRHAGE" ","
 "UPPS06" "," "UPPS07" "," "UPPS08" "," "UPPS09"  "," "UPPS10"  "," "UPPS11"  "," "UPPS12"  ","
 "UPPS13" "," "UPPS14" "," "UPPS15"  ","
 
 "SPPS02" "," "SPPS03" "," "SPPS04" "," "SPPS06" "," "SPPS07" "," "SPPS08" "," "SPPS09" "," "SPPS10"  "," "SPPS11"  "," "SPPS12"  ","
 "SPPS13" "," "SPPS14" "," "SPPS15" ","
 
 "XPPS02" "," "XPPS03" "," "XPPS04" "," "XPPS06" "," "XPPS07" "," "XPPS08" "," "XPPS09" "," "XPPS10"  "," "XPPS11"  "," "XPPS12"  ","
 "XPPS13" "," "XPPS14" "," "XPPS15" ","
 ;
 end;
 
 put HOSPID 13. "," AGECAT 3.  "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPPS02 TPPS03 TPPS04 TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE TPPS06 TPPS07 TPPS08-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 ) (7.0  ",")  ","
 (PPPS02 PPPS03 PPPS04 PPPS04_DVT_PE PPPS04_PNEUMONIA PPPS04_SEPSIS PPPS04_SHOCK PPPS04_GIHEMORRHAGE PPPS06 PPPS07 PPPS08-PPPS14 PPPS14_OPEN PPPS14_NONOPEN PPPS15 ) (13.0 ",")  ","
 (OPPS02 OPPS03 OPPS04 OPPS04_DVT_PE OPPS04_PNEUMONIA OPPS04_SEPSIS OPPS04_SHOCK OPPS04_GIHEMORRHAGE OPPS06 OPPS07 OPPS08-OPPS14 OPPS14_OPEN OPPS14_NONOPEN OPPS15 ) 
 %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); ","
 (EPPS02 EPPS03 EPPS04 EPPS04_DVT_PE EPPS04_PNEUMONIA EPPS04_SEPSIS EPPS04_SHOCK EPPS04_GIHEMORRHAGE EPPS06 EPPS07 EPPS08-EPPS14 EPPS15 )
 %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); ","
 (RPPS02 RPPS03 RPPS04 RPPS04_DVT_PE RPPS04_PNEUMONIA RPPS04_SEPSIS RPPS04_SHOCK RPPS04_GIHEMORRHAGE RPPS06 RPPS07 RPPS08-RPPS14 RPPS15 )
 %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); ","
 (LPPS02 LPPS03 LPPS04 LPPS04_DVT_PE LPPS04_PNEUMONIA LPPS04_SEPSIS LPPS04_SHOCK LPPS04_GIHEMORRHAGE LPPS06 LPPS07 LPPS08-LPPS14 LPPS15 )
 %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); ","
 (UPPS02 UPPS03 UPPS04 UPPS04_DVT_PE UPPS04_PNEUMONIA UPPS04_SEPSIS UPPS04_SHOCK UPPS04_GIHEMORRHAGE UPPS06 UPPS07 UPPS08-UPPS14 UPPS15 )
 %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); ","
 (SPPS02 SPPS03 SPPS04 SPPS06 SPPS07 SPPS08-SPPS15 ) 
 %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); ","
 (XPPS02 XPPS03 XPPS04 XPPS06 XPPS07 XPPS08-XPPS15 ) (12.10 ",");
 ;
  
run;

%END;

%MEND TEXT;

%TEXT;

