*=================== PROGRAM: PSI17_HOSP_MEASURES.SAS ===========================;
*
*  DESCRIPTION: Assigns numerator and denominator flags for PSI 17,
*               BIRTH TRAUMA RATE - INJURY TO NEONATE.
*               This indicator is also included in the Pediatric
*               Quality Indicator module.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*  USER NOTE1: Make sure you have created the format library
*              using PSI17_FORMATS.SAS BEFORE running this program. 
*              This is done through the CONTROL program.
*
*  USER NOTE2: See the AHRQ_PSI17_SAS_v2024_ICD10_Release_Notes.txt 
*              file for software change notes.
*
*  USER NOTE3:  The AHRQ QI software does not support the calculation of
*               weighted estimates and standard errors using complex
*               sampling designs.
*
* ===============================================================================;

 title2 'PSI17_HOSP_MEASURES PROGRAM';
 title3 'AHRQ PATIENT SAFETY INDICATORS: ASSIGN PSI 17 TO INPATIENT DATA';

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
     %put "WARNING: The input data does not have PAY1. The software creates a placeholder for PAY1 as PAY1=999 for the programs to run";
   %end;
   %if &RACE_PROVIDED. = 0 %then %do;
     %put "WARNING: The input data does not have RACE. The software creates a placeholder for RACE as RACE=999 for the programs to run";
   %end;
 %mend check_pay1_race;
 %check_pay1_race;

 * -------------------------------------------------------------- ;
 * --- CREATE A PERMANENT DATASET CONTAINING ALL RECORDS THAT --- ;
 * --- WILL NOT BE INCLUDED IN ANALYSIS BECAUSE KEY VARIABLE  --- ;
 * --- VALUES ARE MISSING.                                    --- ;
 * -------------------------------------------------------------- ;

 data   OUTMSR.&DELFILE.
 	(keep=KEY HOSPID SEX AGE DX1 DRG MDC YEAR DQTR);
 set 	INMSR.&DISCHARGE.;
 if (AGE lt 0) or (AGE ge 18 or %MDX1($MDC14PRINDX.)) or (missing(SEX)) or
    (missing(DX1)) or (missing(DQTR)) or (missing(YEAR)) or (DRG = 999) or
    (&MDC_PROVIDED. = 1 and missing(MDC));
 run;

 * ---------------------------------------------------------------- ;
 * --- PATIENT SAFETY INDICATOR (PSI) NAMING CONVENTION:        --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PATIENT SAFETY INDICATOR --- ;
 * --- AS NUMERATOR, 'T' ("TOP"). THE SECOND LETTER IDENTIFIES  --- ;
 * --- THE TYPE OF INDICATOR WITH 'P' FOR HOSPITAL LEVEL. THE   --- ;
 * --- NEXT TWO CHARACTERS ARE 'PS'. THE LAST TWO DIGITS ARE    --- ;
 * --- 17 FOR INDICATOR PSI 17.                                 --- ;
 * ---------------------------------------------------------------- ;
 
 data   OUTMSR.&OUTFILE_MEAS.
    (keep=KEY HOSPID DRG MDC YEAR DQTR
          PAGECAT AGEDCAT BWHTCAT SEXCAT RACECAT PAYCAT COVIDDX
          TPPS17 AGE AGEDAY &OUTFILE_KEEP);
 set   INMSR.&DISCHARGE.
     (keep=KEY HOSPID DRG MDC SEX AGE AGEDAY
           YEAR DQTR %ADDPAY1_RACE POINTOFORIGINUB04 ATYPE
           DX1-DX&NDX. DXPOA1-DXPOA&NDX. &OUTFILE_KEEP);

 label
 HOSPID   = 'Hospital Identification Number'
 key = 'Unique record identifier'
 ;

 ARRAY DX (&NDX.) $  DX1 - DX&NDX.;
 ARRAY DXPOA (&NDX.) $  DXPOA1 - DXPOA&NDX.;

 * ----------------------------------------------------------------- ;
 * --- DELETE NON-PEDIATRIC RECORDS AND RECORDS WITH MISSING VALUES  ;
 * --- FOR AGE, SEX, DX1, DQTR, YEAR, MDC OR DRG = 999           --- ;
 * ----------------------------------------------------------------- ;
 
 if missing(SEX) then delete;
 if AGE lt 0 then delete;
 if AGE ge 18 or %MDX1($MDC14PRINDX.) then delete;
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
 * --- DEFINE STRATIFIER: AGE CATEGORY -------------------------- ;
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
 * --- DEFINE STRATIFIER: AGEDAY CATEGORY ----------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib AGEDCAT length=3
      label='Age in Days Categories';

 select;
   when (      AGEDAY <   0)  AGEDCAT = 0;
   when (0  <= AGEDAY <= 28)  AGEDCAT = 1;
   when (29 <= AGEDAY <= 60)  AGEDCAT = 2;
   when (61 <= AGEDAY <= 90)  AGEDCAT = 3;
   when (91 <= AGEDAY      )  AGEDCAT = 4;
   otherwise AGEDCAT = 0;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: SEX CATEGORY -------------------------- ;
 * -------------------------------------------------------------- ;
 
 attrib SEXCAT length=3
   label  = 'Sex Categories';

 select (SEX);
   when (1)  SEXCAT = 1;
   when (2)  SEXCAT = 2;
   otherwise SEXCAT = 0;
 end;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: BIRTH WEIGHT CATEGORY ----------------- ;
 * -------------------------------------------------------------- ;
 
 attrib BWHTCAT length=3
   label  = 'Birthweight Categories';

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

 attrib TPPS17 length=8
   label='PSI 17 Birth Trauma Rate - Injury to Neonate (Numerator)';


 * -------------------------------------------------------------- ;
 * --- IDENTIFY NEONATES AND NEWBORNS --------------------------- ;
 * -------------------------------------------------------------- ;

   NEONATE = 0;
   if 0 <= AGEDAY <= 28 then NEONATE = 1;
   else if AGEDAY le .Z and AGE = 0 then do;
      if ATYPE IN (4) or %MDX($LIVEBND.)
      then NEONATE = 1;
   end;

   NEWBORN = 0;
   if NEONATE then do;
      if %MDX($LIVEBND.) and NOT AGEDAY > 0 then NEWBORN = 1;
      else if ATYPE IN (4) and
              ((AGEDAY = 0 and NOT %MDX($LIVEB2D.)) or
               POINTOFORIGINUB04 IN ('5'))
      then NEWBORN = 1;
   end;


 * --------------------------------------------------------- ;
 * ---   PSI 17 : BIRTH TRAUMA RATE - INJURY TO NEONATE  --- ;
 * --------------------------------------------------------- ;

   if NEWBORN then do;

      TPPS17 = 0;
      if %MDX($BIRTHID.) then TPPS17 = 1;

   *** Exclude Birth weight less than 2000g;
      if %MDX($PRETEID.) then TPPS17 = .;

   *** Exclude Osteogenesis imperfecta;
      if %MDX($OSTEOID.) then TPPS17 = .;

   end;


run;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MEASURES OUTPUT FILE             --- ;
 * -------------------------------------------------------------- ;

proc means data=OUTMSR.&OUTFILE_MEAS. n nmiss min max mean sum nolabels;
title4 'PSI 17 MEASURE OUTPUT SUMMARY STATISTICS';
run;

proc contents data=OUTMSR.&OUTFILE_MEAS. position;
title5 'PSI 17 MEASURE OUTPUT CONTENTS';
run;

proc print data=OUTMSR.&OUTFILE_MEAS. (obs=24);
  title6 "FIRST 24 RECORDS IN OUTPUT DATA SET &OUTFILE_MEAS.";
run;
