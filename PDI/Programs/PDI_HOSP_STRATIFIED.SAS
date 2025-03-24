*====================== Program: PDI_HOSP_STRATIFIED.SAS =====================;
*
*  DESCRIPTION:
*         Calculate observed rates for
*         Pediatric Quality Indicators across stratifiers.
*         Program uses HOSPID, GPPD08, GPPD10 and
*         GPPD12 from PDI_ALL_MEASURES.SAS program.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*=============================================================================;

 title2 'PROGRAM: PDI_HOSP_STRATIFIED';
 title3 'AHRQ PEDIATRIC QUALITY INDICATORS: CALCULATE STRATIFIED OBSERVED HOSPITAL RATES';

* ----------------------------------------------------------------- ;
* --- HOSPITAL LEVEL MEANS ON PEDIATRIC DATA FILE  ---------------- ;
* ----------------------------------------------------------------- ;
* ----------------------------------------------------------------- ;
* --- PEDIATRIC QUALITY INDICATOR (PDI) NAMING CONVENTION:      --- ;
* --- THE FIRST LETTER IDENTIFIES THE PEDIATRIC QUALITY         --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                        --- ;
* ---           (T) NUMERATOR ("TOP") - FROM PDI_ALL_MEASURES   --- ;
* ---           (P) DENOMINATOR ("POPULATION")                  --- ;
* ---           (O) OBSERVED RATES (T/P)                        --- ;
* ---           (G) MEASURE SPECIFIC STRATIFICATION ("GROUP")   --- ;
* ---               FROM PDI_ALL_MEASURES                       --- ;
* --- THE SECOND LETTER IDENTIFIES THE INDICATOR AS A HOSPITAL  --- ;
* --- (P) LEVEL INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS  --- ;
* --- 'PD'. THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.       --- ;
* ----------------------------------------------------------------- ;

 proc   SUMMARY data=OUTMSR.&OUTFILE_MEAS. missing;
 class  HOSPID GPPD08 GPPD10 GPPD12;
 var    TPPD08 TPPD10 TPPD12;
 output out=&OUTFILE_STRAT.
        sum (TPPD08 TPPD10 TPPD12)=
        n (TPPD08 TPPD10 TPPD12)=PPPD08 PPPD10 PPPD12
        mean(TPPD08 TPPD10 TPPD12)=OPPD08 OPPD10 OPPD12;
 run;

 proc   Sort data=&OUTFILE_STRAT.;
 by HOSPID GPPD08 GPPD10 GPPD12;
 run;

 data   OUTST.&OUTFILE_STRAT.;
 set    &OUTFILE_STRAT. (where=(_TYPE_ in (1,2,4,8,9,10,12)));

 array PPPD PPPD08 PPPD10 PPPD12;

 do over PPPD;
    if PPPD eq 0 then PPPD = .;
 end;

 %macro label_qis(qi_num=, qi_name=);
   label 
   TP&qi_num. = "&qi_name. (Numerator)"
   PP&qi_num. = "&qi_name. (Population)"
   OP&qi_num. = "&qi_name. (Observed rate)"
   GP&qi_num. = "&qi_name. (Stratified)"
   ;
   
 %mend label_qis;
 %label_qis(qi_num=PD08, qi_name=PDI 08 Postoperative Hemorrhage or Hematoma Rate);
 %label_qis(qi_num=PD10, qi_name=PDI 10 Postoperative Sepsis Rate);
 %label_qis(qi_num=PD12, qi_name=PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate);

label
 _TYPE_ = 'Stratification Level'
;
 drop _FREQ_ ;

 run;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF HOSPITAL STRATIFIED OUTPUT FILE ---- ;
 * -------------------------------------------------------------- ;

 proc   Contents data=OUTST.&OUTFILE_STRAT. position;
 run;

 %MACRO MNS(PD,T);

 proc   MEANS data=OUTST.&OUTFILE_STRAT. (where=(_TYPE_ in (&T.))) n nmiss min max mean sum nolabels;
 title4 "SUMMARY OF HOSPITAL-LEVEL RATES, PDI &PD.";
 class GPPD&PD.;
 var TPPD&PD. PPPD&PD. OPPD&PD.;
 run;

 %MEND;

 %MNS(08,12);
 %MNS(10,10);
 %MNS(12,9);

 * ---------------------------------------------------------- ;
 * --- PRINT HOSPITAL STRATIFIED FILE TO SAS OUTPUT  -------- ;
 * ---------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PD,TEXT,T1,T2);

 proc   Print data=OUTST.&OUTFILE_STRAT. label SPLIT='*';
 var    HOSPID GPPD&PD. TPPD&PD. PPPD&PD. OPPD&PD. ;
 label HOSPID  = "HOSPID"
       GPPD&PD.   = "GPPD&PD.*(Stratif)"
       TPPD&PD.   = "TPPD&PD.*(Numerator)"
       PPPD&PD.   = "PPPD&PD.*(Population)"
       OPPD&PD.   = "OPPD&PD.*(Observed rate)"
       ;
 format TPPD&PD. PPPD&PD. 13.0 OPPD&PD. 8.6;
 format GPPD&PD. 3.0; 
 title4 "Indicator &PD.: &TEXT";
 where _TYPE_ in (&T1.,&T2.) and GPPD&PD. NE .;
 run;

 %MEND PRT;


 %PRT(08,Postoperative Hemorrhage or Hematoma Rate,4,12);
 %PRT(10,Postoperative Sepsis Rate,2,10);
 %PRT(12,Central Venous Catheter-Related Blood Stream Infection Rate,1,9);

 %END;

 %MEND PRT2;

 %PRT2;

 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS                           --- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXTST;
 
 %macro scale_rates;
   
   %IF &SCALE_RATES = 1 %THEN %DO;
      ARRAY RATES OPPD:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*1000;	
	  end;
	%END;
	
 %mend scale_rates;

 %IF &TXTSTRAT. = 1  %THEN %DO;

 data _NULL_;
   set OUTST.&OUTFILE_STRAT.;
   %scale_rates;
 file PDTXTSTR lrecl=2000;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_STRAT data set created with the following CONTROL options:";
 put "&&Calibration_OE_to_ref_pop&Calibration_OE_to_ref_pop. (Calibration_OE_to_ref_pop = &Calibration_OE_to_ref_pop)";
 put "&&MDC_PROVIDED&MDC_PROVIDED. (MDC_PROVIDED = &MDC_PROVIDED)";
 put "&&PRDAY&PRDAY. (PRDAY = &PRDAY)";
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "PDI" "," "HOSP ID" "," "Stratifier" "," "Numerator" "," "Denominator" "," "Rate" "," "Type";
 end;
 
 if _TYPE_ in (4,12) and GPPD08 NE . then 
 put "08 ," HOSPID 13. "," GPPD08 3. "," TPPD08 7.0 "," PPPD08 13.2 "," OPPD08 %if &SCALE_RATES = 1 %then 12.2 ","; %else 12.10 "," ; _TYPE_ 2.;
 if _TYPE_ in (2,10) and GPPD10 NE . then 
 put "10 ," HOSPID 13. "," GPPD10 3. "," TPPD10 7.0 "," PPPD10 13.2 "," OPPD10 %if &SCALE_RATES = 1 %then 12.2 ","; %else 12.10 "," ; _TYPE_ 2.;
 if _TYPE_ in (1,9) and GPPD12 NE . then 
 put "12 ," HOSPID 13. "," GPPD12 3. "," TPPD12 7.0 "," PPPD12 13.2 "," OPPD12 %if &SCALE_RATES = 1 %then 12.2 ","; %else 12.10 "," ; _TYPE_ 2.;
 ;
 run;

 %END;

 %MEND TEXTST;

 %TEXTST;
