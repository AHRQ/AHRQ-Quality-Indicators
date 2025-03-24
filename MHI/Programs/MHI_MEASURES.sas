*========================= PROGRAM: MHI_MEASURES.SAS ===============================;
*
*  DESCRIPTION:
*         Assigns the Maternal Health Indicators outcomes and stratifiers
*         to inpatient records.
*         Variables created by this program are TAMHXX, stratifiers, and 
*         severity indicators.
*
*  VERSION: SAS Beta version of MHI v2024
*  RELEASE DATE: SEPTEMBER 2024
*
*  USER NOTE1: Make sure you have created the format library
*              using MHI_FORMATS.SAS BEFORE running this program. 
*              This is done through the CONTROL program.
*
*  USER NOTE2: The AHRQ QI software does not support the calculation of weighted
*              estimates and standard errors using complex sampling designs.
*
*  USER NOTE3: See the AHRQ_MHI_SAS_v2024_ICD10_Release_Notes.txt file for 
*              software change notes.
*
*  USER NOTE4: Although some of the exclusion criteria for present on admission 
*              conditions were removed in v2020, some of the original logic
*              is retained for potential use in future versions.
*
*===================================================================================;

 title2 'MHI_MEASURES PROGRAM';
 title3 'AHRQ MATERNAL HEALTH INDICATORS: ASSIGN MHIs TO INPATIENT DATA';

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
 * --- VALUES ARE MISSING. REVIEW AFTER RUNNING MHI_MEASURES.     --- ;
 * ------------------------------------------------------------------ ;

 data   OUTMSR.&DELFILE.
     (keep=KEY HOSPID SEX AGE DX1 YEAR DQTR);
 set     INMSR.&DISCHARGE.;
 if (AGE lt 12) or (AGE gt 55) or (missing(SEX)) or
    (missing(DX1)) or (missing(DQTR)) or (missing(YEAR));
 run;
 
 * ------------------------------------------------------------------ ;
 * --- MATERNAL HEALTH INDICATORS (MHI) NAMING CONVENTION:        --- ;
 * --- THE FIRST LETTER IDENTIFIES THE MATERNAL HEALTH INDICATORS --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:                         --- ;
 *               (T) NUMERATOR ("TOP")                            --- ;
 *               (P) POPULATION ("POP") IS DENOMINATOR            --- ;
 * --- THE SECOND LETTER IDENTIFIES THE MHI AS AN AREA (A)        --- ;
 * --- LEVEL INDICATOR. THE NEXT TWO CHARACTERS ARE               --- ;
 * --- ALWAYS 'MH' for MHI. THE LAST TWO DIGITS ARE THE           --- ;
 * --- INDICATOR NUMBER.                                          --- ;
 * ------------------------------------------------------------------ ;

     data   OUTMSR.&OUTFILE_MEAS.
        (keep=KEY HOSPID YEAR DQTR AGE SEX
              AGECAT SEXCAT PAYCAT RACECAT POVCAT HOSPST
              MYOCARD ANEURYSM ACUTE_RENAL RESP_DISTRESS AM_FLUID CARD_ARR CONV_CARD DISS_INTRA ECLAMPSIA 
              HEART_FAIL PUERP PULM_ED ANES_COMP SEPSIS SHOCK SICKLE AIR_THROMB HYSTER TRACHEO VENT
              MATH_ABORT DECEASED_FLAG ACUTE_RENAL3 DISS_INTRA3
              TAMH01 TAMH02 TAMH03 &OUTFILE_KEEP);
     set  INMSR.&DISCHARGE.
        (keep=KEY HOSPID SEX AGE YEAR DQTR HOSPST PSTCO
              PAY1 DISP POINTOFORIGINUB04
              DX1-DX&NDX. PR1-PR&NPR. %ADDPAY1_RACE
              DXPOA1-DXPOA&NDX. &OUTFILE_KEEP
        );

     label
     SEX = 'Sex of the patient'
     key = 'Unique record identifier'
     ;

     ARRAY DX(&NDX.)    $ DX1-DX&NDX.;
     ARRAY DXPOA(&NDX.) $ DXPOA1-DXPOA&NDX.;
     ARRAY PR(&NPR.)    $ PR1-PR&NPR.;

     * ---------------------------------------------------------------- ;
     * --- DEFINE FIPS STATE COUNTY CODES AND FIPS POVERTY CATEGORY --- ;
     * ---------------------------------------------------------------- ;

     attrib FIPSTCO length=$5
     label='FIPS State County Code';
     FIPSTCO = put(PSTCO,Z5.);

     attrib POVCAT length=3
     label='FIPS Poverty Categories';
     POVCAT = put(FIPSTCO,$POVCAT.);

     * --------------------------------------------------------------- ;
     * -- DELETE NON-ADULT RECORDS WITH AGE <12 or AGE >55         --- ;
     * -- DELETE RECORDS WITH MISSING AGE, SEX, DX1, DQTR, YEAR    --- ;
     * --------------------------------------------------------------- ;
     
     if missing(SEX) then delete;
     if AGE lt 12 then delete;
     if AGE gt 55 then delete;
     if missing(DX1) then delete;
     if missing(DQTR) then delete;
     if missing(YEAR) then delete;

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

    * --------------------------------------------------------------------------------- ;
    * ------------------------- MHI NUMERATOR/DENOMINAOR ------------------------------ ;
    * --------------------------------------------------------------------------------- ;


     *if the patient had a delivery;
       if  %MDX($DX_Delivery.) then deliv_dx = 1;
       if  %MPR($PR_Delivery.) then deliv_pr = 1;

       if (deliv_dx=1 or deliv_pr = 1) then do;

               *patient is in the denominator if they had a delivery;
                TAMH01 = 0;
                TAMH02 = 0;
                TAMH03 = 0;

                myocard = 0;
                aneurysm = 0;
                acute_renal = 0;
                acute_renal3 = 0;
                resp_distress = 0;
                am_fluid = 0;
                card_arr = 0;
                conv_card = 0;
                diss_intra = 0;
                diss_intra3 = 0;
                eclampsia = 0;
                heart_fail = 0;
                puerp = 0;
                pulm_ed = 0;
                anes_comp = 0;
                sepsis = 0;
                shock = 0;
                sickle = 0;
                air_thromb = 0;
                hyster = 0;
                tracheo = 0;
                vent = 0;
                deceased_flag = 0;


                if %MDX($DX_Acute_MyoCard_Infarct.) then myocard = 1;
                if %MDX($DX_Aneurysm.) then aneurysm = 1;
                if %MDX($DX_Acute_Renal_Fail.) then acute_renal = 1;
                if %MDX($DX_Acute_Renal_Fail.) and %MPR($DIALYIP.) then acute_renal3 = 1;
                if %MDX($DX_Acute_Resp_Distress.) then resp_distress = 1;
                if %MDX($DX_Amniotic_Fluid_Emb.) then am_fluid = 1;
                if %MDX($DX_Card_Arrest_Vent_Fib.) then card_arr = 1;
                if %MPR($PR_Conv_Cardiac_Rhythm.) then conv_card = 1;
                if %MDX($DX_Diss_Intravasc_Coagul.) then diss_intra =1;
                if %MDX($DX_Diss_Intravasc_Coagul3_.) then diss_intra3 =1;
                if %MDX($DX_Eclampsia.) then eclampsia = 1;
                if %MDX($DX_Heart_Fail_Surgery.) then heart_fail = 1;
                if %MDX($DX_Puerp_Cerebrovascular.) then puerp = 1;
                if %MDX($DX_Pulmonary_Edema.) then pulm_ed = 1;
                if %MDX($DX_Severe_Anesth_Comp.) then anes_comp = 1;
                if %MDX($DX_Sepsis.) then sepsis = 1;
                if %MDX($DX_Shock.) then shock = 1;
                if %MDX($DX_Sickle_Cell_Crisis.) then sickle = 1;
                if %MDX($DX_Air_Thrombotic_Embolism.) then air_thromb = 1;
                if %MPR($PR_Hysterectomy.) then hyster = 1;
                if %MPR($PR_Temp_Tracheostomy.) then tracheo = 1;
                if %MPR($PR_Ventilation.) then vent = 1;
                if DISP = 20 then deceased_flag = 1; 
                else deceased_flag = 0;            


                TAMH01 = max(0,
                            myocard 
                            ,aneurysm
                            ,acute_renal
                            ,resp_distress
                            ,am_fluid
                            ,card_arr
                            ,conv_card
                            ,diss_intra
                            ,eclampsia
                            ,heart_fail
                            ,puerp
                            ,pulm_ed
                            ,anes_comp
                            ,sepsis
                            ,shock
                            ,sickle
                            ,air_thromb
                            ,hyster
                            ,tracheo
                            ,vent
                    );
                
                TAMH02 = max(0,
                            myocard 
                            ,aneurysm
                            ,acute_renal
                            ,resp_distress
                            ,am_fluid
                            ,card_arr
                            ,conv_card
                            ,diss_intra
                            ,eclampsia
                            ,heart_fail
                            ,puerp
                            ,pulm_ed
                            ,anes_comp
                            ,sepsis
                            ,shock
                            ,sickle
                            ,air_thromb
                            ,hyster
                            ,tracheo
                            ,vent
                            ,deceased_flag
                    );

                    
                TAMH03 = max(0,
                            myocard 
                            ,aneurysm
                            ,acute_renal3
                            ,resp_distress
                            ,am_fluid
                            ,card_arr
                            ,conv_card
                            ,diss_intra3
                            ,eclampsia
                            ,heart_fail
                            ,puerp
                            ,pulm_ed
                            ,anes_comp
                            ,sepsis
                            ,shock
                            ,sickle
                            ,air_thromb
                            ,hyster
                            ,tracheo
                            ,vent
                            ,deceased_flag
                    );

       end;

       *if discharge had abortion, do not include;
        if %MDX($DX_Abortion.) or 
           %MPR($PR_Abortion.) then do;
                TAMH01 = .;
                TAMH02 = .;
                TAMH03 = .;
                math_abort = 1;    
        end;

       *label the numerator indicators and exclusion flag;
        label
            myocard       = "Acute Myocardial Infarction Rate"
            aneurysm      = "Aneurysm Rate"
            acute_renal   = "Acute Renal Failure Rate"
            acute_renal3  = "Refined Acute Renal Failure Rate"
            resp_distress = "Adult Respiratory Distress Syndrome Rate"
            am_fluid      = "Amniotic Fluid Embolism Rate"
            card_arr      = "Cardiac Arrest/Ventricular Fibrillation Rate"
            conv_card     = "Conversion of Cardiac Rhythm Rate"
            diss_intra    = "Disseminated Intravascular Coagulation Rate"
            diss_intra3   = "Refined Disseminated Intravascular Coagulation Rate"
            eclampsia     = "Eclampsia Rate"
            heart_fail    = "Heart Failure/Arrest during Surgery or Procedure Rate"
            puerp         = "Puerperal Cerebrovascular Disorder Rate"
            pulm_ed       = "Pulmonary Edema/Acute Heart Failure Rate"
            anes_comp     = "Severe Anesthesia Complications Rate"
            sepsis        = "Sepsis Rate"
            shock         = "Shock Rate"
            sickle        = "Sickle Cell Disease with Crisis Rate"
            air_thromb    = "Air and Thrombotic Embolism Rate"
            hyster        = "Hysterectomy Rate"
            tracheo       = "Temporary Tracheostomy Rate"
            vent          = "Ventilation Rate" 
            deceased_flag = "In-Hospital Mortality Rate"
            math_abort    = "Exclusion flag for abortion"
            TAMH01        = "Severe Maternal Morbidity Rate (20 Indicators) (Numerator)"
            TAMH02        = "Severe Maternal Morbidity (20 Indicators) Plus In-Hospital Mortality Rate (Numerator)"
            TAMH03        = "Refined Severe Maternal Morbidity (20 Indicators) Plus In-Hospital Mortality Rate, Beta (Numerator)";
    run;


* -------------------------------------------------------------- ;
* --- CONTENTS AND MEANS OF MEASURES OUTPUT FILE             --- ;
* -------------------------------------------------------------- ;
  
proc MEANS data=OUTMSR.&OUTFILE_MEAS. N NMISS MIN MAX MEAN SUM;
title "MATERNAL HEALTH INDICATORS (=SUM),DENOMINATOR (=N), AND OBSERVED RATE (MEAN)";
run;

proc CONTENTS data=OUTMSR.&OUTFILE_MEAS. POSITION;
title "MATERNAL HEALTH INDICATORS MEASURE OUTPUT";
run;

proc PRINT data=OUTMSR.&OUTFILE_MEAS.(OBS=24);
title4 "FIRST 24 RECORDS IN OUTPUT DATA SET &OUTFILE_MEAS.";
run;