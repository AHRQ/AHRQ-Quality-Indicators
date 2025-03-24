*================== Program: PSI_HOSP_COMPOSITE.SAS =====================;
*
*  DESCRIPTION:
*         Constructs a Patient Safety and Adverse Events Composite 
*         measure based on user defined weights.  The default weights are the
*         National Quality Forum endorsed 10 component harm adjusted
*         numerator weights.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*  USER NOTE:  Requires output from PSI_HOSP_RISKADJ.SAS
*
*========================================================================;
title  'PROGRAM PSI_HOSP_COMPOSITE';

%MACRO PSC;

*Do not calculate composite measures if certain flags are set in the CONTROL program;
%if &MDC_PROVIDED. = 0 or &PRDAY. = 0 %then %do;
data OUTHCOMP.&OUTFILE_COMP.;
  HOSPID=.; COMP1=.; COMP1VAR=.; COMP1SE=.; COMP1WHT=.; COMP1LB=.; COMP1UB=.;
  RPPS03=.; RPPS06=.; RPPS08=.; RPPS09=.; RPPS10=.; RPPS11=.; RPPS12=.; RPPS13=.; RPPS14=.; RPPS15=.; 
  VPPS03=.; VPPS06=.; VPPS08=.; VPPS09=.; VPPS10=.; VPPS11=.; VPPS12=.; VPPS13=.; VPPS14=.; VPPS15=.; 
  APPS03=.; APPS06=.; APPS08=.; APPS09=.; APPS10=.; APPS11=.; APPS12=.; APPS13=.; APPS14=.; APPS15=.; 
  PPPS03=.; PPPS06=.; PPPS08=.; PPPS09=.; PPPS10=.; PPPS11=.; PPPS12=.; PPPS13=.; PPPS14=.; PPPS15=.; 
  WPPS03=.; WPPS06=.; WPPS08=.; WPPS09=.; WPPS10=.; WPPS11=.; WPPS12=.; WPPS13=.; WPPS14=.; WPPS15=.; 
  REFPS03=.; REFPS06=.; REFPS08=.; REFPS09=.; REFPS10=.; REFPS11=.; REFPS12=.; REFPS13=.; REFPS14=.; REFPS15=.;
run;
%end;

%else %do;

%LET ARRY = ARRYP3;

*===================================================================;
* Import PSI Composite Weights                                  --- ;
* Weights sum to 1.0                                            --- ;
*===================================================================;
%include MacLib(PSI_HOSP_Composite_Wt_v2024.sas);
%setweights;

*===================================================================;
*  COMPUTE COMPOSITE                                            --- ;
*===================================================================;

data OUTHCOMP.&OUTFILE_COMP.  (keep=HOSPID COMP1 COMP1VAR COMP1SE COMP1WHT COMP1LB COMP1UB 
                                    RPPS03 RPPS06 RPPS08 RPPS09 RPPS10 RPPS11 RPPS12 RPPS13 RPPS14 RPPS15 
                                    VPPS03 VPPS06 VPPS08 VPPS09 VPPS10 VPPS11 VPPS12 VPPS13 VPPS14 VPPS15 
                                    APPS03 APPS06 APPS08 APPS09 APPS10 APPS11 APPS12 APPS13 APPS14 APPS15 
                                    PPPS03 PPPS06 PPPS08 PPPS09 PPPS10 PPPS11 PPPS12 PPPS13 PPPS14 PPPS15 
                                    WPPS03 WPPS06 WPPS08 WPPS09 WPPS10 WPPS11 WPPS12 WPPS13 WPPS14 WPPS15 
                                    REFPS03 REFPS06 REFPS08 REFPS09 REFPS10 REFPS11 REFPS12 REFPS13 REFPS14 REFPS15);
attrib 
  HOSPID               label='Hospital Identification Number'
  COMP1    format=13.7 label='PSI 90 Patient Safety and Adverse Events Composite'
  COMP1VAR format=13.7 label='PSI 90 Patient Safety and Adverse Events Composite (Variance)'
  COMP1SE  format=13.7 label='PSI 90 Patient Safety and Adverse Events Composite (SE)'
  COMP1WHT format=13.7 label='PSI 90 Patient Safety and Adverse Events Composite (Weighted Denominator)'
  COMP1LB  format=13.7 label='PSI 90 Patient Safety and Adverse Events Composite (Lower CL)'
  COMP1UB  format=13.7 label='PSI 90 Patient Safety and Adverse Events Composite (Upper CL)'
  ;

%macro label_qis(qi_num=, qi_name=);
  attrib VPPS&qi_num.  format=13.7 label="&qi_name. (Noise Variance)"
         APPS&qi_num.  format=13.7 label="&qi_name. (Reliability Weight)"
         WPPS&qi_num.  format=13.7 label="&qi_name. (Component Weight)"
         REFPS&qi_num. format=13.7 label="&qi_name. (Reference Population Rate)"
  ;
%mend label_qis;

%label_qis(qi_num=03, qi_name=PSI 03 Pressure Ulcer Rate);
%label_qis(qi_num=06, qi_name=PSI 06 Iatrogenic Pneumothorax Rate);
%label_qis(qi_num=08, qi_name=PSI 08 In-Hospital Fall-Associated Fracture Rate);
%label_qis(qi_num=09, qi_name=PSI 09 Postoperative Hemorrhage or Hematoma Rate);
%label_qis(qi_num=10, qi_name=PSI 10 Postoperative Acute Kidney Injury Requiring Dialysis Rate);
%label_qis(qi_num=11, qi_name=PSI 11 Postoperative Respiratory Failure Rate);
%label_qis(qi_num=12, qi_name=PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate);
%label_qis(qi_num=13, qi_name=PSI 13 Postoperative Sepsis Rate);
%label_qis(qi_num=14, qi_name=PSI 14 Postoperative Wound Dehiscence Rate);
%label_qis(qi_num=15, qi_name=PSI 15 Abdominopelvic Accidental Puncture or Laceration Rate);

set OUTHRISK.&OUTFILE_HOSPRISK.;

if _TYPE_ in (0,16);

* --- Load Component Reference Rate and Signal Variance Arrays --- ;
%include MacLib(&PSCOMPRR.);

array ARRY4{10}
   RPPS03 RPPS06 RPPS08 RPPS09 RPPS10
   RPPS11 RPPS12 RPPS13 RPPS14 RPPS15
;

array ARRY6{10}
   VPPS03 VPPS06 VPPS08 VPPS09 VPPS10
   VPPS11 VPPS12 VPPS13 VPPS14 VPPS15
;

array ARRY7{10}
   APPS03 APPS06 APPS08 APPS09 APPS10
   APPS11 APPS12 APPS13 APPS14 APPS15
;

array ARRY12{10} 
   WPPS03 WPPS06 WPPS08 WPPS09 WPPS10
   WPPS11 WPPS12 WPPS13 WPPS14 WPPS15
   (&W03. &W06. &W08. &W09. &W10.
    &W11. &W12. &W13. &W14. &W15.)
;

array ARRY13{10}
   PPPS03 PPPS06 PPPS08 PPPS09 PPPS10
   PPPS11 PPPS12 PPPS13 PPPS14 PPPS15
;

do I = 1 TO 10;
   if ARRY13(I) GE 3 then do;
      ARRY6(I) = ARRY6(I) / (&ARRY.(I) * &ARRY.(I));
      do J = I TO 10;
         IDX = ARRY10(I,J);
         if I = J then ARRY7(I) = ARRY1(IDX) / (ARRY1(IDX) + ARRY6(I));
      end;
   end;
   else do;
      do J = I TO 10;
         IDX = ARRY10(I,J);
         if I = J then ARRY7(I) = 0;
      end;
   end;
end;

COMP1    = 0;
COMP1VAR = 0;
COMP1SE  = 0;
COMP1WHT = 0;

do I = 1 TO 10;
   if ARRY13(I) GE 3 then do;
      COMP1 = COMP1 + (ARRY12(I) * (((ARRY4(I) / &ARRY.(I)) * ARRY7(I)) + (1 - ARRY7(I))));
      COMP1WHT = COMP1WHT + (ARRY12(I) * ARRY13(I));
   end;
   else do;
      COMP1 = COMP1 + ARRY12(I);
      COMP1WHT = COMP1WHT + 0;
   end;
   do J = I TO 10;
      IDX = ARRY10(I,J);
      if I = J then COMP1VAR = COMP1VAR
      + (ARRY12(I) * (ARRY1(IDX) * (1 - ARRY7(I))) * ARRY12(J));
      else COMP1VAR = COMP1VAR
      + (ARRY12(I) * (ARRY1(IDX) * (1 - ARRY7(I)) * (1 - ARRY7(J))) * ARRY12(J));
   end;
end;

COMP1SE  = SQRT(COMP1VAR);
COMP1LB  = COMP1 - 1.96* COMP1SE;
COMP1UB  = COMP1 + 1.96* COMP1SE;


run;

%END;

%LET DSID=%SYSFUNC(OPEN(OUTHCOMP.&OUTFILE_COMP.));
%IF &dsid. %THEN %LET DNUM=%SYSFUNC(ATTRN(&dsid,NOBS));
%ELSE %LET DNUM=0;
%LET DRC=%SYSFUNC(CLOSE(&dsid));

%IF &DNUM = 0 %THEN %DO;
data OUTHCOMP.&OUTFILE_COMP.;
  HOSPID=.; COMP1=.; COMP1VAR=.; COMP1SE=.; COMP1WHT=.; COMP1LB=.; COMP1UB=.;
  RPPS03=.; RPPS06=.; RPPS08=.; RPPS09=.; RPPS10=.; RPPS11=.; RPPS12=.; RPPS13=.; RPPS14=.; RPPS15=.; 
  VPPS03=.; VPPS06=.; VPPS08=.; VPPS09=.; VPPS10=.; VPPS11=.; VPPS12=.; VPPS13=.; VPPS14=.; VPPS15=.; 
  APPS03=.; APPS06=.; APPS08=.; APPS09=.; APPS10=.; APPS11=.; APPS12=.; APPS13=.; APPS14=.; APPS15=.; 
  PPPS03=.; PPPS06=.; PPPS08=.; PPPS09=.; PPPS10=.; PPPS11=.; PPPS12=.; PPPS13=.; PPPS14=.; PPPS15=.; 
  WPPS03=.; WPPS06=.; WPPS08=.; WPPS09=.; WPPS10=.; WPPS11=.; WPPS12=.; WPPS13=.; WPPS14=.; WPPS15=.; 
  REFPS03=.; REFPS06=.; REFPS08=.; REFPS09=.; REFPS10=.; REFPS11=.; REFPS12=.; REFPS13=.; REFPS14=.; REFPS15=.;
run;
%END;

%MEND;
%PSC;


* -------------------------------------------------------------- ;
* ---        CONTENTS AND MEANS OF COMPOSITE MEASURES        --- ;
* -------------------------------------------------------------- ;
proc Contents data=OUTHCOMP.&OUTFILE_COMP. position;
   title2  'CONTENTS OF PATIENT SAFETY COMPOSITE FILE';
run;
 
proc Means data=OUTHCOMP.&OUTFILE_COMP. n mean;
   var COMP1 COMP1VAR COMP1SE COMP1WHT;
   title2  'SUMMARY OF PATIENT SAFETY COMPOSITE INDICATORS';
run; quit;

* -------------------------------------------------------------- ;
* --- PRINT COMPOSITE MEASURES AND COMPONENTS                --- ;
* -------------------------------------------------------------- ;
%MACRO PRT2;

%IF &PRINT. = 1 %THEN %DO;

 proc  Print data=OUTHCOMP.&OUTFILE_COMP. label split='*';
 var    HOSPID COMP1 COMP1VAR COMP1SE COMP1WHT COMP1LB COMP1UB ;
 format COMP1 COMP1VAR COMP1SE COMP1WHT COMP1LB COMP1UB 8.6;
 title2 'PATIENT SAFETY AND ADVERSE EVENTS COMPOSITE INDICATORS';
 run;

 %MACRO PRT(PS,TEXT);
 proc  Print data=OUTHCOMP.&OUTFILE_COMP. label split='*';
 var   HOSPID RPPS&PS VPPS&PS. APPS&PS PPPS&PS. WPPS&PS. REFPS&PS.;
 label RPPS&PS. = "RPPS&PS.*(Risk-adjusted rate)"
       VPPS&PS. = "VPPS&PS.*(Noise variance)"
       APPS&PS. = "APPS&PS.*(Reliability weight)"
       PPPS&PS. = "PPPS&PS.*(Population)"
       WPPS&PS. = "WPPS&PS.*(Component weight)"
       REFPS&PS. = "REFPS&PS.*(Reference population rate)"
       ;
 format PPPS&PS. 13.0 RPPS&PS. VPPS&PS. APPS&PS. WPPS&PS. REFPS&PS. 8.6;
 title2 "Indicator &PS.: &TEXT";
 run;
 %MEND PRT;

 %PRT(03,Pressure Ulcer Rate);
 %PRT(06,Iatrogenic Pneumothorax Rate);
 %PRT(08,In-Hospital Fall-Associated Fracture Rate);
 %PRT(09,Postoperative Hemorrhage or Hematoma Rate);
 %PRT(10,Postoperative Acute Kidney Injury Requiring Dialysis Rate);
 %PRT(11,Postoperative Respiratory Failure Rate);
 %PRT(12,Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate);
 %PRT(13,Postoperative Sepsis Rate);
 %PRT(14,Postoperative Wound Dehiscence Rate);
 %PRT(15,Abdominopelvic Accidental Puncture or Laceration Rate);

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
      ARRAY RATES RPPS: REFPS:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*1000;	
	  end;
  %END;
	
%mend scale_rates;

%IF &TXTCOMP. = 1 %THEN %DO;
 data _NULL_;
 set OUTHCOMP.&OUTFILE_COMP.;
 %scale_rates;
 file PSTXTCMP lrecl=2000 ;
 if _N_=1 then do;
  put "AHRQ SAS QI v2024 &OUTFILE_COMP data set created with the following CONTROL options:";
  put "&&Calibration_OE_to_ref_pop&Calibration_OE_to_ref_pop. (Calibration_OE_to_ref_pop = &Calibration_OE_to_ref_pop)";
  put "&&MDC_PROVIDED&MDC_PROVIDED. (MDC_PROVIDED = &MDC_PROVIDED)";
  put "&&PRDAY&PRDAY. (PRDAY = &PRDAY)";
  put "Number of diagnoses evaluated = &NDX";
  put "Number of procedures evaluated = &NPR";
  put "Review the CONTROL program for more information about these options.";
  put ;
  put "HOSP ID" "," "COMP1" "," "COMP1VAR" "," "COMP1SE" "," "COMP1WHT" "," " COMP1LB" "," "COMP1UB" "," 
      "RPPS03" "," "RPPS06" "," "RPPS08" "," "RPPS09" "," "RPPS10" "," "RPPS11" "," "RPPS12" "," "RPPS13" "," "RPPS14" "," "RPPS15" "," 
      "VPPS03" "," "VPPS06" "," "VPPS08" "," "VPPS09" "," "VPPS10" "," "VPPS11" "," "VPPS12" "," "VPPS13" "," "VPPS14" "," "VPPS15" "," 
      "APPS03" "," "APPS06" "," "APPS08" "," "APPS09" "," "APPS10" "," "APPS11" "," "APPS12" "," "APPS13" "," "APPS14" "," "APPS15" "," 
      "PPPS03" "," "PPPS06" "," "PPPS08" "," "PPPS09" "," "PPPS10" "," "PPPS11" "," "PPPS12" "," "PPPS13" "," "PPPS14" "," "PPPS15" "," 
      "WPPS03" "," "WPPS06" "," "WPPS08" "," "WPPS09" "," "WPPS10" "," "WPPS11" "," "WPPS12" "," "WPPS13" "," "WPPS14" "," "WPPS15" ","
      "REFPS03" "," "REFPS06" "," "REFPS08" "," "REFPS09" "," "REFPS10" "," "REFPS11" "," "REFPS12" "," "REFPS13" "," "REFPS14" "," "REFPS15"
      ;
 end;

 put HOSPID 13. "," COMP1 12.10 "," COMP1VAR 12.10 "," COMP1SE 12.10 "," COMP1WHT 12.10 "," COMP1LB 12.10 ","  COMP1UB 12.10 "," 
    (RPPS03 RPPS06 RPPS08-RPPS15) 
	%if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");  ","
    (VPPS03 VPPS06 VPPS08-VPPS15) (12.10 ",")  ","
    (APPS03 APPS06 APPS08-APPS15) (12.10 ",")  ","
    (PPPS03 PPPS06 PPPS08-PPPS15) (13.0 ",")   ","
    (WPPS03 WPPS06 WPPS08-WPPS15) (12.10 ",")  ","
    (REFPS03 REFPS06 REFPS08-REFPS15) 
	%if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
    ;
 run;

%END;

%MEND TEXT;

%TEXT;
