*================== PROGRAM: PSI17_HOSP_OBSERVED.SAS =============================;
*
*  TITLE: HOSPITAL LEVEL OBSERVED RATE FOR AHRQ
*         PATIENT SAFETY INDICATOR - PSI 17: BIRTH TRAUMA RATE - INJURY TO NEONATE
*
*  DESCRIPTION:
*     Calculate observed rate for Patient Safety Indicator 17
*     using numerator and denominator output from PSI17_HOSP_MEASURES.SAS.
*     Output stratified by HOSPID, BWHTCAT, AGECAT, PAGECAT, SEXCAT, PAYCAT, and RACECAT.
*     Variable created by this program is OPPS17
*     This indicator is also included in the Pediatric Quality Indicator module.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*=================================================================================;

title2 'PROGRAM: PSI17_HOSP_OBSERVED';
title3 'AHRQ PATIENT SAFETY INDICATOR 17: CALCULATE OBSERVED HOSPITAL LEVEL RATES';

 * ------------------------------------------------------------------- ;
 * --- HOSPITAL LEVEL SUMMARY USING PSI17_HOSP_MEASURES.SAS OUTPUT --- ;
 * ------------------------------------------------------------------- ;

 data   TEMP0;
   set  OUTMSR.&OUTFILE_MEAS.;
   onewgt=1;
 run;

 * ------------------------------------------------------------------- ;
 * --- PATIENT SAFETY INDICATOR (PSI) NAMING CONVENTION:           --- ;
 * --- THE FIRST LETTER IDENTIFIES THE INDICATOR AS ONE OF         --- ;
 * --- THE FOLLOWING:                                              --- ;
 * ---          (T) NUMERATOR ("TOP")                              --- ;
 * ---          (P) POPULATION ("POP")                             --- ;
 * ---          (O) OBSERVED RATES (T/P)                           --- ;
 * --- THE SECOND LETTER IDENTIFIES THE TYPE OF INDICATOR WITH     --- ;
 * --- 'P' FOR HOSPITAL LEVEL. THE NEXT TWO CHARACTERS ARE         --- ;
 * --- 'PS'. THE LAST TWO DIGITS ARE 17 FOR INDICATOR PSI 17.      --- ;
 * ------------------------------------------------------------------- ;

 proc summary data=TEMP0;
   class  HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT;
   var    TPPS17;
   weight onewgt;
   output out=&OUTFILE_HOSPOBS.
        SUM (TPPS17)=
        SUMWGT (TPPS17)= PPPS17
        MEAN(TPPS17)= OPPS17;
 run;

 proc sort data=&OUTFILE_HOSPOBS.;
   by _TYPE_ HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT;
 run;

 data OUTHOBS.&OUTFILE_HOSPOBS.;
   set  &OUTFILE_HOSPOBS. (WHERE=(_TYPE_ &TYPELVLH))
;

   label
     TPPS17 = 'PSI 17 Birth Trauma Rate - Injury to Neonate (Numerator)'
     PPPS17 = 'PSI 17 Birth Trauma Rate - Injury to Neonate (Population)'
     OPPS17 = 'PSI 17 Birth Trauma Rate - Injury to Neonate (Observed rate)'
 _TYPE_ = 'Stratification Level'
  ;

 label
 HOSPID   = 'Hospital Identification Number'
 ;
 
 drop _FREQ_ ;

 run;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF HOSPITAL OBSERVED MEANS FILE     --- ;
 * -------------------------------------------------------------- ;

 proc contents data=OUTHOBS.&OUTFILE_HOSPOBS. position;
 run;

 proc means data=OUTHOBS.&OUTFILE_HOSPOBS. (where=(_TYPE_ IN (64))) N NMISS MIN MAX MEAN SUM NOLABELS;
   title4 "SUMMARY OF HOSPTIAL-LEVEL RATES (_TYPE_=64)";
 run;

 * -------------------------------------------------------------- ;
 * --- PRINT HOSPITAL OBSERVED MEANS FILE TO SAS OUTPUT       --- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PD,TEXT);

 proc print data=OUTHOBS.&OUTFILE_HOSPOBS. label SPLIT='*';
   var   HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT TP&PD. PP&PD. OP&PD. ;
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
   title4 "Indicator &PD.: &TEXT";
 run;

 %MEND PRT;

 %PRT(PS17,Birth Trauma Rate - Injury to Neonate);

 %END;

 %MEND PRT2;

 %PRT2;

 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS                           --- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXTP1;
 %if &TXTHOBS. = 1  %then %do;
 data _NULL_;
 set OUTHOBS.&OUTFILE_HOSPOBS.;
 %if &SCALE_RATES = 1 %then if not missing(OPPS17) then OPPS17 = OPPS17*1000;;
 file P17TXTHO lrecl=2000 ;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_HOSPOBS data set created with the following CONTROL options:";
 put "&&MDC_PROVIDED&MDC_PROVIDED. (MDC_PROVIDED = &MDC_PROVIDED)";
 put "Output stratification includes TYPELVLH = &TYPELVLH";
 put "Number of diagnoses evaluated = &NDX";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "HOSP ID" "," "AgeDays" "," "Sex" "," "Payer" "," "Race" "," "Type" ","
 "TPPS17" "," "PPPS17" "," "OPPS17" ;
 end;

 put HOSPID 13. "," AGEDCAT 3. "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPPS17) (7.0 ",")
  ","
 (PPPS17) (13.0 ",")
 ","
 (OPPS17) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ;
 run;

 %END;

 %MEND TEXTP1;

 %TEXTP1;
