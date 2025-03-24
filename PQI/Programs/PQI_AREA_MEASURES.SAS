* ====================== PROGRAM: PQI_AREA_MEASURES.SAS ======================;
*
*  DESCRIPTION:
*         Assigns the Prevention Quality Indicator outcome of interest and
*         stratifier categories to inpatient records.
*         Variables created by this program are TAPQXX and stratifiers.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*  USER NOTE1: The PQI_FORMATS.SAS program must be run BEFORE
*              running this program.
*
*  USER NOTE2: See the AHRQ_PQI_SAS_v2024_ICD10_Release_Notes.txt file for 
*              software change notes.
*
*  USER NOTE3: The AHRQ QI software does not support the calculation of
*              weighted estimates and standard errors using complex
*              sampling designs.
*
* ===========================================================================;

 title2 'PQI_AREA_MEASURES PROGRAM';
 title3 'AHRQ PREVENTION QUALITY INDICATORS: ASSIGN PQIs TO INPATIENT DATA';

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

 * ------------------------------------------------------------------- ;
 * --- CREATE A PERMANENT DATASET CONTAINING ALL RECORDS THAT      --- ;
 * --- WILL NOT BE INCLUDED IN ANALYSIS BECAUSE KEY VARIABLE       --- ;
 * --- VALUES ARE MISSING. REVIEW AFTER RUNNING PQI_AREA_MEASURES. --- ;
 * ------------------------------------------------------------------- ;

 data   OUTMSR.&DELFILE.
     (keep=KEY HOSPID SEX AGE DX1 MDC YEAR DQTR);
 set     INMSR.&DISCHARGE.;
 if (AGE lt 0) or (AGE lt 18 and not %MDX1($MDC14PRINDX.)) or (missing(SEX)) or
    (missing(DX1)) or (missing(DQTR)) or (missing(YEAR)) or (DRG = 999);
 run;

 * ------------------------------------------------------------------ ;
 * --- PREVENTION QUALITY INDICATOR (PQI) NAMING CONVENTION:      --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PREVENTION QUALITY         --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:                         --- ;
 * ---             (T) NUMERATOR ("TOP")                          --- ;
 * --- THE SECOND LETTER IDENTIFIES THE PQI AS AN AREA (A)        --- ;
 * --- LEVEL INDICATOR. THE LAST TWO DIGITS ARE THE INDICATOR     --- ;
 * --- NUMBER.                                                    --- ;
 * ------------------------------------------------------------------ ;

data OUTMSR.&OUTFILE_MEAS.
                 (keep=KEY FIPST FIPSTCO DRG MDC YEAR DQTR
                       AGECAT AGECCAT POPCAT SEXCAT RACECAT
                       TAPQ01--TAPQ16 TAPQ90-TAPQ93 &OUTFILE_KEEP);
 set INMSR.&DISCHARGE.
                 (keep=KEY DRG MDC SEX AGE PSTCO
                       %ADDPAY1_RACE YEAR DQTR
                       ASOURCE POINTOFORIGINUB04
                       DX1-DX&NDX. PR1-PR&NPR. &OUTFILE_KEEP);

 label
 key = 'Unique record identifier'
 ;

 * --------------------------------------------------------------- ;
 * -- DELETE NON-ADULT RECORDS AND RECORDS WITH MISSING VALUES --- ;
 * -- FOR AGE, SEX, DX1, DQTR, YEAR OR DRG = 999               --- ;
 * --------------------------------------------------------------- ;
 
 if missing(SEX) then delete;
 if AGE lt 0 then delete;
 if AGE lt 18 and not %MDX1($MDC14PRINDX.) then delete;
 if missing(DX1) then delete;
 if missing(DQTR) then delete;
 if missing(YEAR) then delete;
 if DRG = 999 then delete;


 * ---------------------------------------------------------------- ;
 * --- DEFINE FIPS STATE AND COUNTY CODES ------------------------- ;
 * ---------------------------------------------------------------- ;

 attrib FIPSTCO length=$5
   label='FIPS State County Code';
 FIPSTCO = put(PSTCO,Z5.);

 attrib FIPST length=$2
   label='State FIPS Code';
 FIPST = substr(FIPSTCO,1,2);


 * --------------------------------------------------------------- ;
 * --- DEFINE ICD-10-CM VERSION ---------------------------------- ;
 * --------------------------------------------------------------- ;

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

 * --------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: PAYER CATEGORY ------------------------- ;
 * --------------------------------------------------------------- ;

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
 * --- DEFINE STRATIFIER: AGE CATEGORY -------------------------- ;
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
 * --- DEFINE STRATIFIER: CONDITION-SPECIFIC AGE CATEGORY ------- ;
 * -------------------------------------------------------------- ;

 attrib AGECCAT length=3
   label='Age Condition Categories';

 select;
   when (      AGE < 18)  AGECCAT = 0;
   when (18 <= AGE < 45)  AGECCAT = 1;
   when (45 <= AGE < 65)  AGECCAT = 2;
   when (65 <= AGE < 75)  AGECCAT = 3;
   when (75 <= AGE     )  AGECCAT = 4;
   otherwise AGECCAT = 0;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: SEX CATEGORY -------------------------- ;
 * -------------------------------------------------------------- ;

 attrib SEXCAT length=3
   label='Sex Categories';

 select (SEX);
   when (1)  SEXCAT = 1;
   when (2)  SEXCAT = 2;
   otherwise SEXCAT = 0;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: POPULATION CATEGORY ------------------- ;
 * -------------------------------------------------------------- ;

 attrib POPCAT length=3
   label = 'Population Age Categories';

 POPCAT=put(AGE,AGEFMT.);


 * -------------------------------------------------------------- ;
 * --- DEFINE AREA LEVEL INDICATORS ----------------------------- ;
 * -------------------------------------------------------------- ;

 %macro label_qis(qi_num=, qi_name=);
   attrib TA&qi_num. length=8
   label = "&qi_name. (Numerator)"
   ;
 %mend label_qis;
 
 %label_qis(qi_num=PQ01, qi_name=PQI 01 Diabetes Short-Term Complications Admission Rate);
 %label_qis(qi_num=PQ03, qi_name=PQI 03 Diabetes Long-Term Complications Admission Rate);
 %label_qis(qi_num=PQ05, qi_name=PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate);
 %label_qis(qi_num=PQ07, qi_name=PQI 07 Hypertension Admission Rate);
 %label_qis(qi_num=PQ08, qi_name=PQI 08 Heart Failure Admission Rate);
 %label_qis(qi_num=PQ11, qi_name=PQI 11 Community-Acquired Pneumonia Admission Rate);
 %label_qis(qi_num=PQ12, qi_name=PQI 12 Urinary Tract Infection Admission Rate);
 %label_qis(qi_num=PQ14, qi_name=PQI 14 Uncontrolled Diabetes Admission Rate);
 %label_qis(qi_num=PQ15, qi_name=PQI 15 Asthma in Younger Adults Admission Rate);
 %label_qis(qi_num=PQ16, qi_name=PQI 16 Lower-Extremity Amputation Among Patients with Diabetes Rate);
 %label_qis(qi_num=PQ90, qi_name=PQI 90 Prevention Quality Overall Composite);
 %label_qis(qi_num=PQ91, qi_name=PQI 91 Prevention Quality Acute Composite);
 %label_qis(qi_num=PQ92, qi_name=PQI 92 Prevention Quality Chronic Composite);
 %label_qis(qi_num=PQ93, qi_name=PQI 93 Prevention Quality Diabetes Composite);


 * ------------------------------------------------------------------ ;
 * --- PQI 01 : DIABETES SHORT-TERM COMPLICATIONS ADMISSION RATE  --- ;
 * ------------------------------------------------------------------ ;

   if %MDX1($ACDIASD.) then

        TAPQ01 = 1;


 * ----------------------------------------------------------------- ;
 * --- PQI 03 : DIABETES LONG-TERM COMPLICATIONS ADMISSION RATE  --- ;
 * ----------------------------------------------------------------- ;

   if %MDX1($ACDIALD.) then

        TAPQ03 = 1;


 * ------------------------------------------------------------------------------------------------------ ;
 * --- PQI 05 : CHRONIC OBSTRUCTIVE PULMONARY DISEASE (COPD) OR ASTHMA IN OLDER ADULTS ADMISSION RATE --- ;
 * ------------------------------------------------------------------------------------------------------ ;

   if AGE ge 40 then do;
     if %MDX1($ACCOPDD.) or %MDX1($ACSASTD.)

        then do;  TAPQ05 = 1;

   *** Exclude Cystic Fibrosis and Anomalies
          of the Respiratory System;

      if %MDX($RESPAN.) then TAPQ05 = .;
     end;

   end;

 * ------------------------------------------------ ;
 * --- PQI 07 : HYPERTENSION ADMISSION RATE     --- ;
 * ------------------------------------------------ ;

   if %MDX1($ACSHYPD.) then do;

        TAPQ07 = 1;

      ***Exclude Stage I-IV Kidney Disease
         with dialysis access procedures;
      if %MDX($ACSHY2D.) and %MPR($DIALY2P.)
      then TAPQ07 = .;

      *** Exclude Cardiac Procedures;
      if %MPR($ACSCARP.) then TAPQ07 = .;

   end;


 * -------------------------------------------------- ;
 * --- PQI 08 : HEART FAILURE ADMISSION RATE      --- ;
 * -------------------------------------------------- ;

   if %MDX1($MRTCHFD.) then do;

      TAPQ08 = 1;

      *** Exclude Cardiac Procedures;
      if %MPR($ACSCARP.) then TAPQ08 = .;

   end;


 * ------------------------------------------------------------ ;
 * --- PQI 11 : COMMUNITY-ACQUIRED PNEUMONIA ADMISSION RATE --- ;
 * ------------------------------------------------------------ ;

   if %MDX1($ACSBACD.) then do;

      TAPQ11 = 1;

      *** Exclude: Sickle Cell;
      if %MDX($ACSBA2D.)  then TAPQ11 = .;

      *** Exclude Immunocompromised state;
      if %MDX($IMMUNID.) or %MPR($IMMUNIP.)
      then TAPQ11 = .;

   end;


 * ------------------------------------------------------- ;
 * --- PQI 12 : URINARY TRACT INFECTION ADMISSION RATE --- ;
 * ------------------------------------------------------- ;

   if  %MDX1($ACSUTID.) then do;

      TAPQ12 = 1;

      *** Exclude Immunocompromised state and
          Kidney/Urinary Tract Disorder;
      if %MDX($IMMUNID.) or %MPR($IMMUNIP.) or
         %MDX($KIDNEY.)
      then TAPQ12 = .;

   end;


 * ----------------------------------------------------- ;
 * --- PQI 14 : UNCONTROLLED DIABETES ADMISSION RATE --- ;
 * ----------------------------------------------------- ;

   if %MDX1($ACDIAUD.) then

      TAPQ14 = 1;


 * ----------------------------------------------------------------- ;
 * --- PQI 15 : ASTHMA IN YOUNGER ADULTS DIABETES ADMISSION RATE --- ;
 * ----------------------------------------------------------------- ;

   if %MDX1($ACSASTD.) then do;

      TAPQ15 = 1;

      *** Exclude Cystic Fibrosis and Anomalies
          of the Respiratory System;
      if %MDX($RESPAN.) then TAPQ15 = .;

      if AGE ge 40 then TAPQ15 = .;

   end;


 * ----------------------------------------------------------------------------- ;
 * --- PQI 16 : LOWER-EXTREMITY AMPUTATION AMONG PATIENTS WITH DIABETES RATE --- ;
 * ----------------------------------------------------------------------------- ;

   if %MPR($ACSLEAP.) and %MDX($ACSLEAD.) then do;

      TAPQ16 = 1;

      *** Exclude: MDC 14;
      if %MDX1($MDC14PRINDX.) then TAPQ16 = .;

      *** Exclude: Trauma;
      if %MDX($ACLEA2D.) then TAPQ16 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AREA LEVEL COMPOSITE INDICATORS ---------------- ;
 * -------------------------------------------------------------- ;

 * ----------------------------------------------------- ;
 * --- PQI 90 : PREVENTION QUALITY OVERALL COMPOSITE --- ;
 * ----------------------------------------------------- ;

   if TAPQ01 = 1 or TAPQ03 = 1 or TAPQ05 = 1 or TAPQ07 = 1 or
      TAPQ08 = 1 or TAPQ11 = 1 or TAPQ12 = 1 or
      TAPQ14 = 1 or TAPQ15 = 1 or TAPQ16 = 1
   then
   TAPQ90 = MAX(OF TAPQ01 TAPQ03 TAPQ05 TAPQ07
                   TAPQ08 TAPQ11 TAPQ12
                   TAPQ14 TAPQ15 TAPQ16);

 * --------------------------------------------------- ;
 * --- PQI 91 : PREVENTION QUALITY ACUTE COMPOSITE --- ;
 * --------------------------------------------------- ;

   if TAPQ11 = 1 or TAPQ12 = 1
   then
   TAPQ91 = MAX(OF TAPQ11 TAPQ12);

 * ----------------------------------------------------- ;
 * --- PQI 92 : PREVENTION QUALITY CHRONIC COMPOSITE --- ;
 * ----------------------------------------------------- ;

   if TAPQ01 = 1 or TAPQ03 = 1 or TAPQ05 = 1 or TAPQ07 = 1 or
      TAPQ08 = 1 or TAPQ14 = 1 or TAPQ15 = 1 or
      TAPQ16 = 1
   then
   TAPQ92 = MAX(OF TAPQ01 TAPQ03 TAPQ05 TAPQ07
                   TAPQ08 TAPQ14 TAPQ15
                   TAPQ16);

 * ------------------------------------------------------ ;
 * --- PQI 93 : PREVENTION QUALITY DIABETES COMPOSITE --- ;
 * ------------------------------------------------------ ;

   IF TAPQ01 = 1 OR TAPQ03 = 1 OR TAPQ14 = 1 OR TAPQ16 = 1
   THEN
   TAPQ93 = MAX(OF TAPQ01 TAPQ03 TAPQ14 TAPQ16);


 * -------------------------------------------------------------- ;
 * --- EXCLUDE TRANSFERS ---------------------------------------- ;
 * -------------------------------------------------------------- ;

 * --- Transfers from SNFs, inpatient rehab, or acute hospitals --;
 if ASOURCE in (2,3) or POINTOFORIGINUB04 in ('4','5','6')
 then do;
   TAPQ01 = .;
   TAPQ03 = .;
   TAPQ05 = .;
   TAPQ07 = .;
   TAPQ08 = .;
   TAPQ11 = .;
   TAPQ12 = .;
   TAPQ14 = .;
   TAPQ15 = .;
   TAPQ16 = .;
   TAPQ90 = .;
   TAPQ91 = .;
   TAPQ92 = .;
   TAPQ93 = .;
 end;

run;

 * ------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MEASURES OUTPUT FILE      --- ;
 * ------------------------------------------------------- ;

proc contents DATA=OUTMSR.&OUTFILE_MEAS. position;
run;

***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM proc means STATEMENTS -------***;

proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss min max NOLABELS ;
     var DRG MDC YEAR DQTR
         AGECAT AGECCAT POPCAT SEXCAT RACECAT;
     title4 "PREVENTION QUALITY INDICATOR CATEGORICAL VARIABLES AND RANGES OF VALUES";
run; quit;

proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss sum mean NOLABELS ;
     var TAPQ01 TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ11 TAPQ12 TAPQ14-TAPQ16 TAPQ90-TAPQ93;
     title5 "PREVENTION QUALITY INDICATOR NUMERATORS (COUNT=SUM)";
run; quit;
