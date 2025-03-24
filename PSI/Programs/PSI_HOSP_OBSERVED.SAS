*================ Program: PSI_HOSP_OBSERVED.SAS ======================;
*
*  TITLE:  HOSPITAL LEVEL OBSERVED RATES FOR AHRQ
*          PATIENT SAFETY INDICATORS
*
*  DESCRIPTION:
*     Calculate observed rates for hospital level Patient Safety Indicators
*     using numerator and denominator output from PSI_HOSP_MEASURES.SAS.
*     Output stratified by HOSPID, AGECAT, SEXCAT, PAYCAT, and RACECAT.
*     Variable created by this program is OPPSXX
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*======================================================================;

 title2 'PROGRAM: PSI_HOSP_OBSERVED';
 title3 'AHRQ PATIENT SAFETY INDICATORS: CALCULATE OBSERVED HOSPITAL LEVEL RATES';

* ------------------------------------------------------------------- ;
* --- HOSPITAL LEVEL MEANS ON PSI_HOSP_MEASURES OUTPUT DATA FILE  --- ;
* --- VARIABLES TPPSxx AND PPPSxx ARE CREATED IN MEASURES AND     --- ;
* --- ARE USED TO CREATE THE OPPSxx VARIABLES                     --- ;
* ------------------------------------------------------------------- ;

* ------------------------------------------------------------------- ;
* --- PATIENT SAFETY INDICATOR (PSI) NAMING CONVENTION:           --- ;
* --- THE FIRST LETTER IDENTIFIES THE PATIENT SAFETY              --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                          --- ;
* ---     (T) NUMERATOR ("TOP") - FROM PSI_HOSP_MEASURES          --- ;
* ---     (P) DENOMINATOR ("POPULATION") - FROM PSI_HOSP_MEASURES --- ;
* ---     (O) OBSERVED RATES (T/P)                                --- ;
* --- THE SECOND LETTER IDENTIFIES THE INDICATOR AS A HOSPITAL (P)--- ;
* --- LEVEL INDICATOR. THE NEXT TWO CHARACTERS ARE ALWAYS 'PS'    --- ;
* --- THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.               --- ;
* ------------------------------------------------------------------- ;

 proc Summary data=OUTMSR.&OUTFILE_MEAS.;
   class  HOSPID AGECAT SEXCAT PAYCAT RACECAT;
   var    TPPS02-TPPS15 TPPS18 TPPS19;
   output out=&OUTFILE_HOSPOBS.
        sum (TPPS02-TPPS04 TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE TPPS05-TPPS08 TPPS08_HIP_FX TPPS08_OTHER_FX TPPS09-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 TPPS18 TPPS19) =
             TPPS02-TPPS04 TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE TPPS05-TPPS08 TPPS08_HIP_FX TPPS08_OTHER_FX TPPS09-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 TPPS18 TPPS19
        sum (PPPS02-PPPS04 PPPS04_DVT_PE PPPS04_PNEUMONIA PPPS04_SEPSIS PPPS04_SHOCK PPPS04_GIHEMORRHAGE PPPS05-PPPS08 PPPS08_HIP_FX PPPS08_OTHER_FX PPPS09-PPPS14 PPPS14_OPEN PPPS14_NONOPEN PPPS15 PPPS18 PPPS19) =
             PPPS02-PPPS04 PPPS04_DVT_PE PPPS04_PNEUMONIA PPPS04_SEPSIS PPPS04_SHOCK PPPS04_GIHEMORRHAGE PPPS05-PPPS08 PPPS08_HIP_FX PPPS08_OTHER_FX PPPS09-PPPS14 PPPS14_OPEN PPPS14_NONOPEN PPPS15 PPPS18 PPPS19
        mean(TPPS02-TPPS04 TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE TPPS05-TPPS08 TPPS08_HIP_FX TPPS08_OTHER_FX TPPS09-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 TPPS18 TPPS19) =
             OPPS02-OPPS04 OPPS04_DVT_PE OPPS04_PNEUMONIA OPPS04_SEPSIS OPPS04_SHOCK OPPS04_GIHEMORRHAGE OPPS05-OPPS08 OPPS08_HIP_FX OPPS08_OTHER_FX OPPS09-OPPS14 OPPS14_OPEN OPPS14_NONOPEN OPPS15 OPPS18 OPPS19;
 run;

 proc Sort data=&OUTFILE_HOSPOBS.;
   by _TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 run;

 data OUTHOBS.&OUTFILE_HOSPOBS.;
   set &OUTFILE_HOSPOBS. (where=(_TYPE_ &TYPELVLH)) ;

 label
 HOSPID = 'Hospital Identification Number'
 _TYPE_ = 'Stratification Level'
 ;

 * -------------------------------------------------------------- ;
 * --- DEFINE HOSPITAL LEVEL INDICATORS                       --- ;
 * -------------------------------------------------------------- ;
 
 %macro label_qis(flag=, qi_num=, qi_name=);
   label
   TP&qi_num. = "&qi_name. (Numerator)"
   PP&qi_num. = "&qi_name. (Population)"
   OP&qi_num. = "&qi_name. (Observed rate)"
   ;

 * --- RE-LABEL DAY DEPENDENT INDICATORS                      --- ;
   %IF &PRDAY. = 0 AND &flag. = 1 %THEN %DO;
    label
    TP&qi_num. = "&qi_name.-NO PRDAY (Numerator)"
    PP&qi_num. = "&qi_name.-NO PRDAY (Population)"
    OP&qi_num. = "&qi_name.-NO PRDAY (Observed rate)"
    ;
   %END;

 %mend label_qis;

 %label_qis(flag=0, qi_num=PS02,              qi_name=PSI 02 Death Rate in Low-Mortality Diagnosis Related Groups (DRGs));
 %label_qis(flag=0, qi_num=PS03,              qi_name=PSI 03 Pressure Ulcer Rate);
 %label_qis(flag=1, qi_num=PS04,              qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications);
 %label_qis(flag=1, qi_num=PS04_DVT_PE,       qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Deep Vein Thrombosis/Pulmonary Embolism (DVT/PE));
 %label_qis(flag=1, qi_num=PS04_PNEUMONIA,    qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Pneumonia);
 %label_qis(flag=1, qi_num=PS04_SEPSIS,       qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Sepsis);
 %label_qis(flag=1, qi_num=PS04_SHOCK,        qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Shock/Cardiac Arrest);
 %label_qis(flag=1, qi_num=PS04_GIHEMORRHAGE, qi_name=PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum: Gastrointestinal (GI) Hemorrhage/Acute Ulcer);
 %label_qis(flag=0, qi_num=PS05,              qi_name=PSI 05 Retained Surgical Item or Unretrieved Device Fragment Count);
 %label_qis(flag=0, qi_num=PS06,              qi_name=PSI 06 Iatrogenic Pneumothorax Rate);
 %label_qis(flag=0, qi_num=PS07,              qi_name=PSI 07 Central Venous Catheter-Related Blood Stream Infection Rate);
 %label_qis(flag=0, qi_num=PS08,              qi_name=PSI 08 In-Hospital Fall-Associated Fracture Rate);
 %label_qis(flag=0, qi_num=PS08_HIP_FX,       qi_name=PSI 08 In-Hospital Fall with Hip Fracture Rate Component);
 %label_qis(flag=0, qi_num=PS08_OTHER_FX,     qi_name=PSI 08 In-Hospital Fall with Other Fracture Rate Component);
 %label_qis(flag=1, qi_num=PS09,              qi_name=PSI 09 Postoperative Hemorrhage or Hematoma Rate);
 %label_qis(flag=1, qi_num=PS10,              qi_name=PSI 10 Postoperative Acute Kidney Injury Requiring Dialysis Rate);
 %label_qis(flag=1, qi_num=PS11,              qi_name=PSI 11 Postoperative Respiratory Failure Rate);
 %label_qis(flag=1, qi_num=PS12,              qi_name=PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate);
 %label_qis(flag=0, qi_num=PS13,              qi_name=PSI 13 Postoperative Sepsis Rate);
 %label_qis(flag=1, qi_num=PS14,              qi_name=PSI 14 Postoperative Wound Dehiscence Rate);
 %label_qis(flag=1, qi_num=PS14_OPEN,         qi_name=PSI 14 Postoperative Wound Dehiscence Rate Stratum: Open Approach);
 %label_qis(flag=1, qi_num=PS14_NONOPEN,      qi_name=PSI 14 Postoperative Wound Dehiscence Rate Stratum: Non-Open Approach);
 %label_qis(flag=1, qi_num=PS15,              qi_name=PSI 15 Abdominopelvic Accidental Puncture or Laceration Rate);
 %label_qis(flag=0, qi_num=PS18,              qi_name=PSI 18 Obstetric Trauma Rate - Vaginal Delivery With Instrument);
 %label_qis(flag=0, qi_num=PS19,              qi_name=PSI 19 Obstetric Trauma Rate - Vaginal Delivery Without Instrument);

 drop _FREQ_ ;

 run;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF HOSPITAL OBSERVED OUTPUT FILE    --- ;
 * -------------------------------------------------------------- ;

 proc Contents data=OUTHOBS.&OUTFILE_HOSPOBS. position;
 run;

***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;
proc Means data=OUTHOBS.&OUTFILE_HOSPOBS. (where=(_TYPE_ IN (16))) n nmiss min max sum nolabels;
   var TPPS02-TPPS04 TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE TPPS05-TPPS08 TPPS08_HIP_FX TPPS08_OTHER_FX TPPS09-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 TPPS18 TPPS19;
   title  'SUMMARY OF PATIENT SAFETY HOSPITAL LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=16';
run; quit;

proc Means data=OUTHOBS.&OUTFILE_HOSPOBS. (where=(_TYPE_ IN (16))) n nmiss min max sum nolabels;
   var PPPS02-PPPS04 PPPS04_DVT_PE PPPS04_PNEUMONIA PPPS04_SEPSIS PPPS04_SHOCK PPPS04_GIHEMORRHAGE PPPS05-PPPS08 PPPS08_HIP_FX PPPS08_OTHER_FX PPPS09-PPPS14 PPPS14_OPEN PPPS14_NONOPEN PPPS15 PPPS18 PPPS19;
   title  'SUMMARY OF PATIENT SAFETY HOSPITAL LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=16';
run; quit;

proc Means data=OUTHOBS.&OUTFILE_HOSPOBS. (where=(_TYPE_ IN (16))) n nmiss min max mean nolabels;
   var OPPS02-OPPS04 OPPS04_DVT_PE OPPS04_PNEUMONIA OPPS04_SEPSIS OPPS04_SHOCK OPPS04_GIHEMORRHAGE OPPS05-OPPS08 OPPS08_HIP_FX OPPS08_OTHER_FX OPPS09-OPPS14 OPPS14_OPEN OPPS14_NONOPEN OPPS15 OPPS18 OPPS19;
   title  'SUMMARY OF PATIENT SAFETY HOSPITAL LEVEL INDICATOR AVERAGE RATES (MEAN) WHEN _TYPE_=16';
run; quit;

 * -------------------------------------------------------------- ;
 * --- PRINT HOSPITAL OBSERVED MEANS FILE TO SAS OUTPUT       --- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PS,TEXT,VOLUME=0);

 proc  Print data=OUTHOBS.&OUTFILE_HOSPOBS. label split='*';
 %IF &VOLUME=0 %THEN %DO;
   var   HOSPID AGECAT SEXCAT PAYCAT RACECAT TPPS&PS. PPPS&PS. OPPS&PS. ;
   label HOSPID  = "HOSPID"
         AGECAT  = "AGECAT"
         SEXCAT  = "SEXCAT"
         PAYCAT  = "PAYCAT"
         RACECAT = "RACECAT"
         TPPS&PS.   = "TPPS&PS.*(Numerator)"
         PPPS&PS.   = "PPPS&PS.*(Population)"
         OPPS&PS.   = "OPPS&PS.*(Observed)"
         ;
   format AGECAT AGECAT.
          SEXCAT SEXCAT.
          PAYCAT PAYCAT.
          RACECAT RACECAT.
          TPPS&PS. PPPS&PS. 13.0 OPPS&PS. 8.6;
 %END;	
 %ELSE %DO;
   var   HOSPID AGECAT SEXCAT PAYCAT RACECAT TPPS&PS.;
   label HOSPID  = "HOSPID"
         AGECAT  = "AGECAT"
         SEXCAT  = "SEXCAT"
         PAYCAT  = "PAYCAT"
         RACECAT = "RACECAT"
         TPPS&PS.   = "TPPS&PS.*(Numerator)"
         ;
   format AGECAT AGECAT.
          SEXCAT SEXCAT.
          PAYCAT PAYCAT.
          RACECAT RACECAT.
          TPPS&PS. 13.0
		  ;
  %END;
 title4 "Indicator &PS.: &TEXT";
 run;

 %MEND PRT;

 %PRT(02,Death Rate in Low-Mortality Diagnosis Related Groups (DRGs));
 %IF &PRDAY. = 1 %THEN %DO;
     %PRT(03,Pressure Ulcer Rate);
 %END;
 %ELSE %DO;
     %PRT(03,Pressure Ulcer Rate-NO PRDAY);
 %END;
 %PRT(04,Death Rate among Surgical Inpatients with Serious Treatable Complications);
 %PRT(04_DVT_PE      ,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum_DVT_PE      : Deep Vein Thrombosis/Pulmonary Embolism (DVT/PE));
 %PRT(04_PNEUMONIA   ,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum_PNEUMONIA   : Pneumonia);
 %PRT(04_SEPSIS      ,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum_SEPSIS      : Sepsis);
 %PRT(04_SHOCK       ,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum_SHOCK       : Shock/Cardiac Arrest);
 %PRT(04_GIHEMORRHAGE,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum_GIHEMORRHAGE: Gastrointestinal (GI) Hemorrhage/Acute Ulcer);
 %PRT(05,Retained Surgical Item or Unretrieved Device Fragment Count,VOLUME=1);
 %PRT(06,Iatrogenic Pneumothorax Rate);
 %PRT(07,Central Venous Catheter-Related Blood Stream Infection Rate);
 %IF &PRDAY. = 1 %THEN %DO;
     %PRT(08,In-Hospital Fall-Associated Fracture Rate);
     %PRT(08_HIP_FX,In-Hospital Fall with Hip Fracture Rate Component);
     %PRT(08_OTHER_FX,In-Hospital Fall with Other Fracture Rate Component);
     %PRT(09,Postoperative Hemorrhage or Hematoma Rate);
     %PRT(10,Postoperative Acute Kidney Injury Requiring Dialysis Rate);
     %PRT(11,Postoperative Respiratory Failure Rate);
     %PRT(12,Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate);
 %END;
 %ELSE %DO;
     %PRT(08,In-Hospital Fall-Associated Fracture Rate-NO PRDAY);
     %PRT(08_HIP_FX,In-Hospital Fall with Hip Fracture Rate Component-NO PRDAY);
     %PRT(08_OTHER_FX,In-Hospital Fall with Other Fracture Rate Component-NO PRDAY);
     %PRT(09,Postoperative Hemorrhage or Hematoma Rate-NO PRDAY);
     %PRT(10,Postoperative Acute Kidney Injury Requiring Dialysis Rate-NO PRDAY);
     %PRT(11,Postoperative Respiratory Failure Rate-NO PRDAY);
     %PRT(12,Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate-NO PRDAY);
 %END;
 %PRT(13,Postoperative Sepsis Rate);
 %IF &PRDAY. = 1 %THEN %DO;
     %PRT(14,Postoperative Wound Dehiscence Rate);
     %PRT(14_OPEN   ,Postoperative Wound Dehiscence Rate Stratum_OPEN   : Open Approach);
     %PRT(14_NONOPEN,Postoperative Wound Dehiscence Rate Stratum_NONOPEN: Non-Open Approach);
 %END;
 %ELSE %DO;
     %PRT(14,Postoperative Wound Dehiscence Rate-NO PRDAY);
     %PRT(14_OPEN   ,Postoperative Wound Dehiscence Rate-NO PRDAY Stratum_OPEN   : Open Approach);
     %PRT(14_NONOPEN,Postoperative Wound Dehiscence Rate-NO PRDAY Stratum_NONOPEN: Non-Open Approach);
 %END;
 %PRT(15,Abdominopelvic Accidental Puncture or Laceration Rate);
 %PRT(18,Obstetric Trauma Rate - Vaginal Delivery With Instrument);
 %PRT(19,Obstetric Trauma Rate - Vaginal Delivery Without Instrument);

 %END;

 %MEND PRT2;

 %PRT2;

 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS                           --- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXTP1;
 
 %macro scale_rates;
   
   %IF &SCALE_RATES = 1 %THEN %DO;
      ARRAY RATES OPPS:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*1000;	
	  end;
	%END;
	
 %mend scale_rates;
 
 %if &TXTHOBS. = 1  %then %do;
 data _NULL_;
 set OUTHOBS.&OUTFILE_HOSPOBS.;
 %scale_rates;
 file PSTXTHOB lrecl=2000 ;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_HOSPOBS data set created with the following CONTROL options:";
 put "&&Calibration_OE_to_ref_pop&Calibration_OE_to_ref_pop. (Calibration_OE_to_ref_pop = &Calibration_OE_to_ref_pop)";
 put "&&MDC_PROVIDED&MDC_PROVIDED. (MDC_PROVIDED = &MDC_PROVIDED)";
 put "&&PRDAY&PRDAY. (PRDAY = &PRDAY)";
 put "Output stratification includes TYPELVLH = &TYPELVLH";
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "HOSP ID" "," "Age" "," "Sex" "," "Payer" "," "Race" "," "Type" ","
 "TPPS02" "," "TPPS03" "," "TPPS04" "," "TPPS04_DVT_PE" "," "TPPS04_PNEUMONIA" "," "TPPS04_SEPSIS" "," "TPPS04_SHOCK" "," "TPPS04_GIHEMORRHAGE" ","
 "TPPS05" "," "TPPS06" "," "TPPS07" "," "TPPS08" "," "TPPS08_HIP_FX" "," "TPPS08_OTHER_FX" ","
 "TPPS09" "," "TPPS10" "," "TPPS11" "," "TPPS12" ","
 "TPPS13" "," "TPPS14" "," "TPPS14_OPEN" "," "TPPS14_NONOPEN" "," "TPPS15" ","
 "TPPS18" "," "TPPS19" ","
 "PPPS02" "," "PPPS03" "," "PPPS04" "," "PPPS04_DVT_PE" "," "PPPS04_PNEUMONIA" "," "PPPS04_SEPSIS" "," "PPPS04_SHOCK" "," "PPPS04_GIHEMORRHAGE" ","
 "PPPS05" "," "PPPS06" "," "PPPS07" "," "PPPS08" "," "PPPS08_HIP_FX" "," "PPPS08_OTHER_FX" ","
 "PPPS09" "," "PPPS10" "," "PPPS11" "," "PPPS12" ","
 "PPPS13" "," "PPPS14" "," "PPPS14_OPEN" "," "PPPS14_NONOPEN" "," "PPPS15" ","
 "PPPS18" "," "PPPS19" ","
 "OPPS02" "," "OPPS03" "," "OPPS04" "," "OPPS04_DVT_PE" "," "OPPS04_PNEUMONIA" "," "OPPS04_SEPSIS" "," "OPPS04_SHOCK" "," "OPPS04_GIHEMORRHAGE" ","
 "OPPS05" "," "OPPS06" "," "OPPS07" "," "OPPS08" "," "OPPS08_HIP_FX" "," "OPPS08_OTHER_FX" ","
 "OPPS09" "," "OPPS10" "," "OPPS11" "," "OPPS12" ","
 "OPPS13" "," "OPPS14" "," "OPPS14_OPEN" "," "OPPS14_NONOPEN" "," "OPPS15" ","
 "OPPS18" "," "OPPS19"
 ;
 end;

 put HOSPID 13. "," AGECAT 3. "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPPS02-TPPS04 TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE TPPS05-TPPS08 TPPS08_HIP_FX TPPS08_OTHER_FX TPPS09-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 TPPS18 TPPS19) (7.0 ",")
  ","
 (PPPS02-PPPS04 PPPS04_DVT_PE PPPS04_PNEUMONIA PPPS04_SEPSIS PPPS04_SHOCK PPPS04_GIHEMORRHAGE PPPS05-PPPS08 PPPS08_HIP_FX PPPS08_OTHER_FX PPPS09-PPPS14 PPPS14_OPEN PPPS14_NONOPEN PPPS15 PPPS18 PPPS19) (13.0 ",")
 ","
 (OPPS02-OPPS04 OPPS04_DVT_PE OPPS04_PNEUMONIA OPPS04_SEPSIS OPPS04_SHOCK OPPS04_GIHEMORRHAGE OPPS05-OPPS08 OPPS08_HIP_FX OPPS08_OTHER_FX OPPS09-OPPS14 OPPS14_OPEN OPPS14_NONOPEN OPPS15 OPPS18 OPPS19)
 %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ;
 run;

 %END;

 %MEND TEXTP1;

 %TEXTP1;
