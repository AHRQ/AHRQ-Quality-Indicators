* ======================= Program: PDI_ALL_MEASURES.SAS =============================;
*
*  DESCRIPTION:
*     Assigns the Pediatric Quality Indicators outcomes to inpatient records.
*     Variables created by this program are TPPDXX, TPPS17, TAPDXX, GPPXX, 
*     and stratifiers.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*  USER NOTE1: Make sure you have created the format library
*              using PDI_FORMATS.SAS BEFORE running this program. 
*              This is done through the CONTROL program.
*
*  USER NOTE2: The AHRQ QI software does not support the calculation of
*              weighted estimates and standard errors using complex
*              sampling designs.
*
*  USER NOTE3: See the AHRQ_PDI_SAS_v2024_ICD10_Release_Notes.txt file for 
*              software change notes.
*
*  USER NOTE4: Although some of the exclusion criteria for present on admission 
*              conditions were removed from v2020, some of the original logic
*              is retained for potential use in future versions.
*
* ===================================================================================;

 title2 'PDI_ALL_MEASURES PROGRAM';
 title3 'AHRQ PEDIATRIC QUALITY INDICATORS: ASSIGN PDIs TO INPATIENT DATA';

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
 * --- VALUES ARE MISSING. REVIEW AFTER RUNNING PDI_ALL_MEASURES. --- ;
 * --- CHECK MDC FOR HOSPITAL-LEVEL PDI.                          --- ;
 * ------------------------------------------------------------------ ;

 data OUTMSR.&DELFILE.
   (keep=KEY HOSPID SEX AGE DX1 DRG MDC YEAR DQTR);
 set  INMSR.&DISCHARGE.;
 if (AGE lt 0) or (AGE ge 18 or %MDX1($MDC14PRINDX.)) or (missing(SEX)) or
    (missing(DX1)) or (missing(DQTR)) or (missing(YEAR)) or (DRG = 999);
 run;
 
 * -------------------------------------------------------------- ;
 * --- PEDIATRIC QUALITY INDICATOR (PDI) NAMING CONVENTION:   --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PEDIATRIC INDICATOR    --- ;
 * --- AS ONE OF THE FOLLOWING:                               --- ;
 * ---          (T) NUMERATOR ("TOP")                         --- ;
 * ---          (G) MEASURE SPECIFIC STRATIFICATION ("GROUP") --- ;
 * --- THE SECOND LETTER IDENTIFIES THE PDI AS A HOSPITAL (P) --- ;
 * --- OR AN AREA (A) LEVEL INDICATOR.  THE NEXT TWO          --- ;
 * --- CHARACTERS ARE 'PD' OR 'NQ'. THE LAST TWO DIGITS ARE   --- ;
 * --- THE INDICATOR NUMBER.                                  --- ;
 * -------------------------------------------------------------- ;

data   OUTMSR.&OUTFILE_MEAS.
    (keep=KEY HOSPID FIPSTCO DRG MDC MDRG YEAR DQTR AGE AGEDAY SEX
          TRNSFER TRNSFER_ALT D_DXCCSR_: ODC903 MEDICDR COVIDDX
          PAGECAT AGEDCAT POPCAT BWHTCAT SEXCAT RACECAT PAYCAT LOS
          CMR_AIDS         CMR_ALCOHOL      CMR_ANEMDEF      CMR_AUTOIMMUNE  CMR_BLDLOSS      CMR_CANCER_LYMPH CMR_CANCER_LEUK
          CMR_CANCER_METS  CMR_CANCER_NSITU CMR_CANCER_SOLID CMR_CBVD        CMR_COAG         CMR_DEMENTIA     CMR_DEPRESS      CMR_DIAB_CX
          CMR_DIAB_UNCX    CMR_DRUG_ABUSE   CMR_HF           CMR_HTN_CX      CMR_HTN_UNCX     CMR_LIVER_MLD    CMR_LIVER_SEV    CMR_LUNG_CHRONIC
          CMR_NEURO_MOVT   CMR_NEURO_OTH    CMR_NEURO_SEIZ   CMR_OBESE       CMR_PARALYSIS    CMR_PERIVASC     CMR_PSYCHOSES    CMR_PULMCIRC
          CMR_RENLFL_MOD   CMR_RENLFL_SEV   CMR_THYROID_HYPO CMR_THYROID_OTH CMR_ULCER_PEPTIC CMR_VALVE        CMR_WGHTLOSS
          TPPD01 TPPD05 TPPD08--TPPD10 TPPD12 TPPS17
          TPNQ03
          TAPD14--TAPD16 TAPD18 TAPD90--TAPD92
          GPPD08 GPPD10 GPPD12
          HPPD01 HPPD10 &OUTFILE_KEEP
        );

 set   INMSR.&DISCHARGE.
      (keep=KEY HOSPID DRG MDC SEX AGE AGEDAY PSTCO
            YEAR DQTR DISP LOS ASOURCE POINTOFORIGINUB04 ATYPE
            DX1-DX&NDX. PR1-PR&NPR. %ADDPRDAY_PAY1_RACE
            DXPOA1-DXPOA&NDX. &OUTFILE_KEEP);

 label
 HOSPID = 'Hospital Identification Number'
 AGEDAY = 'Age in days for patients less than 1 year old'
 SEX = 'Sex of the patient'
 key = 'Unique record identifier'
 ;

 ARRAY PR (&NPR.) $  PR1 - PR&NPR.;
 ARRAY DX (&NDX.) $  DX1 - DX&NDX.;
 ARRAY DXPOA (&NDX.) $  DXPOA1 - DXPOA&NDX.;

 * ----------------------------------------------------------------- ;
 * --- DEFINE ODC903                                             --- ;
 * ----------------------------------------------------------------- ;
 
 if %MDX($ODC_VEN.) then ODC903=1; else ODC903=0;
 label ODC903 = 'Ventilator Dependence flag';


 * ----------------------------------------------------------------- ;
 * --- DELETE NON-PEDIATRIC RECORDS AND RECORDS WITH MISSING VALUES  ;
 * --- FOR AGE, SEX, DX1, DQTR, YEAR OR DRG = 999                --- ;
 * ----------------------------------------------------------------- ;

 if missing(SEX) then delete;
 if AGE lt 0 then delete;
 if AGE ge 18 or %MDX1($MDC14PRINDX.) then delete;
 if missing(DX1) then delete;
 if missing(DQTR) then delete;
 if missing(YEAR) then delete;
 if DRG = 999 then delete;


 * -------------------------------------------------------------- ;
 * --- DEFINE FIPS STATE AND COUNTY CODES             ----------- ;
 * -------------------------------------------------------------- ;

 attrib FIPSTCO length=$5
   label='FIPS State County Code';
 FIPSTCO = put(PSTCO,Z5.);


 * -------------------------------------------------------------- ;
 * --- DEFINE ICD-10-CM VERSION          ------------------------ ;
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
 * --- DEFINE MEDICAL DRGS               ------------------------ ;
 * -------------------------------------------------------------- ;
 
 attrib MEDICDR length=3
   label='MEDICAL DRGS';

 if %MDR($MEDIC2R.) then MEDICDR = 1;
 else MEDICDR = 0;


 * -------------------------------------------------------------- ;
 * --- DEFINE SURGICAL DRGS              ------------------------ ;
 * -------------------------------------------------------------- ;
 
 attrib SURGIDR length=3
   label='SURGICAL DRGS';

 if %MDR($SURGI2R.) then SURGIDR = 1;
 else SURGIDR = 0;


 * -------------------------------------------------------------- ;
 * --- REASSIGN FISCAL YEAR DEPENDENT DRGS ---------------------- ;
 * -------------------------------------------------------------- ;
 
 if %MDR($SURGI2R_PREV.) and ICDVER < 38 then do;
   SURGIDR = 1;
   MEDICDR = 0;
 end;
 

 * -------------------------------------------------------------- ;
 * --- DEFINE MODIFIED DRGS              ------------------------ ;
 * -------------------------------------------------------------- ;
 
 attrib MDRG length=4
   label='Modified DRG';

 MDRG = put(put(DRG,Z3.),$DRGF2T.);


 * -------------------------------------------------------------- ;
 * --- DEFINE INFECTION RISK CATEGORIES  ------------------------ ;
 * -------------------------------------------------------------- ;
 
 attrib DRG1C length=3
   label='CLEAN';
 attrib DRG2C length=3
   label='CLEAN CONTAMINATED';
 attrib DRG3C length=3
   label='POTENTIALLY CONTAMINATED';
 attrib DRG4C length=3
   label='LIKELY INFECTED';
 attrib DRG9C length=3
   label='SURGICAL PROCEDURES NOT SPECIFIED';

 DRG1C = put(MDRG,DRG1C.);
 DRG2C = put(MDRG,DRG2C.);
 DRG3C = put(MDRG,DRG3C.);
 DRG4C = put(MDRG,DRG4C.);
 DRG9C = put(MDRG,DRG9C.);


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
 attrib PAGECAT length=3
   label='Pediatric Age Categories';

 select;
   when (0  <= AGE <  1)  PAGECAT = 1;
   when (1  <= AGE <  3)  PAGECAT = 2;
   when (3  <= AGE <  6)  PAGECAT = 3;
   when (6  <= AGE < 13)  PAGECAT = 4;
   when (13 <= AGE < 18)  PAGECAT = 5;
   otherwise PAGECAT = 0;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: AGEDAY CATEGORY  ---------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib AGEDCAT length=3
   label   = 'Age in Days Categories';

 select;
   when (      AGEDAY <   0)  AGEDCAT = 0;
   when (0  <= AGEDAY <= 28)  AGEDCAT = 1;
   when (29 <= AGEDAY <= 60)  AGEDCAT = 2;
   when (61 <= AGEDAY <= 90)  AGEDCAT = 3;
   when (91 <= AGEDAY      )  AGEDCAT = 4;
   otherwise AGEDCAT = 0;
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
 * --- DEFINE STRATIFIER: POPULATION CATEGORY ------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib POPCAT length=3
   label = 'Population Age Categories';

 POPCAT=put(AGE,AGEFMT.);


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: BIRTH WEIGHT CATEGORY  ---------------- ;
 * -------------------------------------------------------------- ;
 
 attrib BWHTCAT length=3
     label  = 'Birth Weight Categories';

 %MACRO BWHT;

 BWHTCAT = 0;
 %DO I = 1 %TO &NDX.;
    if put(DX&I.,$LW500G.)  = '1'      then BWHTCAT = 1;
    else if put(DX&I.,$LW750G.)  = '1' and (BWHTCAT = 0 or  BWHTCAT > 2) then BWHTCAT = 2;
    else if put(DX&I.,$LW1000G.) = '1' and (BWHTCAT = 0 or  BWHTCAT > 3) then BWHTCAT = 3;
    else if put(DX&I.,$LW1250G.) = '1' and (BWHTCAT = 0 or  BWHTCAT > 4) then BWHTCAT = 4;
    else if put(DX&I.,$LW1500G.) = '1' and (BWHTCAT = 0 or  BWHTCAT > 5) then BWHTCAT = 5;
    else if put(DX&I.,$LW1750G.) = '1' and (BWHTCAT = 0 or  BWHTCAT > 6) then BWHTCAT = 6;
    else if put(DX&I.,$LW2000G.) = '1' and (BWHTCAT = 0 or  BWHTCAT > 7) then BWHTCAT = 7;
    else if put(DX&I.,$LW2500G.) = '1' and (BWHTCAT = 0 or  BWHTCAT > 8) then BWHTCAT = 8;
 %END;

 %MEND;

 %BWHT;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: GESTATIONAL AGE CATEGORY -------------- ;
 * -------------------------------------------------------------- ;
 
 attrib GESTCAT length=3
   label='PATIENT GESTATIONAL AGE';

 %MACRO GEST;

 GESTCAT = 0;
 %DO I = 1 %TO &NDX.;
    if put(DX&I.,$GESTC1D.)  = '1'     then GESTCAT = 1;
    else if put(DX&I.,$GESTC2D.) = '1' and (GESTCAT = 0 or GESTCAT > 2) then GESTCAT = 2;
    else if put(DX&I.,$GESTC3D.) = '1' and (GESTCAT = 0 or GESTCAT > 3) then GESTCAT = 3;
    else if put(DX&I.,$GESTC4D.) = '1' and (GESTCAT = 0 or GESTCAT > 4) then GESTCAT = 4;
    else if put(DX&I.,$GESTC5D.) = '1' and (GESTCAT = 0 or GESTCAT > 5) then GESTCAT = 5;
    else if put(DX&I.,$GESTC6D.) = '1' and (GESTCAT = 0 or GESTCAT > 6) then GESTCAT = 6;
    else if put(DX&I.,$GESTC7D.) = '1' and (GESTCAT = 0 or GESTCAT > 7) then GESTCAT = 7;
    else if put(DX&I.,$GESTC8D.) = '1' and (GESTCAT = 0 or GESTCAT > 8) then GESTCAT = 8;
 %END;

 %MEND;

 %GEST;


 * -------------------------------------------------------------- ;
 * --- COUNT OR PROCEDURES AND IDENTIFY FIRST OR PROCEDURE ------ ;
 * -------------------------------------------------------------- ;
 
 attrib ORCNT length=8
   label='OR PROCEDURE COUNT';

 attrib ORDAY length=8
   label='OR PROCEDURE DAY';

 %ORCNT;


 * -------------------------------------------------------------- ;
 * --- DEFINE RISK VARIABLE: PROCEDURE TYPE --------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib HPPD01 length=3
   label='RISK CLASS FOR PDI 01';

 attrib HPPD10 length=3
   label='RISK CLASS FOR PDI 10';

 %PCLASSR;


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
 * --- DEFINE HOSPITAL AND AREA LEVEL INDICATORS ---------------- ;
 * -------------------------------------------------------------- ;
 
 %macro label_qis(flag=, qi_num=, qi_name=);
   attrib T&qi_num. length=8
   label = "&qi_name. (Numerator)"
   ;

  *** Re-label day dependent indicators ***;
   %IF &PRDAY. = 0 AND &flag. = 1 %THEN %DO;
    label
    T&qi_num. = "&qi_name.-NO PRDAY (Numerator)"
    ;
   %END;

 %mend label_qis;

 %label_qis(flag=0, qi_num=PPD01, qi_name=PDI 01 Accidental Puncture or Laceration Rate);
 %label_qis(flag=0, qi_num=PPD05, qi_name=PDI 05 Iatrogenic Pneumothorax Rate);
 %label_qis(flag=1, qi_num=PPD08, qi_name=PDI 08 Postoperative Hemorrhage or Hematoma Rate);
 %label_qis(flag=1, qi_num=PPD09, qi_name=PDI 09 Postoperative Respiratory Failure Rate);
 %label_qis(flag=0, qi_num=PPD10, qi_name=PDI 10 Postoperative Sepsis Rate);
 %label_qis(flag=0, qi_num=PPD12, qi_name=PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate);
 %label_qis(flag=0, qi_num=PPS17, qi_name=PSI 17 Birth Trauma Rate - Injury to Neonate);
 %label_qis(flag=0, qi_num=PNQ03, qi_name=NQI 03 Neonatal Blood Stream Infection Rate);
 %label_qis(flag=0, qi_num=APD14, qi_name=PDI 14 Asthma Admission Rate);
 %label_qis(flag=0, qi_num=APD15, qi_name=PDI 15 Diabetes Short-Term Complications Admission Rate);
 %label_qis(flag=0, qi_num=APD16, qi_name=PDI 16 Gastroenteritis Admission Rate);
 %label_qis(flag=0, qi_num=APD18, qi_name=PDI 18 Urinary Tract Infection Admission Rate);
 %label_qis(flag=0, qi_num=APD90, qi_name=PDI 90 Pediatric Quality Overall Composite);
 %label_qis(flag=0, qi_num=APD91, qi_name=PDI 91 Pediatric Quality Acute Composite);
 %label_qis(flag=0, qi_num=APD92, qi_name=PDI 92 Pediatric Quality Chronic Composite);


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIERS                  ---------------------- ;
 * -------------------------------------------------------------- ;
 
  attrib
  GPPD08 length=3
   label='Strata for PDI 08'
  GPPD10 length=3
   label='Strata for PDI 10'
  GPPD12 length=3
   label='Strata for PDI 12'
 ;

 * -------------------------------------------------------------- ;
 * --- IDENTIFY NEONATES AND NEWBORNS --------------------------- ;
 * -------------------------------------------------------------- ;

   NEONATE = 0;
   if 0 <= AGEDAY <= 28 then NEONATE = 1;
   else if AGEDAY le .Z and AGE = 0 then do;
      if ATYPE in (4) or %MDX($LIVEBND.)
      then NEONATE = 1;
   end;

   NEWBORN = 0;
   if NEONATE then do;
      if %MDX($LIVEBND.) and NOT AGEDAY > 0 then NEWBORN = 1;
      else if ATYPE in (4) and
              ((AGEDAY = 0 and NOT %MDX($LIVEB2D.)) or
               POINTOFORIGINUB04 in ('5'))
      then NEWBORN = 1;
   end;

   NORMAL = 0;
   if NEWBORN and (DRG in (795))
   then NORMAL = 1;

   OUTBORN = 0;
   if NEONATE and NOT NEWBORN then do;
      if (0 <= AGEDAY < 2) or
         (ATYPE in (4) and
          (AGEDAY le .Z or POINTOFORIGINUB04 in ('6')))
      then OUTBORN = 1;
   end;

 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AHRQ COMORBIDITY ------------------------------- ;
 * -------------------------------------------------------------- ;

 %include MacLib(PDI_Comorb_Code_v2024.sas);


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT CCSR VARIABLES                 ----------------- ;
 * -------------------------------------------------------------- ;

 %include MacLib(PDI_CCSR_Code_v2024.sas);


 * --- CONSTRUCT HOSPITAL LEVEL INDICATORS ---------------------- ;

 * -------------------------------------------------------------- ;
 * --- PDI 01 : ACCIDENTAL PUNCTURE OR LACERATION             --- ;
 * -------------------------------------------------------------- ;

   if MEDICDR or SURGIDR then do;

      TPPD01 = 0; QPPD01 = 0;

      if %MDX2($TECHNID.) then TPPD01 = 1;

      *** Exclude principal diagnosis;

      if %MDX1($TECHNID.) then TPPD01 = .;
      if %MDX2Q2($TECHNID.) then QPPD01 = 1;

      *** Exclude spine surgery;

      if %MPR($SPINEP.) then TPPD01 = .;

      *** Exclude Normal Newborn;

      if NORMAL then TPPD01 = .;

      *** Exclude Neonate < 500g;

      if NEONATE and BWHTCAT in (1) then TPPD01 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPD01 = . then QPPD01 = .;

     *** Stratify by risk category (MDC)
         1 - Eye, ear, nose, mouth, throat, skin, breast and other low-risk procedures
         2 - Thoracic, cardiovascular, and specified neoplastic procedures
         3 - Kidney, and male/female reproductive procedures
         4 - Infectious, immunological, hematological, and ungroupable procedures
         5 - Trauma, orthopedic, and neurologic procedures
         6 - Gastrointestinal, hepatobiliary, and endocrine procedures;

     *** Risk adjust by risk category (Procedure Type)
         1 - No therapeutic procedure with any or no diagnostic procedures
         2 - Only minor therapeutic procedure with any or no diagnostic procedures 
         3 - One major therapeutic without diagnostic procedure
         4 - One major therapeutic with only minor diagnostic procedure(s)
         5 - One major therapeutic with major diagnostic procedure(s) 
         6 - Two major therapeutic procedures with any or no diagnostic procedures 
         7 - Three or more major therapeutic procedures with any or no diagnostic procedures;

      if TPPD01 NE . then do;
         if PRCLS2 = 0 and PRCLS4 = 0                     then HPPD01 = 1;
         else if PRCLS4 = 0  and PRCLS2 > 0               then HPPD01 = 2;
         else if PRCLS1 = 0 and PRCLS3 = 0 and PRCLS4 = 1 then HPPD01 = 3;
         else if PRCLS3 = 0 and PRCLS4 = 1 and PRCLS1 > 0 then HPPD01 = 4;
         else if PRCLS4 = 1 and PRCLS3 > 0                then HPPD01 = 5;
         else if PRCLS4 = 2                               then HPPD01 = 6;
         else if PRCLS4 >= 3                              then HPPD01 = 7;
         else                                                  HPPD01 = 9;
      end;

    end;


 * ---------------------------------------------- ;
 * --- PDI 05 : IATROGENIC PNEUMOTHORAX RATE  --- ;
 * ---------------------------------------------- ;

   if MEDICDR or SURGIDR then do;

      TPPD05 = 0; QPPD05 = 0;

      if %MDX2($IATROID.) then TPPD05 = 1;

      *** Exclude principal diagnosis;

      if %MDX1($IATPTXD.) then TPPD05 = .;
      if %MDX2Q2($IATPTXD.) then QPPD05 = 1;

      *** Exclude Chest Trauma, Pleural effusion;

      if %MDX($CTRAUMD.) or %MDX($PLEURAD.)
      then TPPD05 = .;

      *** Exclude Thoracic surgery, Lung or pleural biopsy,
          Cardiac surgery or Diaphragmatic surgery repair;

      if %MPR($THORAIP.) or %MPR($CARDSIP.)
      then TPPD05 = .;

      *** Exclude normal newborn;

      if NORMAL then TPPD05 = .;

      *** Exclude Neonate < 2500g;

      if NEONATE and BWHTCAT in (1,2,3,4,5,6,7,8) then TPPD05 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPD05 = . then QPPD05 = .;

 end;


  * ---------------------------------------------------------- ;
  * --- PDI 08 : POSTOPERATIVE HEMORRHAGE OR HEMATOMA RATE --- ;
  * ---------------------------------------------------------- ;

   %MACRO PD8;

   if (&PRDAY. = 1 and ORDAY NE . and MPRDAY NE .) then do;

      if MPRDAY < ORDAY then TPPD08 = .;

   end;

   %MEND;

   if SURGIDR and ORCNT > 0 and ATYPE in (3) then do;

      TPPD08 = 0; QPPD08 = 0;

      if (%MDX2($POHMRI2D.) and %MPR($HEMOTH2P.))
      then TPPD08 = 1;

      *** Exclude principal diagnosis;

      if %MDX1($POHMRI2D.) then TPPD08 = .;
      if %MDX2Q2($POHMRI2D.) then QPPD08 = 1;

      *** Exclude if control of post-operative hemorrhage or Miscellaneous Hemorrhage or
          hematoma-related procedure are the only OR procedures;

      %MPRCNT($HEMOTH2P.);
      if ORCNT = MPRCNT then TPPD08 = .;

      *** Exclude if control of post-operative hemorrhage or Miscellaneous Hemorrhage or
          hematoma-related procedure occurs before the first OR procedure;

      %ORDAY($HEMOTH2P.);
      %MPRDAY($HEMOTH2P.);
      %PD8;

      *** Exclude Neonate < 500g;

      if NEONATE and BWHTCAT in (1) then TPPD08 = .;


      *** Determine numerator exclusion for secondary Dx POA;

      if TPPD08 = . then QPPD08 = .;

     *** Stratify by risk category (1-Low risk, 2-High risk);

      if %MDX2Q2($MEDBLEEDD.) then MEDBLEEDD_cd=1;

      if TPPD08 NE . then do;
         if %MDX($COAGDID.) or %MPR($ECMOP.) or %MDX1($MEDBLEEDD.) or MEDBLEEDD_cd=1 then GPPD08 = 2;
         else GPPD08 = 1;
      end;

     end;


   * ------------------------------------------------------- ;
   * --- PDI 09 : POSTOPERATIVE RESPIRATORY FAILURE RATE --- ;
   * ------------------------------------------------------- ;

   %MACRO PD9N(FMT, DAYS);

      %MPRDAY_LAST(&FMT.);

      if (&PRDAY. = 1  and ORDAY NE . and MPRDAY_LAST NE .) then do;

         if MPRDAY_LAST >= ORDAY + &DAYS. then TPPD09 = 1;

      end;

   %MEND;

   %MACRO PD9;

      if (&PRDAY. = 1  and ORDAY NE . and MPRDAY NE .) then do;

         if MPRDAY < ORDAY then TPPD09 = .;

      end;

   %MEND;

   if SURGIDR and ORCNT > 0 and ATYPE in (3) then do;

      TPPD09 = 0; QPPD09 = 0;

      if %MDX2($ACURF2D.) then TPPD09 = 1;

      *** Include in numerator if reintubation procedure occurs on the same day or
          # days after the first OR procedure;

      %ORDAY($BLANK.);
      %PD9N($PR9604P., 1);
      %PD9N($PR9671P., 2);
      %PD9N($PR9672P., 0);

     *** Exclude principal diagnosis;

      if %MDX1($ACURF3D.) then TPPD09 = .;
      if %MDX2Q2($ACURF3D.) then QPPD09 = 1;

      *** Exclude if tracheostomy procedure is the only OR procedure;

      %MPRCNT($TRACHIP.);
      if ORCNT = MPRCNT then TPPD09 = .;

      *** Exclude if tracheostomy procedure occurs before the
          first OR procedure;

      %ORDAY($TRACHIP.);
      %MPRDAY($TRACHIP.);
      %PD9;

      *** Exclude Malignant Hyperthermia;

      if %MDX($MALHYPD.) then TPPD09 = .;

      *** Exclude Neuromuscular disorders;

      if %MDXAQ2($NEUROMD.) then TPPD09 = .;

      *** Exclude Tracheostomy;

      if %MDXAQ2($TRACHID.) then TPPD09 = .;

      *** Exclude MDC 4;

      if MDC in (4) then TPPD09 = .;

      *** Exclude laryngeal, pharyngeal, nose, mouth, or facial surgery,
              or craniofacial anomalies;

      if %MPR($NUCRANP.) or %MDX($CRANIID.)
      then TPPD09 = .;

      *** Exclude Neonate < 500g;

      if NEONATE and BWHTCAT in (1) then TPPD09 = .;

      *** Exclude Esophageal resection Procedure;

      if %MPR($PRESOPP.) then TPPD09 = .;

      *** Exclude Lung Cancer Procedure;

      if %MPR($LUNGCIP.) then TPPD09 = .;

      *** Exclude diagnosis of Degenerative neurological disorder;

      if %MDXAQ2($DGNEUID.) then TPPD09 = .;

      *** Exclude Hospitalizations involving lung transplantations;

      if %MPR($LUNGTRANSP.) then TPPD09 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPD09 = . then QPPD09 = .;

   end;


 * ------------------------------------------ ;
 * --- PDI 10 : POSTOPERATIVE SEPSIS RATE --- ;
 * ------------------------------------------ ;

      if SURGIDR and ORCNT > 0 then do;

      TPPD10 = 0; QPPD10 = 0;

      if %MDX2($SEPTI2D.) then TPPD10 = 1;

      *** Exclude principal diagnosis;

      if %MDX1($SEPTI2D.) then TPPD10 = .;
      if %MDX2Q2($SEPTI2D.) then QPPD10 = 1;


      *** Exclude Infection;

      if %MDX1($INFECID.) then TPPD10 = .;

      *** Exclude DRG in surgical class 4;

      if DRG4C then TPPD10 = .;

      *** Exclude Neonate;

      if NEONATE then TPPD10 = .;

      *** Exclude if the first OR procedure occurs after or on 10th day from the admission;

      %MPRDAY($ORPROC.);
      if MPRDAY >=10 then TPPD10 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPD10 = . then QPPD10 = .;

      *** Stratify by procedure type (1-Low risk to 4-High risk, and 9);

      if TPPD10 NE . then do;
         if DRG1C then do;
            if ATYPE in (3) then GPPD10 = 1; else GPPD10 = 2;
         end;
         else if DRG2C or DRG3C then do;
            if ATYPE in (3) then GPPD10 = 3; else GPPD10 = 4;
         end;
         else if DRG9C then do;
            if ATYPE in (3) then GPPD10 = 5; else GPPD10 = 6;
         end;
         else GPPD10 = 9;
      end;

      *** Risk adjust by risk category (0-Low risk, 1-Intermediate risk, 2-High risk, 3-Very high risk);

      if TPPD10 NE . then do;
         if %MDXAQ2($IMMUNHD.) then flag_IMMUNHD=1; 
         if %MPR($TRANSPP.)    then flag_TRANSPP=1;
         if %MDXAQ2($IMMUITD.) then flag_IMMUITD=1;
         if %MDXAQ2($HEPFA2D.) then flag_HEPFA2D=1;
         if %MDXAQ2($HEPFA3D.) then flag_HEPFA3D=1;

         if flag_HEPFA3D=1 or flag_TRANSPP=1 then HPPD10=3; 
         else if flag_IMMUNHD=1  then HPPD10 = 2;
         else if flag_IMMUITD=1 or flag_HEPFA2D=1 then HPPD10 = 1; 
         else HPPD10 = 0;
      end;

   end;


 * ----------------------------------------------------- ;
 * --- PDI 12 : CENTRAL VENOUS CATH RELATED BSI RATE --- ;
 * ----------------------------------------------------- ;

   if MEDICDR or SURGIDR then do;

      TPPD12 = 0; QPPD12 = 0;

      if %MDX2($IDTMC3D.) then TPPD12 = 1;

     *** Exclude principal diagnosis;

     if %MDX1($IDTMC3D.) then TPPD12 = .;
     if %MDX2Q2($IDTMC3D.) then QPPD12 = 1;

      *** Exclude LOS < 2;

      if LOS < 2 then TPPD12 = .;

      *** Exclude Newborn;

      if NORMAL then TPPD12 = .;

      *** Exclude Neonate < 500g;

      if NEONATE and BWHTCAT in (1) then TPPD12 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPD12 = . then QPPD12 = .;

     *** Stratify by risk category (1-Low risk, 2-Intermediate risk, 3-High risk);

      if TPPD12 NE . then do;
         if %MDX($IMMUNHD.) or %MPR($TRANSPP.) or %MDX($CANITD.) then GPPD12 = 3;
         else if %MDX($IMMUITD.) or (%MDX($HEPFA2D.) and %MDX($HEPFA3D.)) or
                 %MDX($ACSCYFD.) or %MDX($HEMOPHD.) then GPPD12 = 2;
         else GPPD12 = 1;
      end;

end;


  * ------------------------------------------------------ ;
  * --- PSI 17 : BIRTH TRAUMA RATE - INJURY TO NEONATE --- ;
  * ------------------------------------------------------ ;

   if NEWBORN then do;

      TPPS17 = 0;

      if %MDX($BIRTHID.) then TPPS17 = 1;

      *** Exclude Birth weight less than 2000g;

      if %MDX($PRETEID.) then TPPS17 = .;

     *** Exclude Osteogenesis imperfecta;

      if %MDX($OSTEOID.) then TPPS17 = .;

   end;


  * ---  CONSTRUCT NEONATAL INDICATOR  --- ;
 
  * ----------------------------------------------------- ;
  * --- NQI 03 : NEONATAL BLOOD STREAM INFECTION RATE --- ;
  * ----------------------------------------------------- ;

   if NEWBORN or OUTBORN then do;

      if BWHTCAT in (2,3,4,5)    or
         GESTCAT in (2,3,4,5)    or
         (BWHTCAT in (0,6,7,8) and
         (DISP in (20) or %MPR($ORPROC.) or %MPR($MECHVCD.) or
         ((0 <= AGEDAY < 2) and (ATYPE in (4) and POINTOFORIGINUB04 in ('6')))
         ))
      then do;

         TPNQ03 = 0; QPNQ03 = 0;

         if %MDX2($BSI5DX.) or
            (%MDX2($BSI2DX.) and %MDX2($BSI3DX.))
         then TPNQ03 = 1;

         *** Exclude principal diagnosis of Sepsis;

       if %MDX1($BSI3DX.) or %MDX1($BSI4DX.) then TPNQ03 = .;

       if %MDX2Q2($BSI3DX.) then BSI3DX_cd = 1;
       if %MDX2Q2($BSI4DX.) then BSI4DX_cd = 1;
       if BSI3DX_cd or BSI4DX_cd then QPNQ03 = 1;

       *** Exclude birth weight < 500g;

       if BWHTCAT in (1) then TPNQ03 = .;

       *** Exclude LOS < 3;

       if LOS < 3 then TPNQ03 = .;

         *** Determine numerator exclusion for secondary Dx POA;

         if TPNQ03 = . then QPNQ03 = .;

      end;

   end;

 * --- CONSTRUCT AREA LEVEL INDICATORS --- ;

 * -------------------------------------- ;
 * --- PDI 14 : ASTHMA ADMISSION RATE --- ;
 * -------------------------------------- ;

   if %MDX1($ACSASTD.) then do;

      TAPD14 = 1;

      *** Exclude Cystic Fibrosis and Anomalies of the Respiratory System;

      if %MDX($RESPAN.) then TAPD14 = .;

      *** Exclude age < 2 years;

      if AGE < 2 then TAPD14 = .;

   end;


 * ----------------------------------------------------------------- ;
 * --- PDI 15 : DIABETES SHORT-TERM COMPLICATIONS ADMISSION RATE --- ;
 * ----------------------------------------------------------------- ;

   if %MDX1($ACDIASD.) then do;

      TAPD15 = 1;

      *** Exclude age < 6 years;

      if AGE < 6 then TAPD15 = .;

   end;


 * ----------------------------------------------- ;
 * --- PDI 16 : GASTROENTERITIS ADMISSION RATE --- ;
 * ----------------------------------------------- ;

   if %MDX1($ACPGASD.) or (%MDX2($ACPGASD.) and %MDX1($ACSDEHD.)) then do;

     TAPD16 = 1;

     *** Exclude age <= 90 days;

     if 0 <= AGEDAY <= 90 or (AGEDAY < 0 and NEONATE) then TAPD16 = .;

     *** Exclude Gastrointestinal Abnormalities and Bacterial Gastroenteritis ;

     if %MDX($ACGDISD.) then TAPD16 = .;
     if %MDX($ACBACGD.) then TAPD16 = .;

   end;


 * ------------------------------------------------------- ;
 * --- PDI 18 : URINARY TRACT INFECTION ADMISSION RATE --- ;
 * ------------------------------------------------------- ;

   if %MDX1($ACSUTID.) then do;

      TAPD18 = 1;

      *** Exclude Kidney/Urinary Tract Disorder;

      if %MDX($KIDNEY.) then TAPD18 = .;

      *** Exclude High and Intermediate Risk Immunocompromised state;

      if %MDX($IMMUNHD.) or %MPR($TRANSPP.) then TAPD18 = .;
      if %MDX($IMMUITD.) or (%MDX($HEPFA2D.) and %MDX($HEPFA3D.)) then TAPD18 = .;

      *** Exclude age <= 90 days;

      if 0 <= AGEDAY <= 90 or (AGEDAY < 0 and NEONATE) then TAPD18 = .;

   end;

  
 * --- CONSTRUCT AREA LEVEL COMPOSITE INDICATORS ---------------- ;

   * ---------------------------------------------------- ;
   * --- PDI 90 : PEDIATRIC QUALITY OVERALL COMPOSITE --- ;
   * ---------------------------------------------------- ;

   if TAPD14 = 1 or TAPD15 = 1 or TAPD16 = 1 or TAPD18 = 1 then do;
      TAPD90 = MAX(OF TAPD14 TAPD15 TAPD16 TAPD18);
      if AGE < 6 then TAPD90 = .;
   end;

   * -------------------------------------------------- ;
   * --- PDI 91 : PEDIATRIC QUALITY ACUTE COMPOSITE --- ;
   * -------------------------------------------------- ;

   if TAPD16 = 1 or TAPD18 = 1 then do;
      TAPD91 = MAX(OF TAPD16 TAPD18);
      if AGE < 6 then TAPD91 = .;
   end;

   * ---------------------------------------------------- ;
   * --- PDI 92 : PEDIATRIC QUALITY CHRONIC COMPOSITE --- ;
   * ---------------------------------------------------- ;

   if TAPD14 = 1 or TAPD15 = 1 then do;
      TAPD92 = MAX(OF TAPD14 TAPD15);
      if AGE < 6 then TAPD92 = . ;
   end;



  * -------------------------------------------------------------- ;
  * --- IDENTIFY TRANSFERS --------------------------------------- ;
  * -------------------------------------------------------------- ;

  *** Flag transfers from another acute care hospital;
  TRNSFER=0 ;
  if ATYPE notin (4) and
     (ASOURCE in (2) or POINTOFORIGINUB04 in ('4'))
  then TRNSFER = 1;
  *** Alternate outborn transfer for risk adjustment;
  if ATYPE=4 then TRNSFER_ALT = OUTBORN;
    else TRNSFER_ALT = TRNSFER;

 *** Label variables;
 label
    TRNSFER  = 'TRANSFER FROM ANOTHER ACUTE CARE HOSPITAL'
    TRNSFER_ALT = 'TRANSFER FROM ACUTE - OUTBORN'
    ;


 * -------------------------------------------------------------- ;
 * --- EXCLUDE TRANSFERS ---------------------------------------- ;
 * -------------------------------------------------------------- ;

 * --- Transfers from SNFs, inpatient rehab, or acute hospitals -- ;
 if ATYPE notin (4) and
    (ASOURCE in (2,3) or POINTOFORIGINUB04 in ('4','5','6'))
 then do;
   TAPD14 = .;
   TAPD15 = .;
   TAPD16 = .;
   TAPD18 = .;
   TAPD90 = .;
   TAPD91 = .;
   TAPD92 = .;
 end;


 * ------------------------------------------------------- ;
 * --- Sync QPPD and TPPD values               ----------- ;
 * ------------------------------------------------------- ;

    if QPPD01 in (.,1) then TPPD01 = .;
    if QPPD05 in (.,1) then TPPD05 = .;
    if QPPD08 in (.,1) then TPPD08 = .;
    if QPPD09 in (.,1) then TPPD09 = .;
    if QPPD10 in (.,1) then TPPD10 = .;
    if QPPD12 in (.,1) then TPPD12 = .;
    if QPNQ03 in (.,1) then TPNQ03 = .;

 * ------------------------------------------------------- ;
 * --- EXCLUDE DISCHARGES WITH MISSING MDC           ----- ;
 * --- FROM HOSPITAL-LEVEL PDI WHEN MDC IS PROVIDED  ----- ;
 * ------------------------------------------------------- ;
 
 if &MDC_PROVIDED. = 1 and missing(MDC) then do;
    TPPS17 = .; PPPS17 = .;
    TPPD01 = .; PPPD01 = .; HPPD01 = .;
    TPPD05 = .; PPPD05 = .;
    TPPD08 = .; PPPD08 = .; GPPD08 = .;
    TPPD09 = .; PPPD09 = .;
    TPPD10 = .; PPPD10 = .; GPPD10 = .; HPPD10 = .;
    TPPD12 = .; PPPD12 = .; GPPD12 = .;
    TPNQ03 = .; PPNQ03 = .;
 end;
 
run;

 * ------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MEASURES OUTPUT FILE      --- ;
 * ------------------------------------------------------- ;

proc contents data=OUTMSR.&OUTFILE_MEAS. position;
run;

proc print data=OUTMSR.&OUTFILE_MEAS. (OBS=24);
title4 "FIRST 24 RECORDS in OUTPUT data SET &OUTFILE_MEAS.";
run;

***----- TO PRINT VARIABLE LABLES COMMENT (DELETE) "NOLABELS" FROM proc means STATEMENTS -------***;

proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss min max NOLABELS ;
    var DRG MDC MDRG YEAR DQTR
         AGEDCAT PAGECAT POPCAT BWHTCAT SEXCAT RACECAT PAYCAT LOS
         GPPD08 GPPD10 GPPD12;
     title4  "CATEGORICAL VARIABLES and RANGES OF VALUES";
run; quit;


proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss sum NOLABELS ;
     var TAPD14--TAPD16 TAPD18 TAPD90--TAPD92;
     title "PEDIATRIC INDICATOR NUMERATORS FOR AREA-BASED OR COUNT BASED INDICATORS (COUNT =SUM)";
run; quit;

proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss sum mean  NOLABELS ;
     var TPNQ03 TPPD01 TPPD05 TPPD08--TPPD10 TPPD12 TPPS17;
     title "PEDIATRIC HOSPITAL LEVEL INDICATOR NUMERATOR (=SUM),DENOMINATOR (=N), and OBSERVED RATE (MEAN) ";
run; quit;

proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss sum mean NOLABELS ;
     var TPPD01 TPPD05 TPPD08--TPPD10 TPPD12 TPNQ03;
     title1 "PEDIATRIC HOSPITAL LEVEL INDICATOR NUMERATORS (=SUM),DENOMINATORS (=N), and OBSERVED RATE (MEAN) ";
     title2 "WITH POA MODIFIERS";
run; quit;

