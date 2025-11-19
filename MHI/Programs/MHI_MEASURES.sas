*========================= PROGRAM: MHI_MEASURES.SAS ===============================;
*
*  DESCRIPTION:
*         Assigns the Maternal Health Indicators outcomes and stratifiers
*         to input records.
*         Variables created by this program are TAMHXX, stratifiers, and 
*         severity indicators.
*
*  VERSION: SAS Beta version of MHI v2025
*  RELEASE DATE: AUGUST 2025
*
*  USER NOTE1: Make sure you have created the format library
*              using MHI_FORMATS.SAS BEFORE running this program. 
*              This is done through the CONTROL program.
*
*  USER NOTE2: The AHRQ QI software does not support the calculation of weighted
*              estimates and standard errors using complex sampling designs.
*
*  USER NOTE3: See the AHRQ_MHI_SAS_v2025_ICD10_Release_Notes.txt file for 
*              software change notes.
*
*===================================================================================;

 title2 'MHI_MEASURES PROGRAM';
 title3 'AHRQ MATERNAL HEALTH INDICATORS: ASSIGN MHIs TO INPUT DATA';

 * ---------------------------------------------------------------------- ;
 * --- DETERMINE IF DAYSTOEVENT HAS MISSING VALUES ON THE INPUT FILE  --- ;
 * ---------------------------------------------------------------------- ;

 %macro check_daystoevent;
   %if &ref_pop. = 2 or &ref_pop. = 3 %then %do;
      proc sql noprint;
         select nmiss(daystoevent) into :n_miss
         from INMSR.&DISCHARGE.;
      quit;

      %if &n_miss. > 0 %then %do;
         %put "WARNING: Some discharges have missing daystoevent. The measure numerators use the daystoevent variable for MHIs 05-11";
      %end;
   %end;
 %mend check_daystoevent;
 %check_daystoevent;
 
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
 * --- DETERMINE YEAR AND QUARTER FOR THE POSTPARTUM MEASURES     --- ;
 * ------------------------------------------------------------------ ;
 
%macro chk_yr_qtr_post;
   %if &ref_pop. = 2 or &ref_pop. =3 %then %do;
      %global yra qtra;
      proc sql;
         create table agg as
         select year, dqtr, count(*) as cnt
         from INMSR.&DISCHARGE.
         group by year, dqtr;
      quit;

      proc sort data=agg; 
         by descending year descending dqtr;
      run;
      data agg;
         set agg(drop=cnt); 
         order=_N_;
      run;

      *identify latest year and quarter in the data;
      *identify last four quarters of data;
      proc sql;
         select year, dqtr into: yra, : qtra
         from agg
         where order=1;
      quit;

      %put yra=&yra.;
      %put qtra=&qtra.;

   %end;
%mend chk_yr_qtr_post;
%chk_yr_qtr_post;

 * ------------------------------------------------------------------ ;
 * --- CREATE A PERMANENT DATASET CONTAINING ALL RECORDS THAT     --- ;
 * --- WILL NOT BE INCLUDED IN ANALYSIS BECAUSE KEY VARIABLE      --- ;
 * --- VALUES ARE MISSING. REVIEW AFTER RUNNING MHI_MEASURES.     --- ;
 * ------------------------------------------------------------------ ;

 data  OUTMSR.&DELFILE.(keep=KEY HOSPID SEX AGE DX1 YEAR DQTR);
    set INMSR.&DISCHARGE.;
    if (AGE lt 12) or (AGE gt 55) or (missing(SEX)) or (missing(DX1)) or (missing(DQTR)) or (missing(YEAR));
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

%macro PrepData;
%if &ref_pop. = 1 %then %do;
   data temp;
      set INMSR.&DISCHARGE.(keep = KEY HOSPID SEX AGE YEAR DQTR HOSPST PSTCO DISP 
                                   DX1-DX&NDX. PR1-PR&NPR. %ADDPAY1_RACE &OUTFILE_KEEP. &CUSTOM_STRATUM.);
   run;
%end;
%else %if &ref_pop. = 2 or &ref_pop. = 3 %then %do;
   data temp;
      set INMSR.&DISCHARGE.(keep = KEY HOSPID SEX AGE YEAR DQTR HOSPST PSTCO DISP
                                           DX1-DX&NDX. PR1-PR&NPR. PRDAY1-PRDAY&NPR. %ADDPAY1_RACE
                                           &OUTFILE_KEEP. LOS VISITLINK DAYSTOEVENT INPATIENT &CUSTOM_STRATUM.);
      %include MacLib(MHI_MEASURES_macro.sas);
   run;

   proc sort data=temp;
      by hospst visitlink daystoevent;
   run;
%end;
%mend PrepData;
%PrepData;

 * --------------------------------------------------------------------------------- ;
 * ------------------------- MHI NUMERATOR/DENOMINATOR ----------------------------- ;
 * --------------------------------------------------------------------------------- ;

%let vars  = myocard aneurysm resp_distress am_fluid card_arr conv_card eclampsia heart_fail puerp pulm_ed anes_comp sepsis shock sickle air_thromb hyster tracheo vent;
%let vars2 = myocard,aneurysm,resp_distress,am_fluid,card_arr,conv_card,eclampsia,heart_fail,puerp,pulm_ed,anes_comp,sepsis,shock,sickle,air_thromb,hyster,tracheo,vent;

%let vars_post  =myocard_post aneurysm_post resp_distress_post am_fluid_post   card_arr_post conv_card_post eclampsia_post heart_fail_post puerp_post pulm_ed_post anes_comp_post 
                 sepsis_post  shock_post    sickle_post        air_thromb_post hyster_post   tracheo_post   vent_post;
%let vars2_post =myocard_post,aneurysm_post,resp_distress_post,am_fluid_post,  card_arr_post,conv_card_post,eclampsia_post,heart_fail_post,puerp_post,pulm_ed_post,anes_comp_post, 
                 sepsis_post, shock_post,   sickle_post,       air_thromb_post,hyster_post,  tracheo_post,  vent_post;

%macro DefineMeasures;

data temp;

   set temp;

   * -------------------------------------------------------------- ;
   * --- DEFINE MHI 01 - MHI 04 UNLINKED INPATIENT MEASURES     --- ;
   * -------------------------------------------------------------- ;
   
   %if &ref_pop. = 1 %then %do;

      %include MacLib(MHI_MEASURES_macro.sas);

      array indflags(23) &vars. acute_renal diss_intra acute_renal3 diss_intra3 deceased_flag;

      if not(%MDX($DX_Abortion.) or  %MPR($PR_Abortion.)) and (deliv_dx=1 or deliv_pr=1) then do;

         *patient is in the denominator if they had a delivery;
         TAMH01 = 0;
         TAMH02 = 0;
         TAMH03 = 0;
         TAMH04 = 0;

         do i = 1 to 23;
            indflags(i) = 0;
         end; 

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

         TAMH01 = max(0, &vars2., acute_renal,  diss_intra);
         TAMH02 = max(0, &vars2., acute_renal,  diss_intra,  deceased_flag);
         TAMH03 = max(0, &vars2., acute_renal3, diss_intra3, deceased_flag);
         
         if %MDX($DX_BHSUD_DEL.) then TAMH04 = 1;

      end;

      *label the numerator indicators and exclusion flag;
      label myocard       = "Acute Myocardial Infarction Rate, at Delivery"
            aneurysm      = "Aneurysm Rate, at Delivery"
            acute_renal   = "Acute Renal Failure Rate, at Delivery"
            acute_renal3  = "Refined Acute Renal Failure Rate, at Delivery"
            resp_distress = "Adult Respiratory Distress Rate, at Delivery"
            am_fluid      = "Amniotic Fluid Embolism Rate, at Delivery"
            card_arr      = "Cardiac Arrest/Ventricular Fibrillation Rate, at Delivery"
            conv_card     = "Conversion of Cardiac Rhythm Rate, at Delivery"
            diss_intra    = "Disseminated Intravascular Coagulation Rate, at Delivery"
            diss_intra3   = "Refined Disseminated Intravascular Coagulation Rate, at Delivery"
            eclampsia     = "Eclampsia Rate, at Delivery"
            heart_fail    = "Heart Failure/Arrest during or following Surgery or Procedure Rate, at Delivery"
            puerp         = "Puerperal Cerebrovascular Disorder Rate, at Delivery"
            pulm_ed       = "Pulmonary Edema/Acute Heart Failure Rate, at Delivery"
            anes_comp     = "Severe Anesthesia Complications Rate, at Delivery"
            sepsis        = "Sepsis Rate, at Delivery"
            shock         = "Shock Rate, at Delivery"
            sickle        = "Sickle Cell Disease with Crisis Rate, at Delivery"
            air_thromb    = "Air and Thrombotic Embolism Rate, at Delivery"
            hyster        = "Hysterectomy Rate, at Delivery"
            tracheo       = "Temporary Tracheostomy Rate, at Delivery"
            vent          = "Respiratory Ventilation Rate, at Delivery"
            deceased_flag = "In-Hospital Mortality Rate, at Delivery"
            TAMH01        = "Inpatient Severe Maternal Morbidity Rate, at Delivery (20 indicators) (Numerator)"
            TAMH02        = "Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, at Delivery (20 indicators plus in-hospital mortality) (Numerator)"
            TAMH03        = "Refined Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, at Delivery, Beta (20 indicators plus in-hospital mortality) (Numerator)"
            TAMH04        = "Inpatient Mental Health and Substance Use Disorders Rate, at Delivery, Beta (Numerator)";
   %end;

   %else %if &ref_pop. = 2 or &ref_pop. = 3 %then %do;

      by hospst visitlink daystoevent;

      ARRAY PRDAY(&NPR.) PRDAY1-PRDAY&NPR.;

      *identify the index delivery in the data prior to the last quarter;

      %if &ref_pop. = 2 %then %do;
      if not(%MDX($DX_Abortion.) or  %MPR($PR_Abortion.)) then do;
         if (deliv_dx=1 or deliv_pr=1) and INPATIENT=1 and ((year = &yra. and dqtr <&qtra.) or year <&yra.) then index_delivery=1; 
         else index_delivery=0;
      end;
      %end;
      %else %if &ref_pop. = 3 %then %do;
      if not(%MDX($DX_Abortion.) or  %MPR($PR_Abortion.)) then do;
         if (deliv_dx=1 or deliv_pr=1) and INPATIENT=1 and ((year = &yra. and dqtr <&qtra.) or year <&yra.) then index_delivery=1; 
         else index_delivery=0;
      end;
      %end;

      *identify the date associated with the index_delivery;
      %MPRDAY($PR_Delivery.);
      delivery_date = MPRDAY;

      *Among index_deliveries, if the delivery_date is missing, then set it to 0;
      if index_delivery=1 and delivery_date = . then delivery_date=0;

      *Limit the discharges to 42 days from delivery using the delivery_date and DaysToEvent for every discharge;
      retain index_daystoevent index_delivery_date;

      *initialize variables;
      if first.visitlink then do; 
         index_daystoevent=.;
         index_delivery_date=.;
      end;

      *assign variables for the index event;
      if index_delivery=1 then do; 
         index_daystoevent=daystoevent;
         index_delivery_date=delivery_date;
      end;

      %if &ref_pop. = 2 %then %do;

      * -------------------------------------------------------------- ;
      * --- DEFINE MHI 05 - MHI 07 LINKED INPATIENT MEASURES       --- ;
      * -------------------------------------------------------------- ;

      array indflags_post(23) &vars_post. acute_renal_post diss_intra_post acute_renal3_post diss_intra3_post deceased_flag_post;

      *Includes index_delivery discharges;
      if (daystoevent = index_daystoevent) or 0 <= (daystoevent-index_daystoevent-index_delivery_date)<=42 then do; 

         TAMH05 = 0;
         TAMH06 = 0;
         TAMH07 = 0;
           
         do i = 1 to 23;
            indflags_post(i)=0;
         end;

         if %MDX($DX_Acute_MyoCard_Infarct.) then myocard_post = 1;
         if %MDX($DX_Aneurysm.) then aneurysm_post = 1;
         if %MDX($DX_Acute_Renal_Fail.) then acute_renal_post = 1;
         if %MDX($DX_Acute_Renal_Fail.) and %MPR($DIALYIP.) then acute_renal3_post = 1;
         if %MDX($DX_Acute_Resp_Distress.) then resp_distress_post = 1;
         if %MDX($DX_Amniotic_Fluid_Emb.) then am_fluid_post = 1;
         if %MDX($DX_Card_Arrest_Vent_Fib.) then card_arr_post = 1;
         if %MPR($PR_Conv_Cardiac_Rhythm.) then conv_card_post = 1;
         if %MDX($DX_Diss_Intravasc_Coagul.) then diss_intra_post =1;
         if %MDX($DX_Diss_Intravasc_Coagul3_.) then diss_intra3_post =1;
         if %MDX($DX_Eclampsia.) then eclampsia_post = 1;
         if %MDX($DX_Heart_Fail_Surgery.) then heart_fail_post = 1;
         if %MDX($DX_Puerp_Cerebrovascular.) then puerp_post = 1;
         if %MDX($DX_Pulmonary_Edema.) then pulm_ed_post = 1;
         if %MDX($DX_Severe_Anesth_Comp.) then anes_comp_post = 1;
         if %MDX($DX_Sepsis.) then sepsis_post = 1;
         if %MDX($DX_Shock.) then shock_post = 1;
         if %MDX($DX_Sickle_Cell_Crisis.) then sickle_post = 1;
         if %MDX($DX_Air_Thrombotic_Embolism.) then air_thromb_post = 1;
         if %MPR($PR_Hysterectomy.) then hyster_post = 1;
         if %MPR($PR_Temp_Tracheostomy.) then tracheo_post = 1;
         if %MPR($PR_Ventilation.) then vent_post = 1;
         if DISP = 20 then deceased_flag_post = 1;            
                
         TAMH05 = max(0, &vars2_post., acute_renal_post,  diss_intra_post);
         TAMH06 = max(0, &vars2_post., acute_renal_post,  diss_intra_post,  deceased_flag_post);
         TAMH07 = max(0, &vars2_post., acute_renal3_post, diss_intra3_post, deceased_flag_post);

        
         output;
      end;

      %end;

      %else %if &ref_pop. = 3 %then %do;

      * -------------------------------------------------------------- ;
      * --- DEFINE MHI 08 - MHI 11 LINKED INPATIENT/ED MEASURES    --- ;
      * -------------------------------------------------------------- ;

      *Initialize before the IF condition below for the discharges including the index delivery;
         TAMH08  = 0;
         TAMH09  = 0;
         TAMH10A = 0;
         TAMH10B = 0;
         TAMH10  = 0;
         TAMH11  = 0;

         BHSUD_POST = 0;
         SSH_POST   = 0;
         SUD_POST   = 0;
         OD_POST    = 0;
         SUD_OD_POST= 0;
         PMAD_POST  = 0;

      *Does not include index delivery discharges;
      if (daystoevent ne index_daystoevent) and 0 < (daystoevent-index_daystoevent-index_delivery_date)<=42 then do;
         if %MDX($DX_BHSUD_POST.) then BHSUD_POST = 1;
         if %MDX($DX_SSH_POST.)   then SSH_POST   = 1;
         if %MDX($DX_SUD_POST.)   then SUD_POST   = 1;
         if %MDX($DX_OD_POST.)    then OD_POST    = 1;
         if (%MDX($DX_SUD_POST.) or %MDX($DX_OD_POST.)) then SUD_OD_POST = 1;
         if %MDX($DX_PMAD_POST.)  then PMAD_POST  = 1;

         TAMH08  = max(0, BHSUD_POST);
         TAMH09  = max(0, SSH_POST);
         TAMH10A = max(0, SUD_POST);
         TAMH10B = max(0, OD_POST);
         TAMH10  = max(0, SUD_OD_POST);
         TAMH11  = max(0, PMAD_POST);

     end;

     output;

      %end; 
   %end; 

run;

%mend DefineMeasures;
%DefineMeasures;

 * -------------------------------------------------------------- ;
 * --- CREATE A SINGLE RECORD PER PATIENT / INDEX EVENT       --- ;
 * -------------------------------------------------------------- ;

%macro Dorollup;
%if &ref_pop.=1 %then %do;

   data OUTMSR.&OUTFILE_MEAS.;
      set temp(keep = KEY HOSPID YEAR DQTR AGE SEX
                      AGECAT SEXCAT PAYCAT RACECAT POVCAT HOSPST
                      &vars. acute_renal diss_intra acute_renal3 diss_intra3 deceased_flag
                      TAMH01 TAMH02 TAMH03 TAMH04 &OUTFILE_KEEP. &CUSTOM_STRATUM.);
   run;

%end;

%else %if &ref_pop.=2 %then %do;

   %let keepvars = YEAR DQTR PAYCAT RACECAT POVCAT &CUSTOM_STRATUM.
                   &vars_post. acute_renal_post diss_intra_post acute_renal3_post diss_intra3_post deceased_flag_post
                   TAMH05 TAMH06 TAMH07 ;

   *Roll up the overall measures (MHI 05 - MHI 07) and sub-indicators for each condition 42 days postpartum by HOSPST, visitlink, index_daystoevent and index_delivery_date;
   *Take the maximum of the variables across the discharges;
   proc sql;
      create table index_delivery_rolledup as
      select  hospst
             ,visitlink
             ,index_daystoevent  
             ,index_delivery_date
             %do i= 1 %to %sysfunc(countw(&keepvars.));
             ,max(%scan(&keepvars.,&i.)) as %scan(&keepvars.,&i.)
             %end;
      from temp(where=(not missing(index_delivery_date)))
      group by hospst, visitlink, index_daystoevent, index_delivery_date;
   quit;

   title2 "Check the variables after rollup";
   proc freq data=index_delivery_rolledup;
      tables  &keepvars. TAMH05*TAMH06*TAMH07 /missing list;
   run;

   data OUTMSR.&OUTFILE_MEAS.;
      retain HOSPST VISITLINK INDEX_DAYSTOEVENT INDEX_DELIVERY_DATE &keepvars.;
      set index_delivery_rolledup;

      *label the numerator indicators and flags;
      label myocard_post      = "Acute Myocardial Infarction Rate through 42 Days postpartum "
            aneurysm_post     = "Aneurysm Rate through 42 Days postpartum "
            acute_renal_post  = "Acute Renal Failure Rate through 42 Days postpartum"
            acute_renal3_post = "Refined Acute Renal Failure Rate through 42 Days postpartum"
            resp_distress_post= "Adult Respiratory Distress Rate through 42 Days postpartum"
            am_fluid_post     = "Amniotic Fluid Embolism Rate through 42 Days postpartum"
            card_arr_post     = "Cardiac Arrest/Ventricular Fibrillation Rate through 42 Days postpartum"
            conv_card_post    = "Conversion of Cardiac Rhythm Rate through 42 Days postpartum"
            diss_intra_post   = "Disseminated Intravascular Coagulation Rate through 42 Days postpartum"
            diss_intra3_post  = "Refined Disseminated Intravascular Coagulation Rate through 42 Days postpartum"
            eclampsia_post    = "Eclampsia Rate through 42 Days postpartum"
            heart_fail_post   = "Heart Failure/Arrest during or following Surgery or Procedure Rate through 42 Days postpartum"
            puerp_post        = "Puerperal Cerebrovascular Disorder Rate through 42 Days postpartum"
            pulm_ed_post      = "Pulmonary Edema/Acute Heart Failure Rate through 42 Days postpartum"
            anes_comp_post    = "Severe Anesthesia Complications Rate through 42 Days postpartum"
            sepsis_post       = "Sepsis Rate through 42 Days postpartum"
            shock_post        = "Shock Rate through 42 Days postpartum"
            sickle_post       = "Sickle Cell Disease with Crisis Rate through 42 Days postpartum"
            air_thromb_post   = "Air and Thrombotic Embolism Rate through 42 Days postpartum"
            hyster_post       = "Hysterectomy Rate through 42 Days postpartum"
            tracheo_post      = "Temporary Tracheostomy Rate through 42 Days postpartum"
            vent_post         = "Respiratory Ventilation Rate through 42 Days postpartum" 
            deceased_flag_post= "In-Hospital Mortality Rate through 42 Days postpartum"
            TAMH05            = "Inpatient Severe Maternal Morbidity Rate, Delivery through 42 Days Postpartum, Beta (20 indicators)"
            TAMH06            = "Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, Delivery through 42 Days Postpartum, Beta (20 indicators plus in-hospital mortality)"
            TAMH07            = "Refined Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, Delivery through 42 Days Postpartum, Beta (20 indicators plus in-hospital mortality)";
   run;

%end;

%else %if &ref_pop. = 3 %then %do; 

   %let keepvars = YEAR DQTR INPATIENT PAYCAT RACECAT POVCAT &CUSTOM_STRATUM.
                   BHSUD_POST SSH_POST SUD_POST OD_POST SUD_OD_POST PMAD_POST TAMH08 TAMH09 TAMH10A TAMH10B TAMH10 TAMH11;

   *Roll up the overall measures (MHI 08 - MHI 11) 42 days postpartum by HOSPST, visitlink, index_daystoevent and index_delivery_date;
   *Take the maximum of the variables across the discharges;
   proc sql;
      create table index_delivery_rolledup as
      select  hospst
             ,visitlink
             ,index_daystoevent
             ,index_delivery_date
             %do i= 1 %to %sysfunc(countw(&keepvars.));
             ,max(%scan(&keepvars.,&i.)) as %scan(&keepvars.,&i.)
             %end;
      from temp(where=(not missing(index_delivery_date))) 
      group by hospst, visitlink, index_daystoevent, index_delivery_date;
   quit;

   title2 "Check the variables after rollup";
   proc freq data=index_delivery_rolledup;
       tables  &keepvars. 
               BHSUD_POST*TAMH08 SSH_POST*TAMH09 SUD_POST*TAMH10A OD_POST*TAMH10B SUD_OD_POST*TAMH10 PMAD_POST*TAMH11
               TAMH08*TAMH09*TAMH10A*TAMH10B*TAMH10*TAMH11 /missing list;
   run;

   data OUTMSR.&OUTFILE_MEAS.;
      retain HOSPST VISITLINK INDEX_DAYSTOEVENT INDEX_DELIVERY_DATE &keepvars.;
      set index_delivery_rolledup;

      *label the numerator indicators and flags;
      label TAMH08  = "Emergency Department and Inpatient Mental Health and Substance Use Disorders Rate, Days 1 to 42 Postpartum, Beta"
            TAMH09  = "Emergency Department and Inpatient Encounters for Intentional Self-Harm Rate, Days 1 to 42 Postpartum, Beta"
            TAMH10A = "Emergency Department and Inpatient Substance Use Disorders Rate, Days 1 to 42 Postpartum, Beta"
            TAMH10B = "Emergency Department and Inpatient Accidental Overdose Rate, Days 1 to 42 Postpartum, Beta"
            TAMH10  = "Emergency Department and Inpatient Substance Use Disorders and Accidental Overdose Rate, Days 1 to 42 Postpartum, Beta"
            TAMH11  = "Emergency Department and Inpatient Perinatal Mood and Anxiety Disorders Rate, Days 1 to 42 Postpartum, Beta"; 

   run;

%end;

%mend DoRollup;
%DoRollup;

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