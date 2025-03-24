*======================= Program: PDI_HOSP_OBSERVED.SAS ======================;
*
*  TITLE:  HOSPITAL LEVEL OBSERVED RATES FOR AHRQ PEDIATRIC QUALITY INDICATORS
*
*  DESCRIPTION:
*     Calculates observed rates for hospital level Pediatric Quality Indicators
*     using output from PDI_ALL_MEASURES.SAS.
*     Output stratified by HOSPID, AGECAT, SEXCAT, PAYCAT and RACECAT.
*     Variables created by this program are PPPDXX, PPNQ03, PPPS17, 
*     OPPDXX, OPNQ03, and OPPS17.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*=============================================================================;

 title2 'PROGRAM: PDI_HOSP_OBSERVED';
 title3 'AHRQ PEDIATRIC QUALITY INDICATORS: CALCULATE OBSERVED HOSPITAL LEVEL RATES';

* ------------------------------------------------------------------- ;
* --- HOSPITAL LEVEL MEANS ON PDI_HOSP_MEASURES OUTPUT DATA FILE  --- ;
* --- THE TPPDxx, TPNQ03 AND TPPS17 VARIABLES ARE CREATED IN THE  --- ;
* --- MEAUSURES PROGRAM AND USED TO CALCULATE THE                 --- ;
* --- PPPDxx, PPNQ03, PPS17, OPPDxx, OPNQ03 AND OPPS17 VARIABLES. --- ;
* ------------------------------------------------------------------- ;

* ------------------------------------------------------------------- ;
* --- PEDIATRIC QUALITY INDICATOR (PDI) NAMING CONVENTION:        --- ;
* --- THE FIRST LETTER IDENTIFIES THE PEDIATRIC QUALITY           --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                          --- ;
* ---           (T) NUMERATOR ("TOP") - FROM PDI_ALL_MEASURES     --- ;
* ---           (P) DENOMINATOR ("POPULATION")                    --- ;
* ---           (O) OBSERVED RATES (T/P)                          --- ;
* --- THE SECOND LETTER IDENTIFIES THE INDICATOR AS A HOSPITAL    --- ;
* --- (P) LEVEL INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS    --- ;
* --- 'PD' OR 'NQ'. THE LAST TWO DIGITS ARE THE INDICATOR NUMBER. --- ;
* ------------------------------------------------------------------- ;

 proc   Summary data=OUTMSR.&OUTFILE_MEAS.;
 class  HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT;
 var    TPPD01 TPPD05 TPPD08-TPPD10 TPPD12 TPNQ03 TPPS17;
 output out=&OUTFILE_HOSPOBS.
        sum (TPPD01 TPPD05 TPPD08-TPPD10 TPPD12 TPNQ03 TPPS17)=
        n   (TPPD01 TPPD05 TPPD08-TPPD10 TPPD12 TPNQ03 TPPS17)=
             PPPD01 PPPD05 PPPD08-PPPD10 PPPD12 PPNQ03 PPPS17
        mean (TPPD01 TPPD05 TPPD08-TPPD10 TPPD12 TPNQ03 TPPS17)=
              OPPD01 OPPD05 OPPD08-OPPD10 OPPD12 OPNQ03 OPPS17;
 run;

 proc   Sort data=&OUTFILE_HOSPOBS.;
 by _TYPE_ HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT;
 run;

 data   OUTHOBS.&OUTFILE_HOSPOBS.;
 set    &OUTFILE_HOSPOBS. (where=(_TYPE_ &TYPELVLH));

 array PPPD PPPD01 PPPD05 PPPD08-PPPD10 PPPD12 PPNQ03 PPPS17;

 do over PPPD;
    if PPPD eq 0 then PPPD = .;
 end;

 label
 HOSPID = 'Hospital Identification Number'
 _TYPE_ = 'Stratification Level'
 ;
 
 * -------------------------------------------------------------- ;
 * --- DEFINE HOSPITAL LEVEL INDICATORS ------------------------- ;
 * -------------------------------------------------------------- ;                                                                  
 
 %macro label_qis(flag=, qi_num=, qi_name=);
   label 
   TP&qi_num. = "&qi_name. (Numerator)"
   PP&qi_num. = "&qi_name. (Population)"
   OP&qi_num. = "&qi_name. (Observed rate)"
   ;
   
   * --- RE-LABEL DAY DEPENDENT INDICATORS                    --- ;
   %IF &PRDAY. = 0 AND &flag. = 1 %THEN %DO;
    label
    TP&qi_num. = "&qi_name.-NO PRDAY (Numerator)"
    PP&qi_num. = "&qi_name.-NO PRDAY (Population)"
    OP&qi_num. = "&qi_name.-NO PRDAY (Observed rate)"
    ;
   %END;
 %mend label_qis;

 %label_qis(flag=0, qi_num=PD01, qi_name=PDI 01 Accidental Puncture or Laceration Rate);
 %label_qis(flag=0, qi_num=PD05, qi_name=PDI 05 Iatrogenic Pneumothorax Rate);
 %label_qis(flag=1, qi_num=PD08, qi_name=PDI 08 Postoperative Hemorrhage or Hematoma Rate);
 %label_qis(flag=1, qi_num=PD09, qi_name=PDI 09 Postoperative Respiratory Failure Rate);
 %label_qis(flag=0, qi_num=PD10, qi_name=PDI 10 Postoperative Sepsis Rate);
 %label_qis(flag=0, qi_num=PD12, qi_name=PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate);
 %label_qis(flag=0, qi_num=PS17, qi_name=PSI 17 Birth Trauma Rate - Injury to Neonate);
 %label_qis(flag=0, qi_num=NQ03, qi_name=NQI 03 Neonatal Blood Stream Infection Rate);

 drop _FREQ_ ;

 run;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF HOSPITAL OBSERVED MEANS FILE ------- ;
 * -------------------------------------------------------------- ;

 proc   Contents data=OUTHOBS.&OUTFILE_HOSPOBS. position;
 run;

 ***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;
proc Means data=OUTHOBS.&OUTFILE_HOSPOBS. (WHERE=(_TYPE_ IN (64))) n nmiss min max sum nolabels;
   var TPPD01 TPPD05 TPPD08-TPPD10 TPPD12 TPNQ03 TPPS17;
   title  'SUMMARY OF PEDIATRIC HOSPITAL-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=64';
run; quit;

proc Means data=OUTHOBS.&OUTFILE_HOSPOBS. (WHERE=(_TYPE_ IN (64))) n nmiss min max sum nolabels;
   var PPPD01 PPPD05 PPPD08-PPPD10 PPPD12 PPNQ03 PPPS17 ;
   title  'SUMMARY OF PEDIATRIC HOSPITAL-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=64';
run; quit;

proc Means data=OUTHOBS.&OUTFILE_HOSPOBS. (WHERE=(_TYPE_ IN (64))) n nmiss min max mean nolabels;
   var OPPD01 OPPD05 OPPD08-OPPD10 OPPD12 OPNQ03 OPPS17;
   title  'SUMMARY OF PEDIATRIC HOSPITAL-LEVEL OBSERVED INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=64';
run; quit;

 * -------------------------------------------------------------- ;
 * --- PRINT HOSPITAL OBSERVED MEANS FILE TO SAS OUTPUT       --- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PD,TEXT,VOLUME);

 proc   Print data=OUTHOBS.&OUTFILE_HOSPOBS. label SPLIT='*';
 %IF &VOLUME=0 %THEN %DO;
 var    HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT TP&PD. PP&PD. OP&PD. ;
 label HOSPID  = "Hospital Identification Number"
       BWHTCAT = "Birth Weight Categories"
       AGEDCAT = "Age in Days Categories"
       PAGECAT = "Pediatric Age Categories"
       SEXCAT  = "Sex Categories"
       PAYCAT  = "Patient Primary Payer"
       RACECAT = "Race Categories"
       TP&PD.   = "TP&PD.*(Numerator)"
       PP&PD.   = "PP&PD.*(Population)"
       OP&PD.   = "OP&PD.*(Observed rate)"
       ;
 format BWHTCAT BWHTCAT.
        AGEDCAT AGEDCAT.
        PAGECAT PAGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
        TP&PD. PP&PD. 13.0 OP&PD. 8.6;
 %END;
 %ELSE %DO;
 var    HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT TP&PD.  ;
 label HOSPID  = "Hospital Identification Number"
       BWHTCAT = "Birth Weight Categories"
       AGEDCAT = "Age in Days Categories"
       PAGECAT = "Pediatric Age Categories"
       SEXCAT  = "Sex Categories"
       PAYCAT  = "Patient Primary Payer"
       RACECAT = "Race Categories"
       TP&PD.   = "TP&PD.*(Numerator)"
       ;
 format BWHTCAT BWHTCAT.
        AGEDCAT AGEDCAT.
        PAGECAT PAGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
        TP&PD. 13.0;
 %END;
 title4 "Indicator &PD.: &TEXT";

 run;

 %MEND PRT;

 %PRT(PD01,Accidental Puncture or Laceration Rate,0);
 %PRT(PD05,Iatrogenic Pneumothorax Rate,0);
 %PRT(PD08,Postoperative Hemorrhage or Hematoma Rate,0);
 %PRT(PD09,Postoperative Respiratory Failure Rate,0);
 %PRT(PD10,Postoperative Sepsis Rate,0);
 %PRT(PD12,Central Venous Catheter-Related Blood Stream Infection Rate,0);
 %PRT(NQ03,Neonatal Blood Stream Infection Rate,0);
 %PRT(PS17,Birth Trauma Rate - Injury to Neonate,0);

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
      ARRAY RATES OPPD:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*1000;	
	  end;
	%END;
	
 %mend scale_rates;

 %if &TXTHOBS. = 1  %then %do;

 data _NULL_;
 set  OUTHOBS.&OUTFILE_HOSPOBS.;
 %scale_rates;
 file  PDTXTHOB lrecl=2000 ;
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
 put "HOSP ID" "," "BWHT" "," "Age Days" "," "Age"  "," "Sex"  "," "Payer" "," "Race" "," "Type" ","
 "TPPD01" "," 
 "TPPD05" "," "TPPD08" ","
 "TPPD09" "," "TPPD10" "," "TPPD12" ","
 "TPNQ03" "," "TPPS17" "," 
 "PPPD01" "," 
 "PPPD05" ","              "PPPD08" ","
 "PPPD09" "," "PPPD10" "," "PPPD12" ","
 "PPNQ03" "," "PPPS17" "," 
 "OPPD01" "," 
 "OPPD05" ","               "OPPD08" ","
 "OPPD09" "," "OPPD10" "," "OPPD12" ","
 "OPNQ03" "," "OPPS17" 
 ;
 end;
 put HOSPID 13. "," BWHTCAT 3. "," AGEDCAT 3. "," PAGECAT 3. "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPPD01 TPPD05 TPPD08-TPPD10 TPPD12 TPNQ03 TPPS17) (7.0 ",")
  ","
 (PPPD01 PPPD05 PPPD08-PPPD10 PPPD12 PPNQ03 PPPS17) (13.0 ",")
 ","
 (OPPD01 OPPD05 OPPD08-OPPD10 OPPD12 OPNQ03 OPPS17) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ;
 run;

 %END;

 %MEND TEXTP1;

 %TEXTP1;
