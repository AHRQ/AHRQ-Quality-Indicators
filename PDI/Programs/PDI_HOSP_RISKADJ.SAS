*========================== Program: PDI_HOSP_RISKADJ.SAS ==========================;
*
*  TITLE: HOSPITAL LEVEL RISK ADJUSTED RATES FOR AHRQ PEDIATRIC QUALITY INDICATORS
*
*  DESCRIPTION:
*        Calculates Risk-Adjusted and Smoothed Rates for Pediatric Quality Hospital
*        Indicators, adjusting for: SEX, AGE, MDRG, ODC, CCSR
*        Variables created by the program: RPPDxx, LPPDxx, UPPDxx, SPPDxx, XPPDxx,
*                                          RPNQ03, LPNQ03, UPNQ03, SPNQ03, XPNQ03  
*        Output stratified by HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT. 
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

 title2 'PROGRAM PDI_HOSP_RISKADJ';
 title3 'AHRQ PEDIATRIC QUALITY INDICATORS: CALCULATE RISK-ADJUSTED HOSPITAL RATES';

* ---------------------------------------------------------------------- ;
* --- PEDIATRIC QUALITY INDICATOR (PDI) NAMING CONVENTION:           --- ;
* --- THE FIRST LETTER IDENTIFIES THE PEDIATRIC QUALITY              --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                             --- ;  
* ---       (T) NUMERATOR ("TOP") - FROM PDI_ALL_MEASURES            --- ;
* ---       (P) DENOMINATOR ("POP") - FROM PDI_ALL_MEASURES          --- ;
* ---       (O) OBSERVED RATES (T/P)                                 --- ;
* ---       (E) EXPECTED RATE                                        --- ;
* ---       (V) VARIANCE                                             --- ;
* ---       (R) RISK-ADJUSTED RATE                                   --- ;
* ---       (L) LOWER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE        --- ;
* ---       (U) UPPER CONFIDENCE LIMIT FOR RISK-ADJUSTED RATE        --- ;
* ---       (S) SMOOTHED RATE (NOT REPORTED FOR STRATA)              --- ;
* ---       (X) SMOOTHED RATE STANDARD ERROR (NOT REPORTED FOR STRATA) - ; 
* ---       (SN)RELIABILITY                                          --- ;
* --- THE SECOND LETTER IDENTIFIES THE PDI AS A HOSPITAL (P)         --- ;
* --- LEVEL INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS 'PD'.     --- ;
* --- THE LAST TWO DIGITS ARE THE INDICATOR NUMBER                   --- ;
* ---------------------------------------------------------------------- ;
* --- THE PDI_HOSP_REGVARS_v2024.SAS PROGRAM CREATES THE VARIABLES   --- ;
* --- USED FOR RISK ADJUSTMENT. THE USER MUST ENSURE THAT THE        --- ;
* --- PDI_ALL_CONTROL PROGRAM INCLUDES THE CORRECT LOCATION FOR THE  --- ;
* --- PDI_HOSP_REGVARS_v2024 SAS CODE.                               --- ;
*----------------------------------------------------------------------- ;

data &OUTFILE_MEAS.;
     set OUTMSR.&OUTFILE_MEAS.;
     %include MacLib(PDI_HOSP_Regvars_v2024.sas);
run ;

%MACRO MOD3(PD);

 *-- CREATE AN INDICATOR-LEVEL FLAG FOR WHETHER RISK-ADJUSTED AND SMOOTHED RATES ARE SUPPRESSED DUE TO NO PRDAY --* ;
%let PD_PRDAY = PD08 PD09;
%let PRDAY_RA = 0;
%if &PRDAY. = 0 %then %do;
  %do i=1 %to %sysfunc(countw(&PD_PRDAY., " "));
    %if %scan(&PD_PRDAY.,&i.," ") = &PD. %then %let PRDAY_RA = 1;
  %end;
%end;

 *-- DO NOT CALCULATE RISK-ADJUSTED AND SMOOTHED RATES IF CERTAIN FLAGS ARE SET IN THE CONTROL PROGRAM --* ;
%if &PRDAY_RA. = 1 %then %let SUPPRESS_RA = 1;
  %else %let SUPPRESS_RA = 0;

 *-- PARAMETER FILE USED FOR SCORING --*;
 filename RACOEFFS "&HQIRADIR./Gee_&PD._AGE_SEX.csv";

 * --- LOAD CSV PARAMTERS & SHAPE DATA  --- ;
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

 data MODEL_&PD.;
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
 proc Score data=&OUTFILE_MEAS. (where=(TP&PD. in (0,1))) score=MODEL_&PD. type=PARMS out=TEMP1Y&pd.;
   var &VARS_.;
 run;

 *-- CALCULATE PREDICTED VALUES (EHAT) --* ;
 data TEMP1Y&pd.;
   set TEMP1Y&pd.;
   EHAT = EXP(MHAT)/(1 + EXP(MHAT));
 RUN;


%LET DSID=%SYSFUNC(OPEN(TEMP1Y&pd.));
%IF &dsid. %THEN %LET DNUM=%SYSFUNC(ATTRN(&dsid,NOBS));
%ELSE %LET DNUM=0;
%LET DRC=%SYSFUNC(CLOSE(&dsid));

%IF &DNUM NE 0 %THEN %DO;

* --- EHAT IS CAPPED AT THE VALUE 0.99                                  --- ;
* --- IF, THE FLAG, CALIBRATION_OE_TO_REF_POP = 1, SET EHAT TO EHAT*O_E --- ;
* --- AND USE THE MODIFIED VALUE OF EHAT GOING FORWARD.                 --- ;

%if &Calibration_OE_to_ref_pop. = 1 %then %do;
 DATA TEMP1Y&pd.;  
    SET TEMP1Y&pd.;    
    %include MacLib(PDI_HOSP_OE_Array_v2024.sas);
    
    *-- MAP MEASURE NUM TO ARRAY INDEX SUB_N --* ;
    if "&PD." = "PD01"      then SUB_N = 1;
    if "&PD." = "PD05"      then SUB_N = 2;
    if "&PD." = "PD08"      then SUB_N = 3;
    if "&PD." = "PD09"      then SUB_N = 4;
    if "&PD." = "PD10"      then SUB_N = 5;
    if "&PD." = "PD12"      then SUB_N = 6;
    if "&PD." = "NQ03"      then SUB_N = 7;

    EHAT=EHAT*ARRYOE(SUB_N);
    if EHAT > 0.99 then EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT); 
    ONE=1;   
    
 RUN;
%end;
%else %if &Calibration_OE_to_ref_pop. = 0 %then %do; 
 PROC MEANS DATA=TEMP1Y&pd. noprint;
    VAR TP&PD. EHAT;
    OUTPUT OUT=OE&PD.(DROP=_TYPE_ _FREQ_) SUM(TP&PD. EHAT)=TP&PD. EHAT;
 RUN;
 
 DATA OE&PD.;
    SET OE&PD.;
    O_E&PD.=TP&PD./EHAT;
 RUN;
 
 PROC PRINT DATA=OE&PD.;
 RUN;
 
 DATA OE&PD.;
    SET OE&PD.(KEEP=O_E&PD.);
 RUN;
 
 DATA TEMP1Y&pd.;  
    IF _N_=1 THEN SET OE&PD.;
    SET TEMP1Y&pd.;
    EHAT=EHAT*O_E&PD.;
    if EHAT > 0.99 then EHAT = 0.99;
    PHAT = EHAT * (1 - EHAT);    
    ONE=1;
 RUN;
%end;

 *-- SUMMARIZE BY VARIOUS CLASSES --*;
 proc Summary data=TEMP1Y&pd.;
    class HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT;
    var   TP&PD. ONE EHAT PHAT ;
    output out=RP&PD. sum(TP&PD. ONE EHAT PHAT )=TP&PD. PP&PD. EHAT PHAT 
           n=DENOM;
 run;

 *-- APPLY RISK ADJUSTMENT & SMOOTHING --* ;
 data RP&PD.(KEEP=_TYPE_ HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT
                    EP&PD. RP&PD. LP&PD. UP&PD. SP&PD. XP&PD. VP&PD.
                    TP&PD. PP&PD. OP&PD. SNP&PD. );
   set RP&PD.;

   if _TYPE_ &TYPELVLH;

 *-- LOAD SIGNAL AND NOISE ARRAYS FROM TEXT FILE --* ;
 %include MacLib(PDI_HOSP_Sigvar_Array_v2024.sas);

 *-- MAP MEASURE NUM TO ARRAY INDEX SUB_N --* ;
 if "&PD." = "PD01" then SUB_N = 1;
 if "&PD." = "PD05" then SUB_N = 2;
 if "&PD." = "PD08" then SUB_N = 3;
 if "&PD." = "PD09" then SUB_N = 4;
 if "&PD." = "PD10" then SUB_N = 5;
 if "&PD." = "PD12" then SUB_N = 6;
 if "&PD." = "NQ03" then SUB_N = 7;

 *-- T = NUMERATOR     --* ;
 *-- P = DENOMINATOR   --* ;
 *-- E = EXPECTED      --* ;
 *-- R = RISK ADJUSTED --* ;
 *-- L = LOWER CI      --* ;
 *-- U = UPPER CI      --* ;
 *-- S = SMOOTHED      --* ;
 *-- X = SMOOTHED SE   --* ;
 *-- V = VARIANCE      --* ;
 *-- SN = RELIABILITY  --* ;

 EP&PD. = EHAT / PP&PD.;
 THAT = TP&PD. / PP&PD.;
 OP&PD. = TP&PD. / PP&PD.;

 if _TYPE_ in (0,64) and &SUPPRESS_RA. = 0 then do;
    RP&PD.  = (THAT / EP&PD.) * ARRYP3(SUB_N);
    SE&PD.  = (ARRYP3(SUB_N) / EP&PD.) * (1 / PP&PD.) * sqrt(PHAT);
    VP&PD.  = SE&PD.**2;
    SNP&PD. = ARRYP2(SUB_N) / (ARRYP2(SUB_N) + VP&PD.);
    SP&PD.  = (RP&PD. * SNP&PD.) + ((1 -  SNP&PD.) * ARRYP3(SUB_N));
    XP&PD.  = sqrt(ARRYP2(SUB_N)- (SNP&PD. * ARRYP2(SUB_N)));
 end;
 else if _TYPE_ in (1,2,3,65,66,67) and &SUPPRESS_RA. = 0 then do;
    RP&PD.  = (THAT / EP&PD.);
    SE&PD.  = (1 / EP&PD.) * (1 / PP&PD.) * sqrt(PHAT);
    VP&PD.  = SE&PD.**2;
    SNP&PD. = .;
    SP&PD.  = .;
    XP&PD.  = .;
 end;
 else do;
    EP&PD.  = .;
    RP&PD.  = .;
    SE&PD.  = .;
    VP&PD.  = .;
    SNP&PD. = .;
    SP&PD.  = .;
    XP&PD.  = .;
    LP&PD.  = .;
    UP&PD.  = .;
 end;


 if not missing(RP&PD.) then do;
   LP&PD. = RP&PD. - (1.96 * SE&PD.);
   if LP&PD. < 0 then LP&PD. = 0;
   UP&PD. = RP&PD. + (1.96 * SE&PD.);

   if _TYPE_ in (0,64) then do;
     if LP&PD. > 1 then LP&PD. = 1; 
     if UP&PD. > 1 then UP&PD. = 1;
     if RP&PD. > 1 then RP&PD. = 1;
     if SP&PD. > 1 then SP&PD. = 1;
   end;
 end;

 run;

 %END;
 %ELSE %DO;

 data RP&PD.;
   length HOSPID &HOSPID_TYP.. BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT 3;
          call missing(HOSPID); _TYPE_=0; BWHTCAT=.; AGEDCAT=.; PAGECAT=.; SEXCAT=.; PAYCAT=.; RACECAT=.; 
          EP&PD.=.; RP&PD.=.; LP&PD.=.; UP&PD.=.; SP&PD.=.; XP&PD.=.; VP&PD.=.; SNP&PD. = .; SE&PD.  = .;
          TP&PD.=.; PP&PD.=.; OP&PD.=.;
    output;
 run;

 %END;
 
 proc Sort data=RP&PD.;
   by _TYPE_ HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT;
 run; quit;

 proc Datasets NOLIST;
   delete TEMP1 TEMP1Y TEMP1_MODEL TEMP2_MODEL;
 run;

%MEND MOD3;

%MOD3(PD01);
%MOD3(PD05);
%MOD3(PD08);
%MOD3(PD09);
%MOD3(PD10);
%MOD3(PD12);
%MOD3(NQ03);


 * ----------------------------------------------------------------- ;
 * --- MERGE THE HOSPITAL ADJUSTED RATES FOR EACH INDICATOR (PD) --- ;
 * ----------------------------------------------------------------- ;

data OUTHRISK.&OUTFILE_HOSPRISK.;
 merge RPPD01 RPPD05 RPPD08 RPPD09 RPPD10 RPPD12 RPNQ03;
 by _TYPE_ HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT;

 %macro label_qis(qi_num=, qi_name=);
   label
   PP&qi_num. = "&qi_name. (Population)"
   OP&qi_num. = "&qi_name. (Observed rate)"
   EP&qi_num. = "&qi_name. (Expected rate)"
   RP&qi_num. = "&qi_name. (Risk-adjusted rate)"
   LP&qi_num. = "&qi_name. (Lower CL of risk-adjusted rate)"
   UP&qi_num. = "&qi_name. (Upper CL of risk-adjusted rate)"
   VP&qi_num. = "&qi_name. (Variance of the risk-adjusted rate)"
   SNP&qi_num. = "&qi_name. (Reliability of the risk-adjusted rate)"
   SP&qi_num. = "&qi_name. (Smoothed rate)"
   XP&qi_num. = "&qi_name. (Standard error of the smoothed rate)"
   ;
 %mend label_qis;
 
 %label_qis(qi_num=PD01, qi_name=PDI 01 Accidental Puncture or Laceration Rate);
 %label_qis(qi_num=PD05, qi_name=PDI 05 Iatrogenic Pneumothorax Rate);
 %label_qis(qi_num=PD08, qi_name=PDI 08 Postoperative Hemorrhage or Hematoma Rate);
 %label_qis(qi_num=PD09, qi_name=PDI 09 Postoperative Respiratory Failure Rate);
 %label_qis(qi_num=PD10, qi_name=PDI 10 Postoperative Sepsis Rate);
 %label_qis(qi_num=PD12, qi_name=PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate);
 %label_qis(qi_num=NQ03, qi_name=NQI 03 Neonatal Blood Stream Infection Rate);


 array ARRY1{7} EPPD01  EPPD05  EPPD08-EPPD10   EPPD12  EPNQ03;
 array ARRY2{7} RPPD01  RPPD05  RPPD08-RPPD10   RPPD12  RPNQ03;
 array ARRY3{7} LPPD01  LPPD05  LPPD08-LPPD10   LPPD12  LPNQ03;
 array ARRY4{7} UPPD01  UPPD05  UPPD08-UPPD10   UPPD12  UPNQ03;
 array ARRY5{7} SPPD01  SPPD05  SPPD08-SPPD10   SPPD12  SPNQ03;
 array ARRY6{7} XPPD01  XPPD05  XPPD08-XPPD10   XPPD12  XPNQ03;
 array ARRY7{7} VPPD01  VPPD05  VPPD08-VPPD10   VPPD12  VPNQ03;
 array ARRY8{7} PPPD01  PPPD05  PPPD08-PPPD10   PPPD12  PPNQ03;
 array ARRY9{7} SNPPD01 SNPPD05 SNPPD08-SNPPD10 SNPPD12 SNPNQ03;

 do I = 1 TO 7;
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

 format EPPD01  EPPD05  EPPD08-EPPD10   EPPD12  EPNQ03
        LPPD01  LPPD05  LPPD08-LPPD10   LPPD12  LPNQ03
        OPPD01  OPPD05  OPPD08-OPPD10   OPPD12  OPNQ03
        RPPD01  RPPD05  RPPD08-RPPD10   RPPD12  RPNQ03
        SPPD01  SPPD05  SPPD08-SPPD10   SPPD12  SPNQ03
        UPPD01  UPPD05  UPPD08-UPPD10   UPPD12  UPNQ03
        VPPD01  VPPD05  VPPD08-VPPD10   VPPD12  VPNQ03
        XPPD01  XPPD05  XPPD08-XPPD10   XPPD12  XPNQ03
        SNPPD01 SNPPD05 SNPPD08-SNPPD10 SNPPD12 SNPNQ03 13.7
		TPPD01  TPPD05  TPPD08-TPPD10   TPPD12  TPNQ03
		PPPD01  PPPD05  PPPD08-PPPD10   PPPD12  PPNQ03  13.0;
 run;

* -------------------------------------------------------------- ;
* --- CONTENTS AND MEANS OF HOSPITAL-LEVEL MERGED FILE --------- ;
* -------------------------------------------------------------- ;

proc Contents data=OUTHRISK.&OUTFILE_HOSPRISK. position;
run; quit;

***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -----***;
proc Means data=OUTHRISK.&OUTFILE_HOSPRISK. (WHERE=(_TYPE_ IN (64))) n nmiss min max mean nolabels;
   var TPPD01  TPPD05  TPPD08-TPPD10   TPPD12  TPNQ03;
   title  'SUMMARY OF PEDIATRIC QUALITY HOSPITAL-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=64';
run; quit;

proc Means data=OUTHRISK.&OUTFILE_HOSPRISK. (WHERE=(_TYPE_ IN (64))) n nmiss min max mean nolabels;
   var PPPD01  PPPD05  PPPD08-PPPD10   PPPD12  PPNQ03;
   title  'SUMMARY OF PEDIATRIC HOSPITAL-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=64';
run; quit;

proc Means data=OUTHRISK.&OUTFILE_HOSPRISK. (WHERE=(_TYPE_ IN (64))) n nmiss min max mean nolabels;
   var OPPD01  OPPD05  OPPD08-OPPD10   OPPD12   OPNQ03
       EPPD01  EPPD05  EPPD08-EPPD10   EPPD12   EPNQ03
       RPPD01  RPPD05  RPPD08-RPPD10   RPPD12   RPNQ03
       SPPD01  SPPD05  SPPD08-SPPD10   SPPD12   SPNQ03;
   title  'SUMMARY OF PEDIATRIC HOSPITAL-LEVEL INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=64';
run; quit;

* -------------------------------------------------------------- ;
* --- PRINT HOSPITAL MERGED FILE ------------------------------- ;
* -------------------------------------------------------------- ;

%MACRO PRT2;

%IF &PRINT. = 1 %THEN %DO;

%MACRO PRT(PD,TEXT,VOLUME,STRATA);
proc PRINT data=OUTHRISK.&OUTFILE_HOSPRISK. label SPLIT='*';
%IF   &VOLUME = 0 AND &STRATA=0 %THEN %DO;
var HOSPID TP&PD. PP&PD. OP&PD. EP&PD. RP&PD. LP&PD. UP&PD. SP&PD. XP&PD.;
label HOSPID  = "Hospital Identification Number"
      TP&PD. = "TP&PD.*(Numerator)"
      PP&PD. = "PP&PD.*(Population)"
      OP&PD. = "OP&PD.*(Observed rate)"
      EP&PD. = "EP&PD.*(Expected rate)"
      RP&PD. = "RP&PD.*(Risk-adjusted rate)"
      LP&PD. = "LP&PD.*(Lower CL of risk-adjusted rate)"
      UP&PD. = "UP&PD.*(Upper CL OF risk-adjusted rate)"
      SP&PD. = "SP&PD.*(Smoothed rate)"
      XP&PD. = "XP&PD.*(Standard error of the smoothed rate)"
      ;
format TP&PD. PP&PD. 13.0 OP&PD. RP&PD. EP&PD. SP&PD. XP&PD. 8.6;
%END;
%ELSE %IF &VOLUME. = 1 %THEN %DO;
var HOSPID TP&PD. ;
label HOSPID  = "HOSPID"
      TP&PD. = "TP&PD.*(NUMERATOR)"
      ;
format TP&PD. 13.0 ;
%END;
%ELSE %IF &STRATA. = 1 %THEN %DO;
var HOSPID TP&PD. PP&PD. OP&PD. EP&PD. RP&PD. LP&PD. UP&PD.;
label HOSPID  = "Hospital Identification Number"
      TP&PD. = "TP&PD.*(Numerator)"
      PP&PD. = "PP&PD.*(Population)"
      OP&PD. = "OP&PD.*(Observed rate)"
      EP&PD. = "EP&PD.*(Expected rate)"
      RP&PD. = "RP&PD.*(Risk-adjusted rate)"
      LP&PD. = "LP&PD.*(Lower CL of risk-adjusted rate)"
      UP&PD. = "UP&PD.*(Upper CL OF risk-adjusted rate)"
      ;
format TP&PD. PP&PD. 13.0 OP&PD. RP&PD. EP&PD. 8.6;
%END;
title4 "FINAL OUTPUT";
title5 "INDICATOR &PD.: &TEXT";

run;

%MEND PRT;

 %PRT(PD01, PDI 01 Accidental Puncture or Laceration Rate,0,0);
 %PRT(PD05, PDI 05 Iatrogenic Pneumothorax Rate,0,0);
 %PRT(PD08, PDI 08 Postoperative Hemorrhage or Hematoma Rate,0,0);
 %PRT(PD09, PDI 09 Postoperative Respiratory Failure Rate,0,0);
 %PRT(PD10, PDI 10 Postoperative Sepsis Rate,0,0);
 %PRT(PD12, PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate,0,0);
 %PRT(NQ03, NQI 03 Neonatal Blood Stream Infection Rate,0,0);

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
      ARRAY RATES OPPD: EPPD: RPPD: LPPD: UPPD: SPPD:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*1000;	
	  end;
	%END;
	
%mend scale_rates;

%IF &TXTHRISK. = 1 %THEN %DO;
	%LET TYPEPRN  = %sysfunc(tranwrd(&TYPELVLH.,%str(,),_));
	%LET TYPEPRN2  = %sysfunc(compress(&TYPEPRN.,'(IN )'));
	%let PDCSVREF = %sysfunc(pathname(PDTXTHRA));
	%let PDCSVRF2 =  %sysfunc(tranwrd(&PDCSVREF.,.TXT,_&TYPEPRN2..TXT));
 data _NULL_;
 set OUTHRISK.&OUTFILE_HOSPRISK.;
 %scale_rates;
 file  "&PDCSVRF2." lrecl=4500 ;
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
 "HOSP ID" "," "BWHT" "," "AGE DAYS" "," "AGE"  "," "SEX"  "," "PAYER" "," "RACE" "," "TYPE" ","
 "TPPD01" "," "TPPD05" "," "TPPD08" "," "TPPD09" "," "TPPD10" "," "TPPD12" ","  "TPNQ03" ","
 
 "PPPD01" "," "PPPD05" "," "PPPD08" "," "PPPD09" "," "PPPD10" "," "PPPD12" ","  "PPNQ03" ","
 
 "OPPD01" "," "OPPD05" "," "OPPD08" "," "OPPD09" "," "OPPD10" "," "OPPD12" ","  "OPNQ03" ","
 
 "EPPD01" "," "EPPD05" "," "EPPD08" "," "EPPD09" "," "EPPD10" "," "EPPD12" ","  "EPNQ03" ","
 
 "RPPD01" "," "RPPD05" "," "RPPD08" "," "RPPD09" "," "RPPD10" "," "RPPD12" ","  "RPNQ03" ","
 
 "LPPD01" "," "LPPD05" "," "LPPD08" "," "LPPD09" "," "LPPD10" "," "LPPD12" ","  "LPNQ03" ","
 
 "UPPD01" "," "UPPD05" "," "UPPD08" "," "UPPD09" "," "UPPD10" "," "UPPD12" ","  "UPNQ03" ","
 
 "SPPD01" "," "SPPD05" "," "SPPD08" "," "SPPD09" "," "SPPD10" "," "SPPD12" ","  "SPNQ03"  ","
 
 "XPPD01" "," "XPPD05" "," "XPPD08" "," "XPPD09" "," "XPPD10" "," "XPPD12" ","  "XPNQ03"  ","
 ;
 end;
 
 put HOSPID 13. "," BWHTCAT 3. "," AGEDCAT 3. "," PAGECAT 3. "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPPD01 TPPD05 TPPD08-TPPD10 TPPD12 TPNQ03) (7.0  ",")  ","
 (PPPD01 PPPD05 PPPD08-PPPD10 PPPD12 PPNQ03) (13.0 ",")  ","
 (OPPD01 OPPD05 OPPD08-OPPD10 OPPD12 OPNQ03) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); "," 
 (EPPD01 EPPD05 EPPD08-EPPD10 EPPD12 EPNQ03) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); "," 
 (RPPD01 RPPD05 RPPD08-RPPD10 RPPD12 RPNQ03) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); "," 
 (LPPD01 LPPD05 LPPD08-LPPD10 LPPD12 LPNQ03) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); "," 
 (UPPD01 UPPD05 UPPD08-UPPD10 UPPD12 UPNQ03) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); "," 
 (SPPD01 SPPD05 SPPD08-SPPD10 SPPD12 SPNQ03) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); "," 
 (XPPD01 XPPD05 XPPD08-XPPD10 XPPD12 XPNQ03) (12.10 ",") 
 ;
 
run;

%END;

%MEND TEXT;

%TEXT;
