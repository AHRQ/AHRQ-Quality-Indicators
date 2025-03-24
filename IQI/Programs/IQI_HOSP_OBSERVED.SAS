*===================== Program: IQI_HOSP_OBSERVED.SAS ==============================;
*
*  TITLE: HOSPITAL LEVEL OBSERVED RATES FOR AHRQ INPATIENT QUALITY INDICATORS
*
*  DESCRIPTION:
*         Calculates observed rates for provider level Inpatient Quality Indicators
*         using output from IQI_HOSP_MEASURES.SAS.
*         Output stratified by HOSPID, AGECAT, SEXCAT, PAYCAT, and  RACECAT.
*         Variables created by this program are PPIQXX and OPIQXX
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*===================================================================================;

 title2 'PROGRAM: IQI_HOSP_OBSERVED';
 title3 'AHRQ INPATIENT QUALITY INDICATORS: CALCULATE OBSERVED HOSPITAL LEVEL RATES';

* ------------------------------------------------------------------ ;
* --- HOSPITAL LEVEL MEANS ON IQI_HOSP_MEASURES OUTPUT DATA FILE --- ;
* --- THE TPIQxx VARIABLE IS CREATED IN THE MEAUSURES PROGRAM    --- ;
* --- AND USED TO CALCULATE THE PPIQxx AND OPIQxx VARIABLES.     --- ;
* ------------------------------------------------------------------ ;

* ------------------------------------------------------------------ ;
* --- INPATIENT QUALITY INDICATOR (IQI) NAMING CONVENTION:       --- ;
* --- THE FIRST LETTER IDENTIFIES THE INPATIENT QUALITY          --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                         --- ;
* ---           (T) NUMERATOR ("TOP") - FROM IQI_HOSP_MEASURES   --- ;
* ---           (P) DENOMINATOR ("POPULATION")                   --- ;
* ---           (O) OBSERVED RATES (T/P)                         --- ;
* --- THE SECOND LETTER IDENTIFIES THE IQI AS A HOSPITAL (P)     --- ;
* --- LEVEL INDICATOR. THE NEXT TWO CHARACTERS ARE ALWAYS        --- ;
* --- 'IQ'. THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.        --- ;
* ------------------------------------------------------------------ ;

 proc Summary data=OUTMSR.&OUTFILE_MEAS.;
  class HOSPID AGECAT SEXCAT PAYCAT RACECAT;
  var   TPIQ08 TPIQ09 TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER 
        TPIQ11 TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED
        TPIQ12 TPIQ15-TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE 
        TPIQ18-TPIQ22 TPIQ30-TPIQ31 TPIQ33;
  output out=&OUTFILE_HOSPOBS.
        sum(TPIQ08 TPIQ09 TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER 
            TPIQ11 TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED 
            TPIQ12 TPIQ15-TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE 
            TPIQ18-TPIQ22 TPIQ30-TPIQ31 TPIQ33)=
        n  (TPIQ08 TPIQ09 TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER 
            TPIQ11 TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED 
            TPIQ12 TPIQ15-TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE 
            TPIQ18-TPIQ22 TPIQ30-TPIQ31 TPIQ33)=
            PPIQ08 PPIQ09 PPIQ09_WITH_CANCER PPIQ09_WITHOUT_CANCER 
            PPIQ11 PPIQ11_OPEN_RUPTURED PPIQ11_OPEN_UNRUPTURED PPIQ11_ENDO_RUPTURED PPIQ11_ENDO_UNRUPTURED
            PPIQ12 PPIQ15-PPIQ17 PPIQ17_HEMSTROKE_SUBARACH PPIQ17_HEMSTROKE_INTRACER PPIQ17_ISCHEMSTROKE 
            PPIQ18-PPIQ22 PPIQ30-PPIQ31 PPIQ33
        mean(TPIQ08 TPIQ09 TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER 
             TPIQ11 TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED 
             TPIQ12 TPIQ15-TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE 
             TPIQ18-TPIQ22 TPIQ30-TPIQ31 TPIQ33)= 
             OPIQ08 OPIQ09 OPIQ09_WITH_CANCER OPIQ09_WITHOUT_CANCER 
             OPIQ11 OPIQ11_OPEN_RUPTURED OPIQ11_OPEN_UNRUPTURED OPIQ11_ENDO_RUPTURED OPIQ11_ENDO_UNRUPTURED
             OPIQ12 OPIQ15-OPIQ17 OPIQ17_HEMSTROKE_SUBARACH OPIQ17_HEMSTROKE_INTRACER OPIQ17_ISCHEMSTROKE 
             OPIQ18-OPIQ22 OPIQ30-OPIQ31 OPIQ33 ;
 run;


 proc Sort data=&OUTFILE_HOSPOBS.;
 by _TYPE_ HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 run;

 data OUTHOBS.&OUTFILE_HOSPOBS.;
   set &OUTFILE_HOSPOBS. (where=(_TYPE_ &TYPELVLH));

 array PPIQ PPIQ08 PPIQ09 PPIQ09_WITH_CANCER PPIQ09_WITHOUT_CANCER 
       PPIQ11 PPIQ11_OPEN_RUPTURED PPIQ11_OPEN_UNRUPTURED PPIQ11_ENDO_RUPTURED PPIQ11_ENDO_UNRUPTURED 
       PPIQ12 PPIQ15-PPIQ17 PPIQ17_HEMSTROKE_SUBARACH PPIQ17_HEMSTROKE_INTRACER PPIQ17_ISCHEMSTROKE 
       PPIQ18-PPIQ22 PPIQ30-PPIQ31 PPIQ33;

 do over PPIQ;
    if PPIQ eq 0 then PPIQ = .;
 end;

 %macro label_qis(qi_num=, qi_name=);
   label
   TP&qi_num. = "&qi_name. (Numerator)"
   PP&qi_num. = "&qi_name. (Population)"
   OP&qi_num. = "&qi_name. (Observed rate)"
   ;
 %mend label_qis;

 %label_qis(qi_num=IQ08,                    qi_name=IQI 08 Esophageal Resection Mortality Rate);
 %label_qis(qi_num=IQ09,                    qi_name=IQI 09 Pancreatic Resection Mortality Rate);
 %label_qis(qi_num=IQ09_WITH_CANCER,        qi_name=IQI 09 Pancreatic Resection Mortality Rate Stratum: Presence of Pancreatic Cancer);
 %label_qis(qi_num=IQ09_WITHOUT_CANCER,     qi_name=IQI 09 Pancreatic Resection Mortality Rate Stratum: Absence of Pancreatic Cancer);
 %label_qis(qi_num=IQ11,                    qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate);
 %label_qis(qi_num=IQ11_OPEN_RUPTURED,      qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_OPEN_RUPTURED: Open Repair of Ruptured AAA);
 %label_qis(qi_num=IQ11_OPEN_UNRUPTURED,    qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_OPEN_UNRUPTURED: Open Repair of Unruptured AAA);
 %label_qis(qi_num=IQ11_ENDO_RUPTURED,      qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_ENDO_RUPTURED: Endovascular Repair of Ruptured AAA);
 %label_qis(qi_num=IQ11_ENDO_UNRUPTURED,    qi_name=IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_ENDO_UNRUPTURED: Endovascular Repair of Unruptured AAA);
 %label_qis(qi_num=IQ12,                    qi_name=IQI 12 Coronary Artery Bypass Graft (CABG) Mortality Rate);
 %label_qis(qi_num=IQ15,                    qi_name=IQI 15 Acute Myocardial Infarction (AMI) Mortality Rate);
 %label_qis(qi_num=IQ16,                    qi_name=IQI 16 Heart Failure Mortality Rate);
 %label_qis(qi_num=IQ17,                    qi_name=IQI 17 Acute Stroke Mortality Rate);
 %label_qis(qi_num=IQ17_HEMSTROKE_SUBARACH, qi_name=IQI 17 Acute Stroke Mortality Rate Stratum_HEMSTROKE_SUBARACH: Subarachnoid Hemorrhage);
 %label_qis(qi_num=IQ17_HEMSTROKE_INTRACER, qi_name=IQI 17 Acute Stroke Mortality Rate Stratum_HEMSTROKE_INTRACER: Intracerebral Hemorrhage);
 %label_qis(qi_num=IQ17_ISCHEMSTROKE,       qi_name=IQI 17 Acute Stroke Mortality Rate Stratum_ISCHEMSTROKE: Ischemic Stroke);
 %label_qis(qi_num=IQ18,                    qi_name=IQI 18 Gastrointestinal Hemorrhage Mortality Rate);
 %label_qis(qi_num=IQ19,                    qi_name=IQI 19 Hip Fracture Mortality Rate);
 %label_qis(qi_num=IQ20,                    qi_name=IQI 20 Pneumonia Mortality Rate);
 %label_qis(qi_num=IQ21,                    qi_name=%quote(IQI 21 Cesarean Delivery Rate, Uncomplicated));
 %label_qis(qi_num=IQ22,                    qi_name=%quote(IQI 22 Vaginal Birth After Cesarean (VBAC) Delivery Rate, Uncomplicated));
 %label_qis(qi_num=IQ30,                    qi_name=IQI 30 Percutaneous Coronary Intervention (PCI) Mortality Rate);
 %label_qis(qi_num=IQ31,                    qi_name=IQI 31 Carotid Endarterectomy Mortality Rate);
 %label_qis(qi_num=IQ33,                    qi_name=%quote(IQI 33 Primary Cesarean Delivery Rate, Uncomplicated));

 label _TYPE_ = 'Stratification Level';

 drop _FREQ_ ;
run;


* -------------------------------------------------------------- ;
* --- CONTENTS AND MEANS OF HOSPITAL OBSERVED OUTPUT FILE    --- ;
* -------------------------------------------------------------- ;
 proc   Contents data=OUTHOBS.&OUTFILE_HOSPOBS. position;
 run;

***--- TO PRINT VARIABLE LABELS REMOVE "NOLABELS" FROM PROC MEANS STATEMENTS ---***;
proc Means data=OUTHOBS.&OUTFILE_HOSPOBS. (where=(_TYPE_ IN (16))) n nmiss min max sum nolabels;
   var TPIQ08 TPIQ09 TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER 
       TPIQ11 TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED
       TPIQ12 TPIQ15-TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE 
       TPIQ18-TPIQ22 TPIQ30-TPIQ31 TPIQ33;
   title  'SUMMARY OF INPATIENT QUALITY HOSPITAL-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=16';
run; quit;

proc Means data=OUTHOBS.&OUTFILE_HOSPOBS. (where=(_TYPE_ IN (16))) n nmiss min max sum nolabels;
   var PPIQ08 PPIQ09 PPIQ09_WITH_CANCER PPIQ09_WITHOUT_CANCER 
       PPIQ11 PPIQ11_OPEN_RUPTURED PPIQ11_OPEN_UNRUPTURED PPIQ11_ENDO_RUPTURED PPIQ11_ENDO_UNRUPTURED
       PPIQ12 PPIQ15-PPIQ17 PPIQ17_HEMSTROKE_SUBARACH PPIQ17_HEMSTROKE_INTRACER PPIQ17_ISCHEMSTROKE 
       PPIQ18-PPIQ22 PPIQ30-PPIQ31 PPIQ33;
   title  'SUMMARY OF INPATIENT QUALITY HOSPITAL-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=16';
run; quit;

proc Means data=OUTHOBS.&OUTFILE_HOSPOBS. (where=(_TYPE_ IN (16))) n nmiss min max mean nolabels;
   VAR OPIQ08 OPIQ09 OPIQ09_WITH_CANCER OPIQ09_WITHOUT_CANCER 
       OPIQ11 OPIQ11_OPEN_RUPTURED OPIQ11_OPEN_UNRUPTURED OPIQ11_ENDO_RUPTURED OPIQ11_ENDO_UNRUPTURED
       OPIQ12 OPIQ15-OPIQ17 OPIQ17_HEMSTROKE_SUBARACH OPIQ17_HEMSTROKE_INTRACER OPIQ17_ISCHEMSTROKE 
       OPIQ18-OPIQ22 OPIQ30-OPIQ31 OPIQ33;
   title  'SUMMARY OF INPATIENT QUALITY HOSPITAL-LEVEL INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=16';
run; quit;

* -------------------------------------------------------- ;
* --- PRINT HOSPITAL OBSERVED MEANS FILE TO SAS OUTPUT --- ;
* -------------------------------------------------------- ;
 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(IQ,TEXT,VOLUME);

 proc   PRINT data=OUTHOBS.&OUTFILE_HOSPOBS. LABEL SPLIT='*';
 %IF &VOLUME=0 %THEN %DO;
 var   HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ&IQ. PPIQ&IQ. OPIQ&IQ. ;
 label HOSPID  = "Hospital Identification Number"
       AGECAT  = "Age Categories"
       SEXCAT  = "Sex Categories"
       PAYCAT  = "Patient Primary Payer"
       RACECAT = "Race Categories"
       TPIQ&IQ.   = "TPIQ&IQ.*(Numerator)"
       PPIQ&IQ.   = "PPIQ&IQ.*(Population)"
       OPIQ&IQ.   = "OPIQ&IQ.*(Observed rate)"
       ;
 format TPIQ&IQ. PPIQ&IQ. 13.0 OPIQ&IQ. 8.6;
 %END;
 %ELSE %DO;
 var   HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ&IQ.  ;
 label HOSPID  = "Hospital Identification Number"
       AGECAT  = "Age Categories"
       SEXCAT  = "Sex Categories"
       PAYCAT  = "Patient Primary Payer"
       RACECAT = "Race Categories"
       TPIQ&IQ.   = "TPIQ&IQ.*(Numerator)"
       ;
 format TPIQ&IQ. 13.0;
 %END;
 format AGECAT AGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
   ;
 title4 "Indicator &IQ.: &TEXT";
 run;

 %MEND PRT;

 %PRT(08, Esophageal Resection Mortality Rate,0);
 %PRT(09, Pancreatic Resection Mortality Rate,0)
 %PRT(09_WITH_CANCER, Pancreatic Resection Mortality Rate Stratum_WITH_CANCER Presence of Pancreatic Cancer,0);
 %PRT(09_WITHOUT_CANCER, Pancreatic Resection Mortality Rate Stratum_WITHOUT_CANCER Absence of Pancreatic Cancer,0)
 %PRT(11, Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate,0);
 %PRT(11_OPEN_RUPTURED,   Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_OPEN_RUPTURED:   Open Repair of Ruptured,0);
 %PRT(11_OPEN_UNRUPTURED, Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_OPEN_UNRUPTURED: Open Repair of Unruptured,0);
 %PRT(11_ENDO_RUPTURED,   Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_ENDO_RUPTURED:   Endovascular Repair of Ruptured,0);
 %PRT(11_ENDO_UNRUPTURED, Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum_ENDO_UNRUPTURED: Endovascular Repair of Unruptured,0);
 %PRT(12, Coronary Artery Bypass Graft (CABG) Mortality Rate,0);
 %PRT(15, Acute Myocardial Infarction (AMI) Mortality Rate,0);
 %PRT(16, Heart Failure Mortality Rate,0);
 %PRT(17, Acute Stroke Mortality Rate,0);
 %PRT(17_HEMSTROKE_SUBARACH, Acute Stroke Mortality Rate Stratum_HEMSTROKE_SUBARACH: Subarachnoid Hemorrhage,0);
 %PRT(17_HEMSTROKE_INTRACER, Acute Stroke Mortality Rate Stratum_HEMSTROKE_INTRACER: Intracerebral Hemorrhage ,0);
 %PRT(17_ISCHEMSTROKE,       Acute Stroke Mortality Rate Stratum_ISCHEMSTROKE:       Ischemic Stroke,0);
 %PRT(18, Gastrointestinal Hemorrhage Mortality Rate,0);
 %PRT(19, Hip Fracture Mortality Rate,0);
 %PRT(20, Pneumonia Mortality Rate,0);
 %PRT(21, %BQUOTE(Cesarean Delivery Rate, Uncomplicated),0);
 %PRT(22, %BQUOTE(Vaginal Birth After Cesarean (VBAC) Delivery Rate, Uncomplicated),0);
 %PRT(30, Percutaneous Coronary Intervention (PCI) Mortality Rate,0);
 %PRT(31, Carotid Endarterectomy Mortality Rate,0);
 %PRT(33, %BQUOTE(Primary Cesarean Delivery Rate, Uncomplicated),0);

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
      ARRAY RATES OPIQ:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*1000;	
	  end;
	%END;
	
 %mend scale_rates;
 
 %if &TXTHOBS. = 1  %then %do;

 data _NULL_;
 set OUTHOBS.&OUTFILE_HOSPOBS.;
 %scale_rates;
 file IQTXTHOB lrecl=2000 ;
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
 put "HOSP ID" "," "Age"  "," "Sex"  "," "Payer" "," "Race"  "," "Type" ","
  "TPIQ08"  "," "TPIQ09"  "," "TPIQ09_WITH_CANCER" "," "TPIQ09_WITHOUT_CANCER" "," 
  "TPIQ11"  "," "TPIQ11_OPEN_RUPTURED" "," "TPIQ11_OPEN_UNRUPTURED" "," "TPIQ11_ENDO_RUPTURED" "," "TPIQ11_ENDO_UNRUPTURED" ","
  "TPIQ12"  "," "TPIQ15"  "," "TPIQ16" "," "TPIQ17"  "," "TPIQ17_HEMSTROKE_SUBARACH" "," "TPIQ17_HEMSTROKE_INTRACER" "," "TPIQ17_ISCHEMSTROKE" ","
  "TPIQ18"  "," "TPIQ19"  "," "TPIQ20" "," "TPIQ21"  "," "TPIQ22"  "," "TPIQ30"  "," "TPIQ31"  "," "TPIQ33"  ","
 
  "PPIQ08"  "," "PPIQ09"  "," "PPIQ09_WITH_CANCER" "," "PPIQ09_WITHOUT_CANCER" ","
  "PPIQ11"  "," "PPIQ11_OPEN_RUPTURED" "," "PPIQ11_OPEN_UNRUPTURED" "," "PPIQ11_ENDO_RUPTURED" "," "PPIQ11_ENDO_UNRUPTURED" "," 
  "PPIQ12"  "," "PPIQ15"  "," "PPIQ16" "," "PPIQ17"  "," "PPIQ17_HEMSTROKE_SUBARACH" "," "PPIQ17_HEMSTROKE_INTRACER" "," "PPIQ17_ISCHEMSTROKE" "," 
  "PPIQ18"  "," "PPIQ19"  "," "PPIQ20" "," "PPIQ21"  "," "PPIQ22"  "," "PPIQ30"  "," "PPIQ31"  "," "PPIQ33"  "," 
 
  "OPIQ08"  "," "OPIQ09"  "," "OPIQ09_WITH_CANCER" "," "OPIQ09_WITHOUT_CANCER" "," 
  "OPIQ11"  "," "OPIQ11_OPEN_RUPTURED" "," "OPIQ11_OPEN_UNRUPTURED" "," "OPIQ11_ENDO_RUPTURED" "," "OPIQ11_ENDO_UNRUPTURED" ","
  "OPIQ12"  "," "OPIQ15"  "," "OPIQ16" "," "OPIQ17"  "," "OPIQ17_HEMSTROKE_SUBARACH" "," "OPIQ17_HEMSTROKE_INTRACER" "," "OPIQ17_ISCHEMSTROKE" ","
  "OPIQ18"  "," "OPIQ19"  "," "OPIQ20" "," "OPIQ21"  "," "OPIQ22"  "," "OPIQ30"  "," "OPIQ31"  "," "OPIQ33"
  ;
 end;

 put HOSPID 13. "," AGECAT 3.  "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPIQ08 TPIQ09 TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER
  TPIQ11 TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED 
  TPIQ12 TPIQ15-TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE
  TPIQ18-TPIQ22 TPIQ30-TPIQ31 TPIQ33) (7.0 ",")
 ","
 (PPIQ08 PPIQ09 PPIQ09_WITH_CANCER PPIQ09_WITHOUT_CANCER 
  PPIQ11 PPIQ11_OPEN_RUPTURED PPIQ11_OPEN_UNRUPTURED PPIQ11_ENDO_RUPTURED PPIQ11_ENDO_UNRUPTURED 
  PPIQ12 PPIQ15-PPIQ17 PPIQ17_HEMSTROKE_SUBARACH PPIQ17_HEMSTROKE_INTRACER PPIQ17_ISCHEMSTROKE 
  PPIQ18-PPIQ22 PPIQ30-PPIQ31 PPIQ33) (13.0 ",")
 ","
 (OPIQ08 OPIQ09 OPIQ09_WITH_CANCER OPIQ09_WITHOUT_CANCER 
  OPIQ11 OPIQ11_OPEN_RUPTURED OPIQ11_OPEN_UNRUPTURED OPIQ11_ENDO_RUPTURED OPIQ11_ENDO_UNRUPTURED 
  OPIQ12 OPIQ15-OPIQ17 OPIQ17_HEMSTROKE_SUBARACH OPIQ17_HEMSTROKE_INTRACER OPIQ17_ISCHEMSTROKE 
  OPIQ18-OPIQ22 OPIQ30-OPIQ31 OPIQ33) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ;
 run;

 %END;

 %MEND TEXTP1;

 %TEXTP1;
