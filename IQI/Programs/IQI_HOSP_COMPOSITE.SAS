*================= Program: IQI_HOSP_COMPOSITE.SAS ======================;
*
*  DESCRIPTION:
*         Constructs Mortality for Selected Procedures (IQI 90) and
*         Mortality for Selected Conditions (IQI 91) Composite Measures
*         based on user defined weights.
*         (Default National Quality Forum Weights supplied.)
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*  USER NOTE:  Requires output from IQI_HOSP_RISKADJ.SAS
*              BEFORE running this program.
*
*========================================================================;

%let OUTSASC3 = IQI_HOSP_Composite_Arrays_v2024.sas ;

*If supplying weights, update array in IQI_HOSP_Composite_Wt_v2024.sas file;
%let IQIWTS = IQI_HOSP_Composite_Wt_v2024.sas ;

%MACRO IQC;

*Do not calculate composite measures if certain flags are set in the CONTROL program;
%if &MDC_PROVIDED. = 0  or &PRDAY. = 0 %then %do;
data OUTHCOMP.&OUTFILE_COMP.;
  HOSPID=.;
  IQC90=.; IQC90VAR=.; IQC90SE=.; IQC90WHT=.; IQC90LB=.; IQC90UB=.; IQC91=.; IQC91VAR=.; IQC91SE=.; IQC91WHT=.; IQC91LB=.; IQC91UB=.;
  RPIQ08=.; RPIQ09=.; RPIQ11=.; RPIQ12=.; RPIQ30=.; RPIQ31=.; RPIQ15=.; RPIQ16=.; RPIQ17=.; RPIQ18=.; RPIQ19=.; RPIQ20=.;
  VPIQ08=.; VPIQ09=.; VPIQ11=.; VPIQ12=.; VPIQ30=.; VPIQ31=.; VPIQ15=.; VPIQ16=.; VPIQ17=.; VPIQ18=.; VPIQ19=.; VPIQ20=.; 
  APIQ08=.; APIQ09=.; APIQ11=.; APIQ12=.; APIQ30=.; APIQ31=.; APIQ15=.; APIQ16=.; APIQ17=.; APIQ18=.; APIQ19=.; APIQ20=.;
  PPIQ08=.; PPIQ09=.; PPIQ11=.; PPIQ12=.; PPIQ30=.; PPIQ31=.; PPIQ15=.; PPIQ16=.; PPIQ17=.; PPIQ18=.; PPIQ19=.; PPIQ20=.;
  WPIQ08=.; WPIQ09=.; WPIQ11=.; WPIQ12=.; WPIQ30=.; WPIQ31=.; WPIQ15=.; WPIQ16=.; WPIQ17=.; WPIQ18=.; WPIQ19=.; WPIQ20=.;
  REFIQ08=.; REFIQ09=.; REFIQ11=.; REFIQ12=.; REFIQ30=.; REFIQ31=.; REFIQ15=.; REFIQ16=.; REFIQ17=.; REFIQ18=.; REFIQ19=.; REFIQ20=.;
run;
%end;


%else %do;

   %LET ARRY = ARRYP3;

*===================================================================;
*  COMPUTE COMPOSITE                                            --- ;
*===================================================================;

data OUTHCOMP.&OUTFILE_COMP.(keep=HOSPID IQC90 IQC90VAR IQC90SE IQC90WHT IQC90LB IQC90UB IQC91 IQC91VAR IQC91SE IQC91WHT IQC91LB IQC91UB
                                  RPIQ08 RPIQ09 RPIQ11 RPIQ12 RPIQ30 RPIQ31 RPIQ15 RPIQ16 RPIQ17 RPIQ18 RPIQ19 RPIQ20
                                  VPIQ08 VPIQ09 VPIQ11 VPIQ12 VPIQ30 VPIQ31 VPIQ15 VPIQ16 VPIQ17 VPIQ18 VPIQ19 VPIQ20 
                                  APIQ08 APIQ09 APIQ11 APIQ12 APIQ30 APIQ31 APIQ15 APIQ16 APIQ17 APIQ18 APIQ19 APIQ20
                                  PPIQ08 PPIQ09 PPIQ11 PPIQ12 PPIQ30 PPIQ31 PPIQ15 PPIQ16 PPIQ17 PPIQ18 PPIQ19 PPIQ20
                                  WPIQ08 WPIQ09 WPIQ11 WPIQ12 WPIQ30 WPIQ31 WPIQ15 WPIQ16 WPIQ17 WPIQ18 WPIQ19 WPIQ20
                                  REFIQ08 REFIQ09 REFIQ11 REFIQ12 REFIQ30 REFIQ31 REFIQ15 REFIQ16 REFIQ17 REFIQ18 REFIQ19 REFIQ20
                             );
attrib
  HOSPID               label= 'Hospital Identification Number'
  IQC90    format=13.7 label='IQI 90 Mortality for Selected Inpatient Procedures'
  IQC90VAR format=13.7 label='IQI 90 Mortality for Selected Inpatient Procedures (Variance)'
  IQC90SE  format=13.7 label='IQI 90 Mortality for Selected Inpatient Procedures (SE)'
  IQC90WHT format=13.7 label='IQI 90 Mortality for Selected Inpatient Procedures (Weighted Denominator)'
  IQC90LB  format=13.7 label='IQI 90 Mortality for Selected Inpatient Procedures (Lower CL)'
  IQC90UB  format=13.7 label='IQI 90 Mortality for Selected Inpatient Procedures (Upper CL)'
  IQC91    format=13.7 label='IQI 91 Mortality for Selected Inpatient Conditions'
  IQC91VAR format=13.7 label='IQI 91 Mortality for Selected Inpatient Conditions (Variance)'
  IQC91SE  format=13.7 label='IQI 91 Mortality for Selected Inpatient Conditions (SE)'
  IQC91WHT format=13.7 label='IQI 91 Mortality for Selected Inpatient Conditions (Weighted Denominator)'
  IQC91LB  format=13.7 label='IQI 91 Mortality for Selected Inpatient Conditions (Lower CL)'
  IQC91UB  format=13.7 label='IQI 91 Mortality for Selected Inpatient Conditions (Upper CL)'
  ;

%macro label_qis(qi_num=, qi_name=);
  attrib VPIQ&qi_num.  format=13.7 label="&qi_name. (Noise Variance)"
         APIQ&qi_num.  format=13.7 label="&qi_name. (Reliability Weight)"
         WPIQ&qi_num.  format=13.7 label="&qi_name. (Component Weight)"
         REFIQ&qi_num. format=13.7 label="&qi_name. (Reference Population Rate)"
  ;
%mend label_qis;

%label_qis(qi_num=08, qi_name=IQI 08 Esophageal Resection Mortality Rate);
%label_qis(qi_num=09, qi_name=IQI 09 Pancreatic Resection Mortality Rate);
%label_qis(qi_num=11, qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate);
%label_qis(qi_num=12, qi_name=IQI 12 Coronary Artery Bypass Graft (CABG) Mortality Rate);
%label_qis(qi_num=15, qi_name=IQI 15 Acute Myocardial Infarction (AMI) Mortality Rate);
%label_qis(qi_num=16, qi_name=IQI 16 Heart Failure Mortality Rate);
%label_qis(qi_num=17, qi_name=IQI 17 Acute Stroke Mortality Rate);
%label_qis(qi_num=18, qi_name=IQI 18 Gastrointestinal Hemorrhage Mortality Rate);
%label_qis(qi_num=19, qi_name=IQI 19 Hip Fracture Mortality Rate);
%label_qis(qi_num=20, qi_name=IQI 20 Pneumonia Mortality Rate);
%label_qis(qi_num=30, qi_name=IQI 30 Percutaneous Coronary Intervention (PCI) Mortality Rate);
%label_qis(qi_num=31, qi_name=IQI 31 Carotid Endarterectomy Mortality Rate);

set OUTHRISK.&OUTFILE_HOSPRISK.;

if _TYPE_ in (0,16);

%include MacLib(&OUTSASC3.);

array ARRY4{12}
   RPIQ08 RPIQ09 RPIQ11 RPIQ12 RPIQ30 RPIQ31
   RPIQ15 RPIQ16 RPIQ17 RPIQ18 RPIQ19 RPIQ20
;

array ARRY6{12}
   VPIQ08 VPIQ09 VPIQ11 VPIQ12 VPIQ30 VPIQ31
   VPIQ15 VPIQ16 VPIQ17 VPIQ18 VPIQ19 VPIQ20
;

array ARRY7{12}
   APIQ08 APIQ09 APIQ11 APIQ12 APIQ30 APIQ31
   APIQ15 APIQ16 APIQ17 APIQ18 APIQ19 APIQ20
;

%include MacLib(&IQIWTS.);

array ARRY13{12}
   PPIQ08 PPIQ09 PPIQ11 PPIQ12 PPIQ30 PPIQ31
   PPIQ15 PPIQ16 PPIQ17 PPIQ18 PPIQ19 PPIQ20
;

do I = 1 TO 6;
   if ARRY13(I) GE 3 then do;
      ARRY6(I) = ARRY6(I) / (&ARRY.(I) * &ARRY.(I));
      do J = I TO 6;
         IDX = ARRY11(I,J);
         if I = J then ARRY7(I) = ARRY1(IDX) / (ARRY1(IDX) + ARRY6(I));
      end;
   end;
   else do;
      do J = I TO 6;
         IDX = ARRY11(I,J);
         if I = J then ARRY7(I) = 0;
      end;
   end;
end;

do I = 7 TO 12;
   if ARRY13(I) GE 3 then do;
      ARRY6(I) = ARRY6(I) / (&ARRY.(I) * &ARRY.(I));
      do J = I TO 12;
         IDX = ARRY11(I-6,J-6);
         if I = J then ARRY7(I) = ARRY3(IDX) / (ARRY3(IDX) + ARRY6(I));
      end;
   end;
   else do;
      do J = I TO 12;
         IDX = ARRY11(I-6,J-6);
         if I = J then ARRY7(I) = 0;
      end;
   end;
end;

IQC90    = 0;
IQC90VAR = 0;
IQC90SE  = 0;
IQC90WHT = 0;

do I = 1 TO 6;
   if ARRY13(I) GE 3 then do;
      IQC90 = IQC90 + (ARRY12(I) * (((ARRY4(I) / &ARRY.(I)) * ARRY7(I)) + (1 - ARRY7(I))));
      IQC90WHT = IQC90WHT + (ARRY12(I) * ARRY13(I));
   end;
   else do;
      IQC90 = IQC90 + ARRY12(I);
      IQC90WHT = IQC90WHT + 0;
   end;
   do J = I TO 6;
      IDX = ARRY11(I,J);
      if I = J then IQC90VAR = IQC90VAR
      + (ARRY12(I) * (ARRY1(IDX) * (1 - ARRY7(I))) * ARRY12(J));
      else IQC90VAR = IQC90VAR
      + (ARRY12(I) * (ARRY1(IDX) * (1 - ARRY7(I)) * (1 - ARRY7(J))) * ARRY12(J));
   end;
end;

IQC91    = 0;
IQC91VAR = 0;
IQC91SE  = 0;
IQC91WHT = 0;

do I = 7 TO 12;
   if ARRY13(I) GE 3 then do;
      IQC91 = IQC91 + (ARRY12(I) * (((ARRY4(I) / &ARRY.(I)) * ARRY7(I)) + (1 - ARRY7(I))));
      IQC91WHT = IQC91WHT + (ARRY12(I) * ARRY13(I));
   end;
   else do;
      IQC91 = IQC91 + ARRY12(I);
      IQC91WHT = IQC91WHT + 0;
   end;
   do J = I TO 12;
      IDX = ARRY11(I-6,J-6);
      if I = J then IQC91VAR = IQC91VAR
      + (ARRY12(I) * (ARRY3(IDX) * (1 - ARRY7(I))) * ARRY12(I));
      else IQC91VAR = IQC91VAR
      + (ARRY12(I) * (ARRY3(IDX) * (1 - ARRY7(I)) * (1 - ARRY7(J))) * ARRY12(J));
   end;
end;

IQC90SE  = SQRT(IQC90VAR);
IQC91SE  = SQRT(IQC91VAR);
IQC90LB  = IQC90 - 1.96* IQC90SE;
IQC90UB  = IQC90 + 1.96* IQC90SE;
IQC91LB  = IQC91 - 1.96* IQC91SE;
IQC91UB  = IQC91 + 1.96* IQC91SE;

run;

%end;

%LET DSID=%SYSFUNC(OPEN(OUTHCOMP.&OUTFILE_COMP.));
%IF &dsid. %THEN %LET DNUM=%SYSFUNC(ATTRN(&dsid,NOBS));
%ELSE %LET DNUM=0;
%LET DRC=%SYSFUNC(CLOSE(&dsid));

%IF &DNUM = 0 %THEN %DO;
data OUTHCOMP.&OUTFILE_COMP.;
  HOSPID=.;
  IQC90=.; IQC90VAR=.; IQC90SE=.; IQC90WHT=.; IQC90LB=.; IQC90UB=.;IQC91=.; IQC91VAR=.; IQC91SE=.; IQC91WHT=.; IQC91LB=.; IQC91UB=.;
  RPIQ08=.; RPIQ09=.; RPIQ11=.; RPIQ12=.; RPIQ30=.; RPIQ31=.; RPIQ15=.; RPIQ16=.; RPIQ17=.; RPIQ18=.; RPIQ19=.; RPIQ20=.;
  VPIQ08=.; VPIQ09=.; VPIQ11=.; VPIQ12=.; VPIQ30=.; VPIQ31=.; VPIQ15=.; VPIQ16=.; VPIQ17=.; VPIQ18=.; VPIQ19=.; VPIQ20=.; 
  APIQ08=.; APIQ09=.; APIQ11=.; APIQ12=.; APIQ30=.; APIQ31=.; APIQ15=.; APIQ16=.; APIQ17=.; APIQ18=.; APIQ19=.; APIQ20=.;
  PPIQ08=.; PPIQ09=.; PPIQ11=.; PPIQ12=.; PPIQ30=.; PPIQ31=.; PPIQ15=.; PPIQ16=.; PPIQ17=.; PPIQ18=.; PPIQ19=.; PPIQ20=.;
  WPIQ08=.; WPIQ09=.; WPIQ11=.; WPIQ12=.; WPIQ30=.; WPIQ31=.; WPIQ15=.; WPIQ16=.; WPIQ17=.; WPIQ18=.; WPIQ19=.; WPIQ20=.;
  REFIQ08=.; REFIQ09=.; REFIQ11=.; REFIQ12=.; REFIQ30=.; REFIQ31=.; REFIQ15=.; REFIQ16=.; REFIQ17=.; REFIQ18=.; REFIQ19=.; REFIQ20=.;
run;
%END;

%MEND;

%IQC;


* -------------------------------------------------------------- ;
* ---        CONTENTS AND MEANS OF COMPOSITE MEASURES        --- ;
* -------------------------------------------------------------- ;
proc Contents data=OUTHCOMP.&OUTFILE_COMP. position;
   title2  'CONTENTS OF INPATIENT QUALITY COMPOSITE FILE';
run;

proc Means data=OUTHCOMP.&OUTFILE_COMP. n mean;
   var IQC90 IQC90VAR IQC90SE IQC90WHT IQC90LB IQC90UB IQC91 IQC91VAR IQC91SE IQC91WHT IQC91LB IQC91UB;
   title2  'SUMMARY OF INPATIENT QUALITY COMPOSITE INDICATORS';
run; quit;


* -------------------------------------------------------------- ;
* --- PRINT COMPOSITE MEASURES AND COMPONENTS                --- ;
* -------------------------------------------------------------- ;
%MACRO PRT2;

%IF &PRINT. = 1 %THEN %DO;

 proc  Print data=OUTHCOMP.&OUTFILE_COMP. label split='*';
 var    HOSPID IQC90 IQC90VAR IQC90SE IQC90WHT IQC90LB IQC90UB IQC91 IQC91VAR IQC91SE IQC91WHT IQC91LB IQC91UB;
 format IQC90 IQC90VAR IQC90SE IQC90WHT IQC90LB IQC90UB IQC91 IQC91VAR IQC91SE IQC91WHT IQC91LB IQC91UB 8.6;
 title2 'INPATIENT QUALITY COMPOSITE INDICATORS';
 run;

%MACRO PRT(IQ,TEXT);
proc  Print data=OUTHCOMP.&OUTFILE_COMP. label split='*';
var   HOSPID RPIQ&IQ VPIQ&IQ. APIQ&IQ PPIQ&IQ. WPIQ&IQ. REFIQ&IQ.;
label RPIQ&IQ.  = "RPIQ&IQ.*(Risk-adjusted rate)"
      VPIQ&IQ.  = "VPIQ&IQ.*(Noise variance)"
      APIQ&IQ.  = "APIQ&IQ.*(Reliability weight)"
      PPIQ&IQ.  = "PPIQ&IQ.*(Population)"
      WPIQ&IQ.  = "WPIQ&IQ.*(Component weight)"
      REFIQ&IQ. = "REFIQ&IQ.*(Reference population rate)"
      ;
format PPIQ&IQ. 13.0 RPIQ&IQ. VPIQ&IQ. APIQ&IQ. WPIQ&IQ. REFIQ&IQ. 8.6;
title2 "Indicator &IQ.: &TEXT";
run;
%MEND PRT;

%PRT(08,Esophageal Resection Mortality Rate);
%PRT(09,Pancreatic Resection Mortality Rate);
%PRT(11,Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate);
%PRT(12,Coronary Artery Bypass Graft (CABG) Mortality Rate);
%PRT(15,Acute Myocardial Infarction (AMI) Mortality Rate);
%PRT(16,Heart Failure Mortality Rate);
%PRT(17,Acute Stroke Mortality Rate);
%PRT(18,Gastrointestinal Hemorrhage Mortality Rate);
%PRT(19,Hip Fracture Mortality Rate);
%PRT(20,Pneumonia Mortality Rate);
%PRT(30,Percutaneous Coronary Intervention (PCI) Mortality Rate);
%PRT(31,Carotid Endarterectomy Mortality Rate);

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
      ARRAY RATES RPIQ: REFIQ:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*1000;	
	  end;
	%END;
	
%mend scale_rates;

%IF &TXTCOMP. = 1 %THEN %DO;
 data _NULL_;
 set OUTHCOMP.&OUTFILE_COMP.;
 %scale_rates;
 file IQTXTCMP lrecl=2000 ;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_HOSPOBS data set created with the following CONTROL options:";
 put "&&Calibration_OE_to_ref_pop&Calibration_OE_to_ref_pop. (Calibration_OE_to_ref_pop = &Calibration_OE_to_ref_pop)";
 put "&&MDC_PROVIDED&MDC_PROVIDED. (MDC_PROVIDED = &MDC_PROVIDED)";
 put "&&PRDAY&PRDAY. (PRDAY = &PRDAY)";
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put  "HOSP ID" "," 
      "IQC90" "," "IQC90VAR" "," "IQC90SE" "," "IQC90WHT" "," "IQC90LB" "," "IQC90UB" "," 
      "IQC91" "," "IQC91VAR" "," "IQC91SE" "," "IQC91WHT" "," "IQC91LB" "," "IQC91UB" ","
      "RPIQ08" "," "RPIQ09" "," "RPIQ11" "," "RPIQ12" "," "RPIQ30" "," "RPIQ31" "," "RPIQ15" "," "RPIQ16" "," "RPIQ17" "," "RPIQ18" "," "RPIQ19" "," "RPIQ20" "," 
      "VPIQ08" "," "VPIQ09" "," "VPIQ11" "," "VPIQ12" "," "VPIQ30" "," "VPIQ31" "," "VPIQ15" "," "VPIQ16" "," "VPIQ17" "," "VPIQ18" "," "VPIQ19" "," "VPIQ20" "," 
      "APIQ08" "," "APIQ09" "," "APIQ11" "," "APIQ12" "," "APIQ30" "," "APIQ31" "," "APIQ15" "," "APIQ16" "," "APIQ17" "," "APIQ18" "," "APIQ19" "," "APIQ20" "," 
      "PPIQ08" "," "PPIQ09" "," "PPIQ11" "," "PPIQ12" "," "PPIQ30" "," "PPIQ31" "," "PPIQ15" "," "PPIQ16" "," "PPIQ17" "," "PPIQ18" "," "PPIQ19" "," "PPIQ20" "," 
      "WPIQ08" "," "WPIQ09" "," "WPIQ11" "," "WPIQ12" "," "WPIQ30" "," "WPIQ31" "," "WPIQ15" "," "WPIQ16" "," "WPIQ17" "," "WPIQ18" "," "WPIQ19" "," "WPIQ20" "," 
      "REFIQ08" "," "REFIQ09" "," "REFIQ11" "," "REFIQ12" "," "REFIQ30" "," "REFIQ31" "," "REFIQ15" "," "REFIQ16" "," "REFIQ17" "," "REFIQ18" "," "REFIQ19" "," "REFIQ20"  
      ;
 end;

 put HOSPID 13. "," 
     IQC90 12.10 "," IQC90VAR 12.10 "," IQC90SE 12.10 "," IQC90WHT 12.10 "," IQC90LB 12.10 ","  IQC90UB 12.10 "," 
     IQC91 12.10 "," IQC91VAR 12.10 "," IQC91SE 12.10 "," IQC91WHT 12.10 "," IQC91LB 12.10 ","  IQC91UB 12.10 "," 
    (RPIQ08 RPIQ09 RPIQ11 RPIQ12 RPIQ30 RPIQ31 RPIQ15-RPIQ20) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); ","
    (VPIQ08 VPIQ09 VPIQ11 VPIQ12 VPIQ30 VPIQ31 VPIQ15-VPIQ20) (12.10 ",")  ","
    (APIQ08 APIQ09 APIQ11 APIQ12 APIQ30 APIQ31 APIQ15-APIQ20) (12.10 ",")  ","
    (PPIQ08 PPIQ09 PPIQ11 PPIQ12 PPIQ30 PPIQ31 PPIQ15-PPIQ20) (13.0 ",")   ","
    (WPIQ08 WPIQ09 WPIQ11 WPIQ12 WPIQ30 WPIQ31 WPIQ15-WPIQ20) (12.10 ",")  ","
    (REFIQ08 REFIQ09 REFIQ11 REFIQ12 REFIQ30 REFIQ31 REFIQ15-REFIQ20) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ","); 
    ;
 run;

%END;

%MEND TEXT;

%TEXT;
