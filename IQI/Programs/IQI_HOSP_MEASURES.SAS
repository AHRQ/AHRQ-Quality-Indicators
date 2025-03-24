*========================PROGRAM: IQI_HOSP_MEASURES.SAS============================;
*
*  DESCRIPTION:
*         Assigns the IQI outcome measure of interest to inpatient records.
*         Variables created by this program are TPIQXX and stratifiers.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*  USER NOTE1: Make sure you have created the format library
*              using IQI_FORMATS.SAS BEFORE running this program.
*              This is done through the CONTROL program.
*
*  USER NOTE2: The AHRQ QI software does not support the calculation of weighted
*              estimates and standard errors using complex sampling designs.
* 
*  USER NOTE3: See the AHRQ_IQI_SAS_v2024_ICD10_Release_Notes.txt file for 
*              software change notes.
*
*==================================================================================;

 title2 'IQI_HOSP_MEASURES PROGRAM';
 title3 'AHRQ INPATIENT QUALITY INDICATORS: ASSIGN IQIs TO INPATIENT DATA';

 * ------------------------------------------------------------------ ;
 * --- VERIFY MDC VALUES PROVIDED ON THE INPUT FILE ARE VALID     --- ;
 * ------------------------------------------------------------------ ;

 %macro check_mdc;
   %if &MDC_PROVIDED. = 1 %then %do;

     proc sql noprint;
       select count(*), nmiss(MDC), min(MDC), max(MDC) into :n_total, :n_miss, :min_MDC, :max_MDC
       from INMSR.&DISCHARGE.;
     quit;

     %if &n_total. > 0 and &n_total. = &n_miss. %then %do;
       %put "ERROR: MDC_PROVIDED = 1 in CONTROL program but all MDC values are missing on input data";
       %abort cancel;
     %end;


     %put minimum MDC=&min_MDC., maximum MDC=&max_MDC.;

     %if &min_MDC. <0 or &max_MDC. >25 %then %do;
       %put "WARNING: MDC_PROVIDED = 1 in CONTROL program but some MDC values are out of range of 0-25";
     %end;

   %end;
 %mend check_mdc;
 %check_mdc;

 * ------------------------------------------------------------------ ;
 * --- DETERMINE IF PAY1 AND RACE ARE SUPPLIED ON THE INPUT FILE  --- ;
 * ------------------------------------------------------------------ ;
 
 %macro check_pay1_race;
   %global PAY1_PROVIDED RACE_PROVIDED;
   proc contents data=INMSR.&DISCHARGE. noprint out=chkpay1race(keep=name);run;
   proc sql noprint;
      select sum(upcase(strip(name))="PAY1"), sum(upcase(strip(name))="RACE") into :PAY1_PROVIDED, :RACE_PROVIDED
	    from chkpay1race;
   quit;

   %put PAY1_PROVIDED = &PAY1_PROVIDED., RACE_PROVIDED = &RACE_PROVIDED.;

   %if &PAY1_PROVIDED. = 0 %then %do;
     %put "WARNING: The input data does not have PAY1. The software creates a fake PAY1 as PAY1=999 for the programs to run";
   %end;
   %if &RACE_PROVIDED. = 0 %then %do;
     %put "WARNING: The input data does not have RACE. The software creates a fake RACE as RACE=999 for the programs to run";
   %end;
 %mend check_pay1_race;
 %check_pay1_race;

 * ------------------------------------------------------------------ ;
 * --- CREATE A PERMANENT DATASET CONTAINING ALL RECORDS THAT     --- ;
 * --- WILL NOT BE INCLUDED IN ANALYSIS BECAUSE KEY VARIABLE      --- ;
 * --- VALUES ARE MISSING. REVIEW AFTER RUNNING IQI_HOSP_MEASURES. -- ;
 * ------------------------------------------------------------------ ;

 data   OUTMSR.&DELFILE.
   (keep=KEY HOSPID SEX AGE DX1 DRG MDC YEAR DQTR);
 set  INMSR.&DISCHARGE.;
 if (AGE lt 0) or (AGE lt 18 and not %MDX1($MDC14PRINDX.)) or %MDX1($MDC15PRINDX.) or (missing(SEX)) or
    (missing(DX1)) or (missing(DQTR)) or (missing(YEAR)) or (DRG = 999) or
    (&MDC_PROVIDED. = 1 and missing(MDC));
 run;

 * -------------------------------------------------------------- ;
 * --- INPATIENT QUALITY INDICATOR (IQI) NAMING CONVENTION:   --- ;
 * --- THE FIRST LETTER IDENTIFIES THE INPATIENT QUALITY      --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:                     --- ;
 * ---          (T) NUMERATOR ("TOP")                         --- ;
 * --- THE SECOND LETTER IDENTIFIES THE IQI AS A HOSPITAL (P) --- ;
 * --- LEVEL INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS   --- ;
 * --- 'IQ'. THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.    --- ;
 * -------------------------------------------------------------- ;

 data   OUTMSR.&OUTFILE_MEAS.
    (keep=KEY HOSPID DRG MDC SEX AGE YEAR DQTR
          AGECAT SEXCAT RACECAT PAYCAT TRNSFER COVIDDX D_DXCCSR_: D_IQ: CSHOCKANOXBDD MRTAMISTD DNR
          TPIQ08 TPIQ09 TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER 
          TPIQ11 TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED 
          TPIQ12 TPIQ15-TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE 
          TPIQ18-TPIQ22 TPIQ30-TPIQ31 TPIQ33 &OUTFILE_KEEP
    );

 set   INMSR.&DISCHARGE.
    (keep=KEY HOSPID DRG MDC SEX AGE YEAR DQTR
          DISP ASOURCE POINTOFORIGINUB04
          DX1-DX&NDX. PR1-PR&NPR. %ADDPRDAY_PAY1_RACE
          DXPOA1-DXPOA&NDX. &OUTFILE_KEEP);

 label
 SEX = 'Sex of the patient'
 key = 'Unique record identifier'
 ;

 ARRAY DX(&NDX.)    $ DX1-DX&NDX.;
 ARRAY DXPOA(&NDX.) $ DXPOA1-DXPOA&NDX.;
 ARRAY PR(&NPR.)    $ PR1-PR&NPR.;
 ARRAY PRDAY(&NPR.)   PRDAY1-PRDAY&NPR.;

 * --------------------------------------------------------------- ;
 * -- DELETE NON-ADULT RECORDS AND RECORDS WITH MISSING VALUES --- ;
 * -- FOR AGE, SEX, DX1, DQTR, YEAR, MDC OR DRG = 999          --- ;
 * --------------------------------------------------------------- ;
 
 if missing(SEX) then delete;
 if AGE lt 0 then delete;
 if AGE lt 18 and not %MDX1($MDC14PRINDX.) then delete;
 if %MDX1($MDC15PRINDX.) then delete;
 if missing(DX1) then delete;
 if missing(DQTR) then delete;
 if missing(YEAR) then delete;
 if DRG = 999 then delete;
 if &MDC_PROVIDED. = 1 and missing(MDC) then delete;


 * -------------------------------------------------------------- ;
 * --- DEFINE ICD-10-CM VERSION --------------------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib ICDVER length=3
   label='ICD-10-CM VERSION';

 ICDVER = 0;
 if (YEAR in (2015) and DQTR in (4))          then ICDVER = 33;
 else if (YEAR in (2016) and DQTR in (1,2,3)) then ICDVER = 33;
 else if (YEAR in (2016) and DQTR in (4))     then ICDVER = 34;
 else if (YEAR in (2017) and DQTR in (1,2,3)) then ICDVER = 34;
 else if (YEAR in (2017) and DQTR in (4))     then ICDVER = 35;
 else if (YEAR in (2018) and DQTR in (1,2,3)) then ICDVER = 35;
 else if (YEAR in (2018) and DQTR in (4))     then ICDVER = 36;
 else if (YEAR in (2019) and DQTR in (1,2,3)) then ICDVER = 36;
 else if (YEAR in (2019) and DQTR in (4))     then ICDVER = 37;
 else if (YEAR in (2020) and DQTR in (1,2,3)) then ICDVER = 37;
 else if (YEAR in (2020) and DQTR in (4))     then ICDVER = 38;
 else if (YEAR in (2021) and DQTR in (1,2,3)) then ICDVER = 38;
 else if (YEAR in (2021) and DQTR in (4))     then ICDVER = 39;
 else if (YEAR in (2022) and DQTR in (1,2,3)) then ICDVER = 39;
 else if (YEAR in (2022) and DQTR in (4))     then ICDVER = 40;
 else if (YEAR in (2023) and DQTR in (1,2,3)) then ICDVER = 40;
 else if (YEAR in (2023) and DQTR in (4))     then ICDVER = 41;
 else if (YEAR in (2024) and DQTR in (1,2,3)) then ICDVER = 41;
 else ICDVER = 41; *Defaults to last version for discharges outside coding updates.;


 * -------------------------------------------------------------- ;
 * --- CREATE FAKE PAY1 AND RACE IF THEY ARE NOT IN INPUT DATA -- ;
 * -------------------------------------------------------------- ;

  %CreateFakePAY1_RACE;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: PAYER CATEGORY ------------------------ ;
 * -------------------------------------------------------------- ;

 attrib PAYCAT length=3
   label='Patient Primary Payer';

 select (PAY1);
   when (1)  PAYCAT = 1;
   when (2)  PAYCAT = 2;
   when (3)  PAYCAT = 3;
   when (4)  PAYCAT = 4;
   when (5)  PAYCAT = 5;
   otherwise PAYCAT = 6;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: RACE CATEGORY ------------------------- ;
 * -------------------------------------------------------------- ;

 attrib RACECAT length=3
  label = 'Race Categories';

 select (RACE);
   when (1)  RACECAT = 1;
   when (2)  RACECAT = 2;
   when (3)  RACECAT = 3;
   when (4)  RACECAT = 4;
   when (5)  RACECAT = 5;
   otherwise RACECAT = 6;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: AGE CATEGORY  ------------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib AGECAT length=3
   label='Age Categories';

 select;
   when (      AGE < 18)  AGECAT = 0;
   when (18 <= AGE < 40)  AGECAT = 1;
   when (40 <= AGE < 65)  AGECAT = 2;
   when (65 <= AGE < 75)  AGECAT = 3;
   when (75 <= AGE     )  AGECAT = 4;
   otherwise AGECAT = 0;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: SEX CATEGORY  ------------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib SEXCAT length=3
    label  = 'Sex Categories';

 select (SEX);
   when (1)  SEXCAT = 1;
   when (2)  SEXCAT = 2;
   otherwise SEXCAT = 0;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE COVID STATUS  ------------------------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib COVIDDX length=3
    label  = 'COVID-19 Diagnosis';

 COVIDDX = 0;

 if %MDX2Q2($COVIDD.) then COVIDD_cd=1;
 if %MDX2Q2($COVIDQ120D.) then COVIDQ120D_cd=1;

 if YEAR > 2020 then do;
   if %MDX1($COVIDD.) or COVIDD_cd=1 then COVIDDX = 1;
 end;
 else if YEAR in (2020) then do;
   if DQTR in (1) then do;
     if %MDX1($COVIDQ120D.) or COVIDQ120D_cd=1 then COVIDDX = 1;
   end;
   else if DQTR in (2,3,4) then do;
     if %MDX1($COVIDD.) or COVIDD_cd=1 then COVIDDX = 1;
   end;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE HOSPITAL LEVEL INDICATORS ------------------------- ;
 * -------------------------------------------------------------- ;
 %macro label_qis(qi_num=, qi_name=);
   attrib
   TP&qi_num. length=8
   label = "&qi_name. (Numerator)"
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


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT DXCCSR VARIABLES ------------------------------- ;
 * -------------------------------------------------------------- ;
 
 %include MacLib(IQI_HOSP_DXCCSR_Code_v2024.sas);


 * -------------------------------------------------------------- ;
 * --- IDENTIFY CSHOCKANOXBDD ----------------------------------- ;
 * -------------------------------------------------------------- ;
  attrib CSHOCKANOXBDD length=3
  label='Cardiogenic shock, anoxic brain injury, or cardiac arrest';

  if %MDXAQ2($CSHOCKANOXBDD.) then CSHOCKANOXBDD = 1;
  else CSHOCKANOXBDD = 0;

 * -------------------------------------------------------------- ;
 * --- IDENTIFY MRTAMISTD --------------------------------------- ;
 * -------------------------------------------------------------- ;
  attrib MRTAMISTD length=3
  label='STEMI AMI';
   
  if %MDXAQ2($MRTAMISTD.) or %MDX1($MRTAMISTD.) then MRTAMISTD = 1;
  else MRTAMISTD = 0;

 * -------------------------------------------------------------- ;
 * --- IDENTIFY DNR --------------------------------------------- ;
 * -------------------------------------------------------------- ;
  attrib DNR length=3
   label='DO NOT RESUSCITATE FLAG';

  if %MDX2Q2($DNR.) then DNR = 1;
    else DNR = 0;


 * ----------------------------------------------------- ;
 * --- CONSTRUCT HOSPITAL LEVEL MORTALITY INDICATORS --- ;
 * ----------------------------------------------------- ;

 * ----------------------------------------------------- ;
 * --- IQI 08 : ESOPHAGEAL RESECTION MORTALITY RATE	 --- ;
 * ----------------------------------------------------- ;

   if not %MDX1($MDC14PRINDX.) and
     ((%MPR($PRESOPP.) and (%MDX($PRESOPD.) or %MDX($PRESO2D.))) or
      (%MPR($PRESO2P.) and %MDX($PRESOPD.)))
   then do;

     TPIQ08 = 0;
     if DISP in (20) then TPIQ08 = 1;

   end;


 * ---------------------------------------------------- ;
 * --- IQI 09 : PANCREATIC RESECTION MORTALITY RATE --- ;
 * ---------------------------------------------------- ;
 
   if not %MDX1($MDC14PRINDX.) and (%MPR($PRPANCP.) or %MPR($PRPAN3P.)) then do;

     TPIQ09 = 0;
     if DISP in (20) then TPIQ09 = 1;

     if %MDX($PRPANCD.) then do;
         TPIQ09_WITH_CANCER = 0;
            if DISP in (20) then TPIQ09_WITH_CANCER = 1;
     end;
     else do;
          TPIQ09_WITHOUT_CANCER = 0;
         if DISP in (20) then TPIQ09_WITHOUT_CANCER = 1;
     end;

     *** EXCLUDE ACUTE PANCREATITIS;
     if %MDX($PRPAN2D.) then do;
         TPIQ09 = .;
         TPIQ09_WITH_CANCER = .;
         TPIQ09_WITHOUT_CANCER = .;
     end;

    end;


 * ---------------------------------------------------------------------- ;
 * --- IQI 11 : ABDOMINAL AORTIC ANEURYSM (AAA) REPAIR MORTALITY RATE --- ;
 * ---------------------------------------------------------------------- ;

   if not %MDX1($MDC14PRINDX.) and
      (%MDX($PRAAARD.) or %MDX($PRAAA2D.)) and
      (%MPR($PRAAARP.) or %MPR($PRAAA2P.))

     then do;

     TPIQ11 = 0;
     if DISP in (20) then TPIQ11 = 1;

   end;

   *** IN-HOSP MORT AAA REPAIR (STRATIFICATION);
   *** stratification priority according to prior probability of death;
   if not %MDX1($MDC14PRINDX.) then do;

     /** IQI 11 Stratum_OPEN_RUPTURED : OPEN REPAIR OF RUPTURED ***/
     if %MPR($PRAAARP.) and %MDX($PRAAARD.) then do;
        TPIQ11_OPEN_RUPTURED = 0;
       if DISP in (20) then TPIQ11_OPEN_RUPTURED = 1;
     end;

     /** IQI 11 Stratum_ENDO_RUPTURED : ENDOVASCULAR REPAIR OF RUPTURED ***/
     else if %MPR($PRAAA2P.) and %MDX($PRAAARD.) then do;
        TPIQ11_ENDO_RUPTURED = 0;
       if DISP in (20) then TPIQ11_ENDO_RUPTURED = 1;
     end;

     /** IQI 11 Stratum_OPEN_UNRUPTURED : OPEN REPAIR OF UNRUPTURED ***/
     else if %MPR($PRAAARP.) and %MDX($PRAAA2D.) then do;
         TPIQ11_OPEN_UNRUPTURED = 0;
          if DISP in (20) then TPIQ11_OPEN_UNRUPTURED = 1;
     end;

     /** IQI 11 Stratum_ENDO_UNRUPTURED : ENDOVASCULAR REPAIR OF UNRUPTURED ***/
     else if %MPR($PRAAA2P.) and %MDX($PRAAA2D.) then do;
        TPIQ11_ENDO_UNRUPTURED = 0;
       if DISP in (20) then TPIQ11_ENDO_UNRUPTURED = 1;
     end;

   end;


 * ------------------------------------------------------------------- ;
 * --- IQI 12 : CORONARY ARTERY BYPASS GRAFT (CABG) MORTALITY RATE --- ;
 * ------------------------------------------------------------------- ;

   if not %MDX1($MDC14PRINDX.) and (AGE >= 40) and
     %MPR($PRCABGP.)
   then do;

     TPIQ12 = 0;
     if DISP in (20) then TPIQ12 = 1;

   end;


 * ----------------------------------------------------------------- ;
 * --- IQI 15 : ACUTE MYOCARDIAL INFARCTION (AMI) MORTALITY RATE --- ;
 * ----------------------------------------------------------------- ;

   if not %MDX1($MDC14PRINDX.) and
     %MDX1($MRTAMID.) then do;

     TPIQ15 = 0;
     if DISP in (20) then TPIQ15 = 1;

     *** Exclusion for cases admitted from a hospice facility ;
     if POINTOFORIGINUB04 in ('F') then TPIQ15 = .;

   end;


 * --------------------------------------------- ;
 * --- IQI 16 : HEART FAILURE MORTALITY RATE --- ;
 * --------------------------------------------- ;

   if not %MDX1($MDC14PRINDX.) and
      %MDX1($MRTCHFD.)
   then do;

     TPIQ16 = 0;
     if DISP in (20) then TPIQ16 = 1;

     *** Exclude any procedure code for heart transplant ;
     if %MPR($HEARTTRP.) then TPIQ16 = .;

     *** Exclusion for cases admitted from a hospice facility ;
     if POINTOFORIGINUB04 in ('F') then TPIQ16 = .;

   end;


 * -------------------------------------------- ;
 * --- IQI 17 : ACUTE STROKE MORTALITY RATE --- ;
 * -------------------------------------------- ;

   if not %MDX1($MDC14PRINDX.) and
      (%MDX1($MRTCV2A.) or %MDX1($MRTCV3D.) or %MDX1($MRTCV4D.))
   then do;

      TPIQ17 = 0;
      if DISP in (20) then TPIQ17 = 1;

   end;

   *** ACUTE STROKE MORTALITY (STRATIFICATION);
   *** Stratification priority according to prior probability of death;

   /* IQI 17 Stratum_HEMSTROKE_INTRACER : INTRACEREBRAL HEMORRHAGIC STROKE */
   if not %MDX1($MDC14PRINDX.) and %MDX1($MRTCV3D.) then do;
      TPIQ17_HEMSTROKE_INTRACER = 0;
      if DISP in (20) then TPIQ17_HEMSTROKE_INTRACER = 1;
   end;

   /* IQI 17 Stratum_HEMSTROKE_SUBARACH : SUBARACHNOID HEMORRHAGE  */
   else if not %MDX1($MDC14PRINDX.) and %MDX1($MRTCV2A.) then do;
      TPIQ17_HEMSTROKE_SUBARACH = 0;
      if DISP in (20) then TPIQ17_HEMSTROKE_SUBARACH = 1;
   end;

   /* IQI 17 Stratum_ISCHEMSTROKE : ISCHEMIC HEMORRHAGIC STROKE */
   else if not %MDX1($MDC14PRINDX.) and %MDX1($MRTCV4D.) then do;
      TPIQ17_ISCHEMSTROKE = 0;
      if DISP in (20) then TPIQ17_ISCHEMSTROKE = 1;
   end;

   *** Exclusion for cases admitted from a hospice facility ;
   if POINTOFORIGINUB04 in ('F') then do;
     TPIQ17 = .;
     TPIQ17_HEMSTROKE_SUBARACH = .;
     TPIQ17_HEMSTROKE_INTRACER = .;
     TPIQ17_ISCHEMSTROKE = .;
   end;


 * ----------------------------------------------------------- ;
 * --- IQI 18 : GASTROINTESTINAL HEMORRHAGE MORTALITY RATE --- ;
 * ----------------------------------------------------------- ;

   if not %MDX1($MDC14PRINDX.) and
      (%MDX1($MRTGIHD.) or (%MDX2($FTR6GV.) and %MDX1($FTR6QD.)))
   then do;

     TPIQ18 = 0;
     if DISP in (20) then TPIQ18 = 1;

     *** Exclusion for cases admitted from a hospice facility ;
     if POINTOFORIGINUB04 in ('F') then TPIQ18 = .;

     *** Exclusion for liver transplant ;
     if %MPR($LIVERTRP.) then TPIQ18 = .;

   end;


 * -------------------------------------------- ;
 * --- IQI 19 : HIP FRACTURE MORTALITY RATE --- ;
 * -------------------------------------------- ;

   if not %MDX1($MDC14PRINDX.) and (AGE >= 65) and
      %MDX1($MTHIPFD.)
   then do;

     TPIQ19 = 0;
     if DISP in (20) then TPIQ19 = 1;

     *** Exclude periprosthetic fracture;
     if %MDX($MTHIP2D.) then TPIQ19 = .;      

     *** Exclusion for cases admitted from a hospice facility ;
     if POINTOFORIGINUB04 in ('F') then TPIQ19 = .;

   end;


 * ----------------------------------------- ;
 * --- IQI 20 : PNEUMONIA MORTALITY RATE --- ;
 * ----------------------------------------- ;

   if %MDX2Q2($PNEUMD.) then PNEUMD_cd = 1;
   
   if not %MDX1($MDC14PRINDX.) and
      (%MDX1($PNEUMD.) or (%MDX1($SEPPNEUD.) and PNEUMD_cd))
   then do;

     TPIQ20 = 0;
     if DISP in (20) then TPIQ20 = 1;

     *** Exclusion for cases admitted from a hospice facility ;
     if POINTOFORIGINUB04 in ('F') then TPIQ20 = .;

     *** Exclusion for cases with severe sepsis;
     if %MDX2Q2($SEVSEPD.) then TPIQ20 = .;

   end;


 * --- CONSTRUCT ADDITIONAL HOSPITAL LEVEL MORTALITY INDICATORS - ;

 * ------------------------------------------------------------------------ ;
 * --- IQI 30 : PERCUTANEOUS CORONARY INTERVENTION (PCI) MORTALITY RATE --- ;
 * ------------------------------------------------------------------------ ;

   if not %MDX1($MDC14PRINDX.) and (AGE >= 40) and
     %MPR($PRPTCAP.)
   then do;

     TPIQ30 = 0;
     if DISP in (20) then TPIQ30 = 1;

   end;


 * ------------------------------------------------------ ;
 * --- IQI 31 : CAROTID ENDARTERECTOMY MORTALITY RATE --- ;
 * ------------------------------------------------------ ;

   if not %MDX1($MDC14PRINDX.) and
     %MPR($PRCEATP.)
   then do;

     TPIQ31 = 0;
     if DISP in (20) then TPIQ31 = 1;

   end;


 * --- CONSTRUCT HOSPITAL LEVEL UTILIZATION INDICATORS ---------- ;

 * --------------------------------------------------------- ;
 * --- IQI 21 : CESAREAN SECTION DELIVERY, UNCOMPLICATED --- ;
 * --------------------------------------------------------- ;

   if %MDX($DELOCMD.)
   then do;

     TPIQ21 = 0;
     if (%MPR($PRCSECP.) and not %MPR($PRCSE2P.)) then TPIQ21 = 1;

     if %MDX($PRCSECD.) then TPIQ21 = .;

   end;


 * --------------------------------------------------------------------------------- ;
 * --- IQI 22 : VAGINAL BIRTH AFTER CESAREAN (VBAC) DELIVERY RATE, UNCOMPLICATED --- ;
 * --------------------------------------------------------------------------------- ;

   if %MDX($DELOCMD.) and %MDX($PRVBACD.)
   then do;

     TPIQ22 = 0;
     if %MPR($VAGDELP.) then TPIQ22 = 1;

     if %MDX($PRCSECD.) then TPIQ22 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- IQI 33 : PRIMARY CESAREAN DELIVERY RATE, UNCOMPLICATED --- ;
 * -------------------------------------------------------------- ;

   if %MDX($DELOCMD.)
   then do;

     TPIQ33 = 0;
     if (%MPR($PRCSECP.) and not %MPR($PRCSE2P.)) then TPIQ33 = 1;

     if %MDX($PRCSECD.) or %MDX($PRVBACD.) then TPIQ33 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- EXCLUSIONS  ---------------------------------------------- ;
 * -------------------------------------------------------------- ;

 array TPIQ TPIQ08 TPIQ09 TPIQ09_WITH_CANCER TPIQ09_WITHOUT_CANCER 
    TPIQ11 TPIQ11_OPEN_RUPTURED TPIQ11_OPEN_UNRUPTURED TPIQ11_ENDO_RUPTURED TPIQ11_ENDO_UNRUPTURED 
    TPIQ12 TPIQ15-TPIQ17 TPIQ17_HEMSTROKE_SUBARACH TPIQ17_HEMSTROKE_INTRACER TPIQ17_ISCHEMSTROKE 
    TPIQ18-TPIQ20 TPIQ30-TPIQ31
 ;

 * --- EXCLUDE CASES WITH MISSING VALUES FOR DISP --------------- ;
 if (DISP lt 0) then do over TPIQ;
    TPIQ = .;
  end;

 * --- TRANSFER TO ANOTHER ACUTE CARE HOSPITAL ------------------ ;
 if DISP in (2) then do over TPIQ;
   TPIQ = .;
 end;

 * -------------------------------------------------------------- ;
 * --- IDENTIFY TRANSFERS --------------------------------------- ;
 * -------------------------------------------------------------- ;

 *** Flag transfers from another acute care hospital;
 if ASOURCE in (2) or POINTOFORIGINUB04 in ('4') then TRNSFER = 1;
 else TRNSFER = 0;

 *** Label variables;
 label
    TRNSFER = 'Transfer from Another Acute Care Hospital'
    HOSPID  = 'Hospital Identification Number'
 ;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT PRCCSR VARIABLES ------------------------------- ;
 * -------------------------------------------------------------- ;

 %include MacLib(IQI_HOSP_PRCCSR_Code_v2024.sas);

run;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MEASURES OUTPUT FILE             --- ;
 * -------------------------------------------------------------- ;
  
proc MEANS data=OUTMSR.&OUTFILE_MEAS. N NMISS MIN MAX MEAN SUM;
title "INPATIENT QUALITY INDICATOR NUMERATOR (=SUM),DENOMINATOR (=N), AND OBSERVED RATE (MEAN) ";
run;

proc CONTENTS data=OUTMSR.&OUTFILE_MEAS. POSITION;
title "INPATIENT QUALITY INDICATOR MEASURE OUTPUT";
run;

proc PRINT data=OUTMSR.&OUTFILE_MEAS.(OBS=24);
title4 "FIRST 24 RECORDS IN OUTPUT DATA SET &OUTFILE_MEAS.";
run;
