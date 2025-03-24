*========================= PROGRAM: PSI_HOSP_MEASURES.SAS ==========================;
*
*  DESCRIPTION:
*         Assigns the Patient Safety Indicator outcomes and stratifiers
*         to inpatient records.
*         Variables created by this program are TPPSXX, PPPSXX, stratifiers, and 
*         severity indicators.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*  USER NOTE1: Make sure you have created the format library
*              using PSI_FORMATS.SAS BEFORE running this program. 
*              This is done through the CONTROL program.
*
*  USER NOTE2: The AHRQ QI software does not support the calculation of weighted
*              estimates and standard errors using complex sampling designs.
*
*  USER NOTE3: See the AHRQ_PSI_SAS_v2024_ICD10_Release_Notes.txt file for 
*              software change notes.
*
*  USER NOTE4: Although some of the exclusion criteria for present on admission 
*              conditions were removed in v2020, some of the original logic
*              is retained for potential use in future versions.
*
*===================================================================================;

 title2 'PSI_HOSP_MEASURES PROGRAM';
 title3 'AHRQ INPATIENT QUALITY INDICATORS: ASSIGN PSIs TO INPATIENT DATA';

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
 * --- VALUES ARE MISSING. REVIEW AFTER RUNNING PSI_HOSP_MEASURES. -- ;
 * ------------------------------------------------------------------ ;

 data   OUTMSR.&DELFILE.
     (keep=KEY HOSPID SEX AGE DX1 DRG MDC YEAR DQTR);
 set     INMSR.&DISCHARGE.;
 if (AGE lt 0) or (AGE lt 18 and not %MDX1($MDC14PRINDX.)) or %MDX1($MDC15PRINDX.) or (missing(SEX)) or
    (missing(DX1)) or (missing(DQTR)) or (missing(YEAR)) or (DRG = 999) or
    (&MDC_PROVIDED. = 1 and missing(MDC));
 run;
 
 * ------------------------------------------------------------------ ;
 * --- PATIENT SAFETY INDICATOR (PSI) NAMING CONVENTION:          --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PATIENT SAFETY             --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:                         --- ;
 *               (T) NUMERATOR ("TOP")                            --- ;
 *               (P) POPULATION ("POP") IS DENOMINATOR            --- ;
 * --- THE SECOND LETTER IDENTIFIES THE PSI AS A HOSPITAL (P)     --- ;
 * --- LEVEL INDICATOR. THE NEXT TWO CHARACTERS ARE               --- ;
 * --- ALWAYS 'PS' for PSI. THE LAST TWO DIGITS ARE THE           --- ;
 * --- INDICATOR NUMBER.                                          --- ;
 * ------------------------------------------------------------------ ;
 
 data   OUTMSR.&OUTFILE_MEAS.
    (keep=KEY HOSPID DRG MDC MDRG YEAR DQTR AGE SEX
          AGECAT SEXCAT RACECAT PAYCAT LOS COVIDDX
          CMR_AIDS         CMR_ALCOHOL      CMR_ANEMDEF      CMR_AUTOIMMUNE  CMR_BLDLOSS      CMR_CANCER_LYMPH CMR_CANCER_LEUK
          CMR_CANCER_METS  CMR_CANCER_NSITU CMR_CANCER_SOLID CMR_CBVD        CMR_COAG         CMR_DEMENTIA     CMR_DEPRESS      CMR_DIAB_CX
          CMR_DIAB_UNCX    CMR_DRUG_ABUSE   CMR_HF           CMR_HTN_CX      CMR_HTN_UNCX     CMR_LIVER_MLD    CMR_LIVER_SEV    CMR_LUNG_CHRONIC
          CMR_NEURO_MOVT   CMR_NEURO_OTH    CMR_NEURO_SEIZ   CMR_OBESE       CMR_PARALYSIS    CMR_PERIVASC     CMR_PSYCHOSES    CMR_PULMCIRC
          CMR_RENLFL_MOD   CMR_RENLFL_SEV   CMR_THYROID_HYPO CMR_THYROID_OTH CMR_ULCER_PEPTIC CMR_VALVE        CMR_WGHTLOSS
          TRNSFER DNR MEDICDR
          RegVarPS04_DVT_PE_ANY RegVarPS04_DVT_PE_SEVERE
          RegVarPS04_PNEUMONIA_ANY RegVarPS04_PNEUMONIA_SEVERE
          RegVarPS04_SEPSIS_ANY RegVarPS04_SEPSIS_SEVERE
          RegVarPS04_SHOCK_ANY RegVarPS04_SHOCK_SEVERE
          RegVarPS04_GIHEMORRHAGE_ANY RegVarPS04_GIHEMORRHAGE_SEVERE

          TPPS02-TPPS04  TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE
          TPPS05-TPPS08  TPPS08_HIP_FX TPPS08_OTHER_FX TPPS09-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 TPPS18 TPPS19
          PPPS02-PPPS04  PPPS04_DVT_PE PPPS04_PNEUMONIA PPPS04_SEPSIS PPPS04_SHOCK PPPS04_GIHEMORRHAGE
          PPPS05-PPPS08  PPPS08_HIP_FX PPPS08_OTHER_FX PPPS09-PPPS14 PPPS14_OPEN PPPS14_NONOPEN PPPS15 PPPS18 PPPS19
          HPPS13 HPPS15 &OUTFILE_KEEP
);
 set   INMSR.&DISCHARGE.
      (keep=KEY HOSPID DRG MDC SEX AGE
            YEAR DQTR
            DISP LOS ASOURCE POINTOFORIGINUB04 ATYPE
            DX1-DX&NDX. PR1-PR&NPR. %ADDPRDAY_PAY1_RACE
            DXPOA1-DXPOA&NDX. &OUTFILE_KEEP);

 label
 HOSPID   = 'Hospital Identification Number'
 SEX = 'Sex of the patient'
 key = 'Unique record identifier'
 ;

 ARRAY PR (&NPR.) $  PR1 - PR&NPR.;
 ARRAY DX (&NDX.) $  DX1 - DX&NDX.;
 ARRAY DXPOA (&NDX.) $  DXPOA1 - DXPOA&NDX.;

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
 * --- DEFINE MEDICAL DRGS -------------------------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib MEDICDR length=3
   label='MEDICAL DRGS';

 if %MDR($MEDIC2R.) then MEDICDR = 1;
 else MEDICDR = 0;


 * -------------------------------------------------------------- ;
 * --- DEFINE SURGICAL DRGS ------------------------------------- ;
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
 * --- DEFINE MODIFIED DRGS ------------------------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib MDRG length=4
   label='Modified DRG';

 MDRG = put(put(DRG,Z3.),$DRGF2T.);


 * -------------------------------------------------------------- ;
 * --- DEFINE LOW MORT DRGS ------------------------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib LOWMODR length=3
   label='LOW MORTALITY DRGS';

 LOWMODR = put(MDRG,LOWMODR.);


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
 attrib HPPS13 length=3
   label='RISK CLASS FOR PSI 13';

 attrib HPPS15 length=3
   label='RISK CLASS FOR PSI 15';


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
 
 %macro label_qis(flag=, qi_num=, qi_name=);
   attrib TP&qi_num. length=8
   label = "&qi_name. (Numerator)"
   ;
   attrib PP&qi_num. length=8
   label = "&qi_name. (Population)"
   ;

   %IF %substr(&qi_num., 1, 4) = PS04 AND &qi_num. ne PS04 %THEN %DO;
    %let stratum = %sysfunc(tranwrd(&qi_num., %str(_), %str( )));
    label 
    RegVar&qi_num._ANY    = "&stratum. Regression variable: Any Triggering Complication POA"
    RegVar&qi_num._SEVERE = "&stratum. Regression variable: Triggering Complication Severe"
    ;
   %END;

   *** Re-label day dependent indicators;
   %IF &PRDAY. = 0 AND &flag. = 1 %THEN %DO;
    label
    TP&qi_num. = "&qi_name.-NO PRDAY (Numerator)"
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


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AHRQ COMORBIDITY ------------------------------- ;
 * -------------------------------------------------------------- ;

 %include MacLib(PSI_HOSP_Comorb_Code_v2024.sas);


 * -------------------------------------------------------------- ;
 * --- IDENTIFY DNR --------------------------------------------- ;
 * -------------------------------------------------------------- ;
  attrib DNR length=3
   label='DO NOT RESUSCITATE FLAG';

  if %MDX2Q2($DNR.) then DNR = 1;
    else DNR = 0;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT HOSPITAL LEVEL INDICATORS ---------------------- ;
 * -------------------------------------------------------------- ;

 * ---------------------------------------------------------------------------- ;
 * --- PSI 02 : DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) --- ;
 * ---------------------------------------------------------------------------- ;

   if LOWMODR then do;

      TPPS02 = 0;

      if DISP in (20) then TPPS02 = 1;

       *** Exclude Trauma, Immunocompromised state, and cancer;

      if %MDX($TRAUMID.) or %MDX($IMMUNID.) or
         %MPR($IMMUNIP.) or %MDX($CANCEID.)
      then TPPS02 = .;

      *** Exclude missing discharge disposition or transfer acute care facility;

      if DISP le .Z or DISP=2 then TPPS02 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- PSI 03 : PRESSURE ULCER RATE ----------------------------- ;
 * -------------------------------------------------------------- ;
 
   if (MEDICDR or SURGIDR) then do;

      %include MacLib(PSI_03_Site_Specific_Macro_v2024.sas);

      *** Exclude severe burns;

      if %MDX($BURNDX.) then TPPS03 = .;

      *** Exclude exfoliation;

      if %MDX($EXFOLIATXD.) then TPPS03 = .;

      *** Exclude MDC 14;

      if %MDX1($MDC14PRINDX.) then TPPS03 = .;

      *** Exclude LOS < 3 ;

      if LOS < 3 then TPPS03 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS03 = . then QPPS03 = .;

   end;


 * ------------------------------------------------------------------------------------------ ;
 * --- PSI 04 : DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS --- ;
 * ------------------------------------------------------------------------------------------ ;

 %MACRO PS4;

  if (&PRDAY. = 1 and ORDAY ne . and MPRDAY_LAST ne .) then do;

      if MPRDAY_LAST >= ORDAY then CHK_FTR5PR = 1;

  end;

 %MEND;
 
 *** create CHK_FTR5PR to identify any procedure in FTR5PR (MPRDAY_LAST) that is on or after the first OR procedure (ORDAY) ;
 
 %ORDAY($FTR5PR.);
 %MPRDAY_LAST($FTR5PR.);
 %PS4;

 %ORDAY($BLANK.); /* resulting ORDAY used twice in PSI 04 */

   if (SURGIDR and ORCNT > 0)   and
      (0 <= ORDAY <=2 or ATYPE in (3)) and
      (17 < AGE < 90 or %MDX1($MDC14PRINDX.))    then do;

       /**-- STRATUM_DVT_PE: DEEP VEIN THROMBOSIS/PULMONARY EMBOLISM (DVT/PE) --**/
   if (%MDX2($FTR2DXB.) and
       not (%MDX1($FTR2DXB.) or %MDX1($OBEMBOL.)))
      or
       /**-- STRATUM_PNEUMONIA: PNEUMONIA --**/
      (%MDX2($FTR3DX.) and
       not (%MDX1($FTR3DX.) or %MDX1($FTR3EXA.) or %MDX($FTR3EXB.) or MDC in (4) or %MPR($LUNGCIP.)))
      or
       /**-- STRATUM_SEPSIS: SEPSIS --**/
      (%MDX2($FTR4DX.) and
       not (%MDX1($FTR4DX.) or %MDX1($INFECID.)))
      or
       /**-- STRATUM_SHOCK: SHOCK/CARDIAC ARREST --**/
      ((%MDX2($FTR5DX.) or CHK_FTR5PR) and
       not (%MDX1($FTR5DX.) or %MDX1($FTR5EX.) or %MDX1($HEMORID.) or %MDX1($TRAUMID.) or
            %MDX1($GASTRID.) or (%MDX2($FTR6GV.) and %MDX1($FTR6QD.)) or MDC in (4,5) ))
      or
       /**-- STRATUM_GIHEMORRHAGE: GASTROINTESTINAL (GI) HEMORRHAGE/ACUTE ULCER --**/
      (%MDX2($FTR6DX.) and
       not (%MDX1($FTR6DX.) or %MDX1($FTR6EX.) or %MDX1($TRAUMID.) or
            %MDX1($ALCHLSM.) or (%MDX2($FTR6GV.) and %MDX1($FTR6QD.)) or MDC in (6,7)))
   then do;

      TPPS04 = 0;

      if DISP in (20) then TPPS04 = 1;

      *** Exclude Transfers to an acute care facility and those admitted from a hospice facility;

      if POINTOFORIGINUB04 in ('F') or DISP le .Z or DISP=2 then TPPS04 = .;

   end;

   end;

 * ----------------------------------------------------------------------------------------------------------------------- ;
 * --- PSI 04 Stratum_DVT_PE       : DEATH AMONG SURGICAL INPATIENTS: DEEP VEIN THROMBOSIS/PULMONARY EMBOLISM (DVT/PE) --- ;
 * --- PSI 04 Stratum_PNEUMONIA    : DEATH AMONG SURGICAL INPATIENTS: PNEUMONIA ------------------------------------------ ;
 * --- PSI 04 Stratum_SEPSIS       : DEATH AMONG SURGICAL INPATIENTS: SEPSIS --------------------------------------------- ;
 * --- PSI 04 Stratum_SHOCK        : DEATH AMONG SURGICAL INPATIENTS: SHOCK/CARDIAC ARREST ------------------------------- ;
 * --- PSI 04 Stratum_GIHEMORRHAGE : DEATH AMONG SURGICAL INPATIENTS: GASTROINTESTINAL (GI) HEMORRHAGE/ACUTE ULCER ------- ;
 * ----------------------------------------------------------------------------------------------------------------------- ;
 
   if (SURGIDR and ORCNT > 0)           and
      (0 <= ORDAY <= 2 or ATYPE in (3)) and
      (17 < AGE < 90 or %MDX1($MDC14PRINDX.))    then do;

	  /** Initialize _ANY, _SEVERE outside of the strata block ***/
      RegVarPS04_DVT_PE_ANY = 0;
      RegVarPS04_DVT_PE_SEVERE=0;
      RegVarPS04_PNEUMONIA_ANY = 0;
      RegVarPS04_PNEUMONIA_SEVERE=0;
      RegVarPS04_SEPSIS_ANY = 0;
      RegVarPS04_SEPSIS_SEVERE=0;
      RegVarPS04_SHOCK_ANY = 0;
      RegVarPS04_SHOCK_SEVERE=0;
      RegVarPS04_GIHEMORRHAGE_ANY = 0;
      RegVarPS04_GIHEMORRHAGE_SEVERE=0;

      /** STRATUM_DVT_PE: DEEP VEIN THROMBOSIS/PULMONARY EMBOLISM (DVT/PE) ***/

      if (%MDX2($FTR2DXB.)) then do;

          TPPS04_DVT_PE = 0;
          if DISP in (20) then TPPS04_DVT_PE = 1;

          if %MDX1($FTR2DXB.) then TPPS04_DVT_PE = .;
          if %MDX1($OBEMBOL.) then TPPS04_DVT_PE = .;

          *** Exclude Transfers to an acute care facility and those admitted from a hospice facility;

          if POINTOFORIGINUB04 in ('F') or DISP le .Z or DISP=2 then TPPS04_DVT_PE = .;

		  *** Define ANY and SEVERE risk adjustment variables ;

				do i = 1 to &NDX.;
					if put(DX(i),$FTR2DXB.) = '1' then do;
						if DXPOA(i) in ('Y','W') then RegVarPS04_DVT_PE_ANY = 1;
						if put(DX(i),$SEVDPEDX.) = '1' then RegVarPS04_DVT_PE_SEVERE=1;
					end;
				end;

      end;

      /** STRATUM_PNEUMONIA: PNEUMONIA ***/

      if %MDX2($FTR3DX.) then do;

          TPPS04_PNEUMONIA = 0;
          if DISP in (20) then TPPS04_PNEUMONIA = 1;

          if %MDX1($FTR3DX.)   then TPPS04_PNEUMONIA = .;
          if %MDX1($FTR3EXA.)  then TPPS04_PNEUMONIA = .;
          if %MDX($FTR3EXB.)   then TPPS04_PNEUMONIA = .;
          if MDC in (4)        then TPPS04_PNEUMONIA = .;
          if %MPR($LUNGCIP.)   then TPPS04_PNEUMONIA = .;

          *** Exclude Transfers to an acute care facility and those admitted from a hospice facility;

          if POINTOFORIGINUB04 in ('F') or DISP le .Z or DISP=2 then TPPS04_PNEUMONIA = .;

		  *** Define ANY and SEVERE risk adjustment variables ;

				do i = 1 to &NDX.;
					if put(DX(i),$FTR3DX.) = '1' then do;
						if DXPOA(i) in ('Y','W') then RegVarPS04_PNEUMONIA_ANY = 1;
						if put(DX(i),$SEVPNEUDX.) = '1' then RegVarPS04_PNEUMONIA_SEVERE=1;
					end;
				end;

      end;


      /** STRATUM_SEPSIS: SEPSIS ***/

      if %MDX2($FTR4DX.) then do;

          TPPS04_SEPSIS = 0;
          if DISP in (20) then TPPS04_SEPSIS = 1;

          if %MDX1($FTR4DX.) then TPPS04_SEPSIS = .;
          if %MDX1($INFECID.) then TPPS04_SEPSIS = .;

          *** Exclude Transfers to an acute care facility and those admitted from a hospice facility;

          if POINTOFORIGINUB04 in ('F') or DISP le .Z or DISP=2 then TPPS04_SEPSIS = .;

		  *** Define ANY and SEVERE risk adjustment variables ;

				do i = 1 to &NDX.;
					if put(DX(i),$FTR4DX.) = '1' then do;
						if DXPOA(i) in ('Y','W') then RegVarPS04_SEPSIS_ANY = 1;
						if put(DX(i),$SEVSEPDX.) = '1' then RegVarPS04_SEPSIS_SEVERE=1;
					end;
				end;

      end;


      /** STRATUM_SHOCK: SHOCK/CARDIAC ARREST ***/

      if %MDX2($FTR5DX.) or CHK_FTR5PR then do;

          TPPS04_SHOCK = 0;
         if DISP in (20) then TPPS04_SHOCK = 1;

          if %MDX1($FTR5DX.)  then TPPS04_SHOCK = .;
          if %MDX1($TRAUMID.) then TPPS04_SHOCK = .;
          if %MDX1($HEMORID.) then TPPS04_SHOCK = .;
          if %MDX1($GASTRID.) then TPPS04_SHOCK = .;
          if %MDX1($FTR5EX.)  then TPPS04_SHOCK = .;
          if %MDX2($FTR6GV.) and %MDX1($FTR6QD.) then TPPS04_SHOCK = .;
          if MDC in (4,5)     then TPPS04_SHOCK = .;

          *** Exclude Transfers to an acute care facility and those admitted from a hospice facility;

          if POINTOFORIGINUB04 in ('F') or DISP le .Z or DISP=2 then TPPS04_SHOCK = .;

		  *** Define ANY and SEVERE risk adjustment variables ;

				do i = 1 to &NDX.;
					if put(DX(i),$FTR5DX.) = '1' then do;
						if DXPOA(i) in ('Y','W') then RegVarPS04_SHOCK_ANY = 1;
						if put(DX(i),$SEVSCKDX.) = '1' then RegVarPS04_SHOCK_SEVERE=1;
					end;
				end;
				do i = 1 to &NPR. until (RegVarPS04_SHOCK_SEVERE=1);
					if put(PR(i),$FTR5PR.) = '1' then RegVarPS04_SHOCK_SEVERE=1;
				end;

      end;


      /** STRATUM_GIHEMORRHAGE: GASTROINTESTINAL (GI) HEMORRHAGE/ACUTE ULCER ***/

      if %MDX2($FTR6DX.) then do;

          TPPS04_GIHEMORRHAGE = 0;
          if DISP in (20) then TPPS04_GIHEMORRHAGE = 1;

          if %MDX1($FTR6DX.)  then TPPS04_GIHEMORRHAGE = .;
          if %MDX1($FTR6EX.)  then TPPS04_GIHEMORRHAGE = .;
          if %MDX1($TRAUMID.) then TPPS04_GIHEMORRHAGE = .;
          if %MDX1($ALCHLSM.) then TPPS04_GIHEMORRHAGE = .;
          if %MDX2($FTR6GV.) and %MDX1($FTR6QD.) then TPPS04_GIHEMORRHAGE = .;
          if MDC in (6,7)     then TPPS04_GIHEMORRHAGE = .;

          *** Exclude Transfers to an acute care facility and those admitted from a hospice facility;

          if POINTOFORIGINUB04 in ('F') or DISP le .Z or DISP=2 then TPPS04_GIHEMORRHAGE = .;

		  *** Define ANY and SEVERE risk adjustment variables ;

				do i = 1 to &NDX.;
					if put(DX(i),$FTR6DX.) = '1' then do;
						if DXPOA(i) in ('Y','W') then RegVarPS04_GIHEMORRHAGE_ANY = 1;
						if put(DX(i),$SEVGIHDX.) = '1' then RegVarPS04_GIHEMORRHAGE_SEVERE=1;
					end;
				end;

      end;


 * -------------------------------------------------------------- ;
 * --- MAKE STRATA MUTUALLY EXCLUSIVE AND EXHAUSTIVE ------------ ;
 * -------------------------------------------------------------- ;
 
       *** Assign discharges with multiple conditions to stratum with highest risk of the outcome;

       if TPPS04_SHOCK ne . then do;
           TPPS04_SEPSIS = .;      
           TPPS04_PNEUMONIA = .;   
           TPPS04_DVT_PE = .;      
           TPPS04_GIHEMORRHAGE = .;
       end;

       else if TPPS04_SEPSIS ne . then do;
           TPPS04_SHOCK = .;       
           TPPS04_PNEUMONIA = .;   
           TPPS04_DVT_PE = .;      
           TPPS04_GIHEMORRHAGE = .;
       end;

       else if TPPS04_PNEUMONIA ne . then do;
           TPPS04_SHOCK = .;       
           TPPS04_SEPSIS = .;      
           TPPS04_DVT_PE = .;      
           TPPS04_GIHEMORRHAGE = .;
       end;

	   else if TPPS04_GIHEMORRHAGE ne . then do;
           TPPS04_SHOCK = .;    
           TPPS04_SEPSIS = .;   
           TPPS04_PNEUMONIA = .;
           TPPS04_DVT_PE = .;   
       end;

       else if TPPS04_DVT_PE ne . then do;
           TPPS04_SHOCK = .;       
           TPPS04_SEPSIS = .;      
           TPPS04_PNEUMONIA = .;   
           TPPS04_GIHEMORRHAGE = .;
       end;

     end;


 * ---------------------------------------------------------------------------- ;
 * --- PSI 05 : RETAINED SURGICAL ITEM OR UNRETRIEVED DEVICE FRAGMENT COUNT --- ;
 * ---------------------------------------------------------------------------- ;

   if (MEDICDR or SURGIDR) then do;

      TPPS05 = .; QPPS05 = .;

      if %MDX2($FOREIID.) then TPPS05 = 1;
      if %MDX2Q1($FOREIID.) then QPPS05 = 0;

      *** Exclude principal diagnosis;

      if %MDX1($FOREIID.) then TPPS05 = .;
      if %MDX2Q2($FOREIID.) then QPPS05 = 1;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS05 = . then QPPS05 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- PSI 06 : IATROGENIC PNEUMOTHORAX RATE -------------------- ;
 * -------------------------------------------------------------- ;

   if (MEDICDR or SURGIDR) then do;

      TPPS06 = 0; QPPS06 = 0;

      if %MDX2($IATROID.) then TPPS06 = 1;

      *** Exclude principal diagnosis;

      if %MDX1($IATPTXD.) then TPPS06 = .;
      if %MDX2Q2($IATPTXD.) then QPPS06 = 1;

      *** Exclude Chest Trauma, Pleural effusion or MDC 14;

      if %MDX($CTRAUMD.) or %MDX($PLEURAD.) or %MDX1($MDC14PRINDX.)
      then TPPS06 = .;

      *** Exclude Thoracic surgery or Cardiac surgery;

      if %MPR($THORAIP.) or %MPR($CARDSIP.)
      then TPPS06 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS06 = . then QPPS06 = .;

  end;


 * ---------------------------------------------------------------------------- ;
 * --- PSI 07 : CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE --- ;
 * ---------------------------------------------------------------------------- ;
 
   if (MEDICDR or SURGIDR) then do;

      TPPS07 = 0; QPPS07 = 0;

      if %MDX2($IDTMC3D.) then TPPS07 = 1;

      *** Exclude principal diagnosis;

      if %MDX1($IDTMC3D.) then TPPS07= .;
      if %MDX2Q2($IDTMC3D.) then QPPS07= 1;

      *** Exclude Immunocompromised state and Cancer;

      if %MDX($IMMUNID.) or %MPR($IMMUNIP.) or %MDX($CANCEID.)
      then TPPS07 = .;

      *** Exclude LOS < 2;

      if LOS < 2 then TPPS07 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS07 = . then QPPS07 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- PSI 08 : IN-HOSPITAL FALL-ASSOCIATED FRACTURE RATE ------- ;
 * -------------------------------------------------------------- ;

   if SURGIDR or MEDICDR then do;

      TPPS08 = 0; QPPS08 = 0;
      TPPS08_HIP_FX = 0; TPPS08_OTHER_FX = 0;

      if %MDX2($FXID.) then TPPS08 = 1;

      *** PSI 08 components;
      *** In-Hospital Fall with Hip Fracture Rate: PS08_HIP_FX;
      *** In-Hospital Fall with Other Fracture Rate: PS08_OTHER_FX; 

      if TPPS08=1 then do;
         if %MDX2($HIPFXID.) then TPPS08_HIP_FX = 1;
	     else TPPS08_OTHER_FX =1;
	  end;


      *** Exclude principal diagnosis;

      if %MDX1($FXID.) then TPPS08 = .;
      if %MDX2Q2($FXID.) then QPPS08 = 1;

      *** Excludes joint prosthesis associated fracture;

      if %MDX($PROSFXID.) then TPPS08 = .;

      *** Exclude MDC 14;

      if %MDX1($MDC14PRINDX.) then TPPS08 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS08 = . then QPPS08 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- PSI 09 : POSTOPERATIVE HEMORRHAGE OR HEMATOMA RATE ------- ;
 * -------------------------------------------------------------- ;

 %MACRO PS9;

  if (&PRDAY. = 1 and ORDAY ne . and MPRDAY ne .) then do;

      if MPRDAY < ORDAY then TPPS09 = .; 

  end;

 %MEND;


   if SURGIDR and ORCNT > 0 then do;

      TPPS09 = 0; QPPS09 = 0;

      if %MDX2($POHMRI2D.) and
          (%MPR($HEMOTH2P.))
      then TPPS09 = 1;

      *** Exclude principal diagnosis;

      if %MDX1($POHMRI2D.) then TPPS09 = .;
      if %MDX2Q2($POHMRI2D.) then QPPS09 = 1;

      *** Exclude if control of post-operative hemorrhage or Miscellaneous hemorrhage
          hematoma-related procedure are the only OR procedures;

      %MPRCNT($HEMOTH2P.);
      if ORCNT = MPRCNT then TPPS09 = .;

      *** Exclude if control of post-operative hemorrhage or Miscellaneous Hemorrhage or
          hematoma-related procedure occurs before the first OR procedure;

      %ORDAY($HEMOTH2P.);
      %MPRDAY($HEMOTH2P.); PS9_MPRDAY_HEMOTH2P=MPRDAY;
      %PS9;

      *** Exclude MDC 14;

      if %MDX1($MDC14PRINDX.) then TPPS09 = .;

      *** Exclude Coagulation Disorders and anticoagulant/antithormbotic coagulopathies POA;
      if %MDX($COAGDID.) then TPPS09 = . ;
      if %MDX1($MEDBLEEDD.) then TPPS09 = . ;
      if %MDX2Q2($MEDBLEEDD.) then QPPS09 = 1;

	  *** Exclude if administration of thrombolytic(THROMBOLYTICP) ccurs before or on the same day as the first procedure for treatment of hemorrhage or hematoma(HEMOTH2P);
	  
	  %MPRDAY($THROMBOLYTICP.); PS9_MPRDAY_THROMBOLYTICP=MPRDAY;

	  if PS9_MPRDAY_THROMBOLYTICP^=. and PS9_MPRDAY_HEMOTH2P^=. and PS9_MPRDAY_THROMBOLYTICP <= PS9_MPRDAY_HEMOTH2P then TPPS09=.; 


      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS09 = . then QPPS09 = .;

   end;


 * -------------------------------------------------------------------------- ;
 * --- PSI 10 : POSTOPERATIVE ACUTE KIDNEY INJURY REQUIRING DIALYSIS RATE --- ;
 * -------------------------------------------------------------------------- ;

 %MACRO PS10;

  if (&PRDAY. = 1  and ORDAY ne . and MPRDAY ne .) then do;

      if MPRDAY <= ORDAY then TPPS10 = .;

  end;

 %MEND;

   if SURGIDR and ORCNT > 0 and ATYPE in (3) then do;

      TPPS10 = 0; QPPS10 = 0;

      if (%MDX2($PHYSIDB.) and %MPR($DIALYIP.)) then TPPS10 = 1;

      *** Exclude principal Dx or secondary Dx POA of acute renal failure or UT Obstruction as principle Dx;

      if %MDX1($PHYSIDB.) or %MDX1($URINARYOBSID.) then TPPS10 = .;
      if %MDX2Q2($PHYSIDB.) then QPPS10 = 1;

      *** Exclude if any dialysis procedure occurs before or on same day as the first OR procedure;

      %ORDAY($BLANK.);
      %MPRDAY($DIALYIP.);
      %PS10;

      *** Exclude if any dialysis access procedure occurs before or on same day as the first OR procedure;

      %ORDAY($BLANK.);
      %MPRDAY($DIALY2P.);
      %PS10;

      *** Exclude Cardiac arrest, Cardiac dysrhythmia, Acute renal failure and Shock, or Chronic renal failure if either principal Dx or secondary Dx POA;

      if (%MDX1($CARDIID.) or %MDX1($CARDRID.) or %MDX1($SHOCKID.) or %MDX1($CRENLFD.))
      then TPPS10 = .;

      if %MDX2Q2($CARDIID.) then CARDIID_cd = 1;
      if %MDX2Q2($CARDRID.) then CARDRID_cd = 1;
      if %MDX2Q2($SHOCKID.) then SHOCKID_cd = 1;
      if %MDX2Q2($CRENLFD.) then CRENLFD_cd = 1;
      if CARDIID_cd or CARDRID_cd or SHOCKID_cd or CRENLFD_cd then QPPS10 = 1;

      *** Exclude any DX POA of solitary kidney disease and any partial nephrectomy procedure;

      if %MDXAQ2($SOLKIDD.) and %MPR($PNEPHREP.) then TPPS10 = .;

      *** Exclude MDC 14;

      if %MDX1($MDC14PRINDX.) then TPPS10 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS10 = . then QPPS10 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- PSI 11 : POSTOPERATIVE RESPIRATORY FAILURE RATE ---------- ;
 * -------------------------------------------------------------- ;

 %MACRO PS11N(FMT, DAYS);

    %MPRDAY_LAST(&FMT.);

    if (&PRDAY. = 1  and ORDAY ne . and MPRDAY_LAST ne .) then do;

       if MPRDAY_LAST >= ORDAY + &DAYS. then TPPS11 = 1;

    end;

 %MEND;

 %MACRO PS11;

    if (&PRDAY. = 1  and ORDAY ne . and MPRDAY ne .) then do;

       if MPRDAY < ORDAY then TPPS11 = .;

    end;

 %MEND;

   if SURGIDR and ORCNT > 0 and ATYPE in (3) then do;

      TPPS11 = 0; QPPS11 = 0;

      if %MDX2($ACURF2D.)   then TPPS11 = 1;

      *** Include in numerator if reintubation procedure occurs on the same day or
          # days after the first OR procedure;

      %ORDAY($BLANK.);
      %PS11N($PR9604P., 1);
      %PS11N($PR9671P., 2);
      %PS11N($PR9672P., 0);

      *** Exclude principal diagnosis;

      if %MDX1($ACURF3D.) then TPPS11 = .;
      if %MDX2Q2($ACURF3D.) then QPPS11 = 1;

      *** Exclude if tracheostomy procedure is the only OR procedure;

      %MPRCNT($TRACHIP.);
      if ORCNT = MPRCNT then TPPS11 = .;

      *** Exclude if tracheostomy procedure occurs before the first or procedure;

      %ORDAY($TRACHIP.);
      %MPRDAY($TRACHIP.);
      %PS11;

      *** Exclude Malignant Hyperthermia;

      if %MDX($MALHYPD.) then TPPS11 = .;

      *** Exclude Neuromuscular disorders;

      if %MDXAQ2($NEUROMD.) then TPPS11 = .;

      *** Exclude Tracheostomy;

      if %MDXAQ2($TRACHID.) then TPPS11 = .;

      *** Exclude Craniofacial anomalies;

      if %MPR($NUCRANP.) then TPPS11 = .;

      *** Exclude Esophageal resection procedure;

      if %MPR($PRESOPP.) then TPPS11 = .;

      *** Exclude Lung Cancer Procedure;

      if %MPR($LUNGCIP.) then TPPS11 = .;

      *** Exclude diagnosis of degenerative neurological disorder;

      if %MDXAQ2($DGNEUID.) then TPPS11 = .;

      *** Exclude Hospitalizations involving lung transplantations;

      if %MPR($LUNGTRANSP.) then TPPS11 = .;

      *** Exclude MDC 4, 14 ;

      if MDC =4 or %MDX1($MDC14PRINDX.) then TPPS11 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS11 = . then QPPS11 = .;

   end;


 * ------------------------------------------------------------------------------ ;
 * --- PSI 12 : PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE --- ;
 * ------------------------------------------------------------------------------ ;

 %MACRO PS12;

    if (&PRDAY. = 1  and ORDAY ne . and MPRDAY ne .) then do;

        if MPRDAY <= ORDAY then TPPS12 = .;

    end;

 %MEND;

   if SURGIDR and ORCNT > 0 then do;

      TPPS12 = 0; QPPS12 = 0;

      if %MDX2($DEEPVIB.) or %MDX2($PULMOID.) then TPPS12 = 1;

      *** Exclude principal diagnosis;

      if %MDX1($DEEPVIB.) or %MDX1($PULMOID.) then TPPS12 = .;

      *** Account for secondary diagnosis present on admission;

      if %MDX2Q2($DEEPVIB.) then DEEPVIB_cd = 1;
      if %MDX2Q2($PULMOID.) then PULMOID_cd = 1;
      if DEEPVIB_cd or PULMOID_cd then QPPS12 = 1;

      *** Exclude hospitalizations with clinically significant HIT, without regard to POA; 

      if %MDX2($HITD.) then TPPS12 = .; 

      *** Exclude if the first OR procedure occurs after or on 10th day from the admission;

      %MPRDAY($ORPROC.);
      if MPRDAY >=10 then TPPS12 = .;

      *** Exclude if interruption of vena cava occurs before or on the
          same day as the first OR procedure;

      %ORDAY($VENACIP.);
      %MPRDAY($VENACIP.);
      %PS12;

      *** Exclude if pulmonary arterial thrombectomy before or on the
          same day as the first OR procedure;

      %ORDAY($THROMP.);
      %MPRDAY($THROMP.);
      %PS12;

      *** Exclude if only operating room procedure was for interruption of vena cava or pulmonary arterial thrombectomy;

      %MPRCNT($VENACIP.);
      if ORCNT = MPRCNT then TPPS12 = .;
      MPRCNTV = MPRCNT;

      %MPRCNT($THROMP.);
      if ORCNT = MPRCNT then TPPS12 = .;

      *** Exclude if the combined count equals ORCNT;

      if ORCNT = MPRCNT + MPRCNTV then TPPS12 = .;

      *** Exclude hospitalizations with neurotrauma POA;

      if %MDXAQ2($NEURTRAD.) then TPPS12 = .;

      *** Exclude any extracorporeal membrane oxygenation procedure;

      if %MPR($ECMOP.) then TPPS12 = . ;

      *** Exclude MDC 14;

      if %MDX1($MDC14PRINDX.) then TPPS12 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS12 = . then QPPS12 = .;

   end;


 * -------------------------------------------------------------- ;
 * --- PSI 13 : POSTOPERATIVE SEPSIS RATE ----------------------- ;
 * -------------------------------------------------------------- ;

   if SURGIDR and ORCNT > 0 and ATYPE in (3)  then do;

      TPPS13 = 0; QPPS13 = 0;

      if (%MDX2($SEPTI2D.)) then TPPS13 = 1;

      *** Exclude principal diagnosis;

      if (%MDX1($SEPTI2D.)) then TPPS13 = .;
      if %MDX2Q2($SEPTI2D.) then QPPS13 = 1;

      *** Exclude Infection;

      if %MDX1($INFECID.) then TPPS13 = .;
      if %MDX2Q2($INFECID.) then QPPS13 = 1;

      *** Exclude MDC 14;

      if %MDX1($MDC14PRINDX.) then TPPS13 = .;

      *** Exclude if the first OR procedure occurs after or on 10th day from the admission;

      %MPRDAY($ORPROC.);
      if MPRDAY >=10 then TPPS13 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS13 = . then QPPS13 = .;

      *** Risk adjust by risk category (0-Low risk, 1-Intermediate risk, 2-High risk, 3-Very high risk);

      if TPPS13 NE . then do;
         if %MDXAQ2($IMMUNHD.) then flag_IMMUNHD=1; 
         if %MPR($TRANSPP.)    then flag_TRANSPP=1;
         if %MDXAQ2($IMMUITD.) then flag_IMMUITD=1;
         if %MDXAQ2($HEPFA2D.) then flag_HEPFA2D=1;
         if %MDXAQ2($HEPFA3D.) then flag_HEPFA3D=1;

         if flag_HEPFA3D=1 then HPPS13=3; 
         else if flag_IMMUNHD=1 or flag_TRANSPP=1 then HPPS13 = 2;
         else if flag_IMMUITD=1 or flag_HEPFA2D=1 then HPPS13 = 1; 
         else HPPS13 = 0;
      end;

   end;


 * -------------------------------------------------------------- ;
 * --- PSI 14 : POSTOPERATIVE WOUND DEHISCENCE RATE ------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PS14;

   if (&PRDAY. = 1 and (MPRDAYA ne . or MPRDAYA2 ne .) and MPRDAY_LAST_B ne .) then do;
     if (MPRDAY_LAST_B <= MPRDAYA or MPRDAYA eq .) and (MPRDAY_LAST_B <= MPRDAYA2 or MPRDAYA2 eq .) then TPPS14 = .;
   end;

 %MEND;

   if (%MPR($ABDOMIPOPEN.) or %MPR($ABDOMIPOTHER.)) then do;

      TPPS14 = 0;

      if %MPR($RECLOIP.) and %MDX($ABWALLCD.) then TPPS14 = 1;

      *** Exclude if qualifying wound reclosure occurs before or on the same
          day as the first abdominopelvic procedure;

      MPRDAYA=.; MPRDAYA2=.; MPRDAY_LAST_B=.;
      %MPRDAY($ABDOMIPOPEN.); MPRDAYA = MPRDAY;
      %MPRDAY($ABDOMIPOTHER.); MPRDAYA2 = MPRDAY;
      %MPRDAY_LAST($RECLOIP.);
      if MPRDAY_LAST > . then MPRDAY_LAST_B = MPRDAY_LAST;
      %PS14;

      *** Exclude Primary Dx or secondary DX POA of Disruption of Internal Operation Wound;

      if %MDX2Q2($ABWALLCD.) then ABWALLCD_cd = 1;
      if %MDX1($ABWALLCD.) or ABWALLCD_cd = 1 then TPPS14 = .;

      *** Exclude LOS < 2;

      if LOS < 2 then TPPS14 = .;

      *** Exclude MDC 14;

      if %MDX1($MDC14PRINDX.) then TPPS14 = .;

      *** identify Stratum_OPEN   : OPEN APPROACH
	               Stratum_NONOPEN: NON-OPEN APPROACH
          Among discharges otherwise qualifying for the denominator ;

      if %MDX($ABWALLCD.) then flag_MDX_ABWALLCD=1; else flag_MDX_ABWALLCD=0;
      if TPPS14 ne . then do;
         if MPRDAYA =. or  MPRDAY_LAST=. or flag_MDX_ABWALLCD=0 then do;
            if %MPR($ABDOMIPOPEN.) then TPPS14_OPEN = TPPS14;
            else if %MPR($ABDOMIPOTHER.) then TPPS14_NONOPEN = TPPS14;
         end;
         else do;
            if (%MPR($ABDOMIPOPEN.) and MPRDAYA < MPRDAY_LAST) then TPPS14_OPEN = TPPS14;
            else if (%MPR($ABDOMIPOPEN.) and MPRDAYA >= MPRDAY_LAST) or %MPR($ABDOMIPOTHER.) then TPPS14_NONOPEN = TPPS14;
         end;
      end;

   end;


 * ---------------------------------------------------------------------- ;
 * --- PSI 15 : ABDOMINOPELVIC ACCIDENTAL PUNCTURE OR LACERATION RATE --- ;
 * ---------------------------------------------------------------------- ;

  %MACRO PS15(FMT1,FMT2);
    PR1DAY = .;
    PR2DAY = .;
    PR1INDX = 0;
    MPRDAYCD = 0;
    %DO I = 1 %TO &NPR.;
       if put(PR&I.,&FMT1.) = '1' and (PRDAY&I. gt .Z) then do;
          if PR1DAY le .Z then do;
             PR1DAY = PRDAY&I;
             PR1INDX = &I;
          end;
          else if PR1DAY > PRDAY&I. then do;
             PR1DAY = PRDAY&I;
             PR1INDX = &I;
         end;
       end;
    %END;

    %DO I = 1 %TO &NPR.;
       if put(PR&I.,&FMT2.) = '1' and (PRDAY&I. gt .Z) and (&I ne PR1INDX) then do;
          if PR2DAY le .Z then do;
             PR2DAY = PRDAY&I;
          end;
          else if PR2DAY < PRDAY&I. then do;
             PR2DAY = PRDAY&I;
          end;
       end;
    %END;

    if (PR2DAY gt .Z) and (PR1DAY gt .Z) and (PR2DAY > PR1DAY and PR2DAY <= PR1DAY+30 ) then MPRDAYCD = 1;

  %MEND;

   %include MacLib(PSI_15_Num_Denom_Macro_v2024.sas);
   %PSI15_denom_numer($ABDOMI15P.);

   if (MEDICDR or SURGIDR) and flag_PSI15_Denom = 1 then do;

      TPPS15 = 0; QPPS15 = 0;

      %include MacLib(PSI_15_Site_Specific_Macro_v2024.sas);

      *** Exclude MDC 14;

      if %MDX1($MDC14PRINDX.) then TPPS15 = .;

      *** Determine numerator exclusion for secondary Dx POA;

      if TPPS15 = . then QPPS15 = .;

      *** Risk adjust by risk category (Procedure Type)
         1 - No therapeutic procedure with any or no diagnostic procedures
         2 - Only minor therapeutic procedure with any or no diagnostic procedures 
         3 - One major therapeutic without diagnostic procedure
         4 - One major therapeutic with only minor diagnostic procedure(s)
         5 - One major therapeutic with major diagnostic procedure(s) 
         6 - Two major therapeutic procedures with any or no diagnostic procedures 
         7 - Three or more major therapeutic procedures with any or no diagnostic procedures;

      %PCLASSR_m;

      if TPPS15 NE . then do;
         if PRCLS2 = 0 and PRCLS4 = 0                     then HPPS15 = 1;
         else if PRCLS4 = 0  and PRCLS2 > 0               then HPPS15 = 2;
         else if PRCLS1 = 0 and PRCLS3 = 0 and PRCLS4 = 1 then HPPS15 = 3;
         else if PRCLS3 = 0 and PRCLS4 = 1 and PRCLS1 > 0 then HPPS15 = 4;
         else if PRCLS4 = 1 and PRCLS3 > 0                then HPPS15 = 5;
         else if PRCLS4 = 2                               then HPPS15 = 6;
         else if PRCLS4 >= 3                              then HPPS15 = 7;
         else                                                  HPPS15 = 9;
      end;

   end;


 * ------------------------------------------------------------------------- ;
 * --- PSI 18 : OBSTETRIC TRAUMA RATE - VAGINAL DELIVERY WITH INSTRUMENT --- ;
 * ------------------------------------------------------------------------- ;

   if %MDX($DELOCMD.) and %MPR($VAGDELP.) and %MPR($INSTRIP.)
   then do;

      TPPS18 = 0;

      if %MDX($OBTRAID.) then TPPS18 = 1;

   end;


 * ---------------------------------------------------------------------------- ;
 * --- PSI 19 : OBSTETRIC TRAUMA RATE - VAGINAL DELIVERY WITHOUT INSTRUMENT --- ;
 * ---------------------------------------------------------------------------- ;

   if %MDX($DELOCMD.) and %MPR($VAGDELP.) and not %MPR($INSTRIP.)
   then do;

      TPPS19 = 0;

      if %MDX($OBTRAID.) then TPPS19 = 1;

   end;


 * -------------------------------------------------------------- ;
 * --- IDENTIFY TRANSFERS --------------------------------------- ;
 * -------------------------------------------------------------- ;

  *** Flag transfers from another acute care hospital;
  if ASOURCE in (2) or POINTOFORIGINUB04 in ('4') then TRNSFER = 1;
  else  TRNSFER = 0;
  
  *** Label variable;
  label
  TRNSFER  = 'Transfer from Another Acute Care Hospital';


 * -------------------------------------------------------------- ;
 * --- Sync QPPS, TPPS and PPPS values -------------------------- ;
 * -------------------------------------------------------------- ;

    if QPPS03 in (.,1) then TPPS03 = .;
    if QPPS05 in (.,1) then TPPS05 = .;
    if QPPS06 in (.,1) then TPPS06 = .;
    if QPPS07 in (.,1) then TPPS07 = .;
    if QPPS08 in (.,1) then TPPS08 = .;
	if TPPS08 = . then do;
       TPPS08_HIP_FX =.; TPPS08_OTHER_FX=.;
	end;
    if QPPS09 in (.,1) then TPPS09 = .;
    if QPPS10 in (.,1) then TPPS10 = .;
    if QPPS11 in (.,1) then TPPS11 = .;
    if QPPS12 in (.,1) then TPPS12 = .;
    if QPPS13 in (.,1) then TPPS13 = .;
    if QPPS15 in (.,1) then TPPS15 = .;


 * ----------------------------------------------------------------------------------- ;
 * ---- ASSIGN DENOMINATORS FOR HOSPITAL_LEVEL PSIs BASED ON NON-MISSING NUMERATOR --- ;
 * ----------------------------------------------------------------------------------- ;

  array TPPS   TPPS02-TPPS04 TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE TPPS05-TPPS08 TPPS08_HIP_FX TPPS08_OTHER_FX TPPS09-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 TPPS18 TPPS19;
  array PPPS 3 PPPS02-PPPS04 PPPS04_DVT_PE PPPS04_PNEUMONIA PPPS04_SEPSIS PPPS04_SHOCK PPPS04_GIHEMORRHAGE PPPS05-PPPS08 PPPS08_HIP_FX PPPS08_OTHER_FX PPPS09-PPPS14 PPPS14_OPEN PPPS14_NONOPEN PPPS15 PPPS18 PPPS19;
  do over TPPS;
    if TPPS ge 0 then PPPS = 1;
    else PPPS = .;
  end;

run;


 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MEASURES OUTPUT FILE             --- ;
 * -------------------------------------------------------------- ;

proc contents data=OUTMSR.&OUTFILE_MEAS. position;
run;

proc print data=OUTMSR.&OUTFILE_MEAS. (obs=24);
title4 "FIRST 24 RECORDS IN OUTPUT data set &OUTFILE_MEAS.";
run;

 * --- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM proc means STATEMENTS --- ;

proc means data = OUTMSR.&OUTFILE_MEAS.(keep = DRG MDC MDRG YEAR DQTR
         AGECAT SEXCAT RACECAT PAYCAT LOS) n nmiss min max nolabels ;
     title4 "CATEGORICAL VARIABLES AND RANGES OF VALUES";
run; quit;

proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss sum mean  nolabels ;
     var TPPS02-TPPS04  TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE TPPS05-TPPS08 TPPS08_HIP_FX TPPS08_OTHER_FX TPPS09-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 TPPS18 TPPS19;
     title "PATIENT SAFETY INDICATOR NUMERATOR FOR HOSPITAL LEVEL INDICATORS (=SUM),DENOMINATOR (=N), AND OBSERVED RATE (MEAN) ";
run; quit;

proc means data = OUTMSR.&OUTFILE_MEAS. n nmiss sum mean nolabels ;
     var TPPS02-TPPS04  TPPS04_DVT_PE TPPS04_PNEUMONIA TPPS04_SEPSIS TPPS04_SHOCK TPPS04_GIHEMORRHAGE TPPS05-TPPS08 TPPS08_HIP_FX TPPS08_OTHER_FX TPPS09-TPPS14 TPPS14_OPEN TPPS14_NONOPEN TPPS15 ;
     title1 "PATIENT SAFETY INDICATOR NUMERATOR FOR HOSPITAL LEVEL INDICATORS (=SUM),DENOMINATORS (=N), AND OBSERVED RATE (MEAN) ";
     title2 "WITH POA MODIFIERS";
run; quit;

proc freq data = OUTMSR.&OUTFILE_MEAS.;
     tables TPPS04_DVT_PE*TPPS04_PNEUMONIA*TPPS04_SEPSIS*TPPS04_SHOCK*TPPS04_GIHEMORRHAGE
            TPPS04_DVT_PE*RegVarPS04_DVT_PE_ANY*RegVarPS04_DVT_PE_SEVERE
	        TPPS04_PNEUMONIA*RegVarPS04_PNEUMONIA_ANY*RegVarPS04_PNEUMONIA_SEVERE
	        TPPS04_SEPSIS*RegVarPS04_SEPSIS_ANY*RegVarPS04_SEPSIS_SEVERE
	        TPPS04_SHOCK*RegVarPS04_SHOCK_ANY*RegVarPS04_SHOCK_SEVERE
	        TPPS04_GIHEMORRHAGE*RegVarPS04_GIHEMORRHAGE_ANY*RegVarPS04_GIHEMORRHAGE_SEVERE
            TPPS08*TPPS08_HIP_FX*TPPS08_OTHER_FX/missing list;
run;
