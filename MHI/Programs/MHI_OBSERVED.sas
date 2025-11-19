*===================== Program: MHI_OBSERVED.SAS ==================================;
*
*  TITLE: OBSERVED RATES FOR AHRQ MATERNAL HEALTH INDICATORS
*
*  DESCRIPTION:
*         Calculates observed rates for Maternal Health Indicators
*         using output from MHI_MEASURES.SAS.
*         Output stratified by RACECAT, POVCAT, STATE, YEAR, PAYER 
          and user-define stratum.
*         Variables created by this program are PAMHXX and OAMHXX
*
*  VERSION: SAS Beta version of MHI v2025
*  RELEASE DATE: AUGUST 2024
*
*===================================================================================;

 title2 'PROGRAM: MHI_OBSERVED';
 title3 'AHRQ MATERNAL HEALTH INDICATORS: CALCULATE OBSERVED RATES';

* ------------------------------------------------------------------ ;
* --- MEANS ON MHI_MEASURES OUTPUT DATA FILE                     --- ;
* --- THE TAMHxx VARIABLE IS CREATED IN THE MEAUSURES PROGRAM    --- ;
* --- AND USED TO CALCULATE THE PAMHxx AND OAMHxx VARIABLES.     --- ;
* ------------------------------------------------------------------ ;

* ------------------------------------------------------------------ ;
* --- MATERNAL HEALTH INDICATORS (MHI) NAMING CONVENTION:        --- ;
* --- THE FIRST LETTER IDENTIFIES THE MATERNAL HEALTH INDICATORS --- ;
* --- AS ONE OF THE FOLLOWING:                                   --- ;
* ---           (T) NUMERATOR ("TOP") - FROM MHI_MEASURES        --- ;
* ---           (P) DENOMINATOR ("POPULATION")                   --- ;
* ---           (O) OBSERVED RATES (T/P)                         --- ;
* --- THE SECOND LETTER IDENTIFIES THE MHI AS AN AREA (A)        --- ;
* --- LEVEL INDICATOR. THE NEXT TWO CHARACTERS ARE ALWAYS        --- ;
* --- 'MH'. THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.        --- ;
* ------------------------------------------------------------------ ;

*Do not modify the macro variable VARS below, such as, adding a space or changing the order of the variables;
%LET VARS =
MYOCARD ANEURYSM ACUTE_RENAL ACUTE_RENAL3 RESP_DISTRESS AM_FLUID CARD_ARR CONV_CARD DISS_INTRA DISS_INTRA3
ECLAMPSIA HEART_FAIL PUERP PULM_ED ANES_COMP SEPSIS SHOCK SICKLE AIR_THROMB HYSTER
TRACHEO VENT DECEASED_FLAG;

%LET VARS_POST = %sysfunc(tranwrd(&vars.,%str( ),%str(_POST )))_POST;
%LET T_VARS    = T_%sysfunc(tranwrd(&vars.,%str( ),%str( T_)));
%LET P_VARS    = P_%sysfunc(tranwrd(&vars.,%str( ),%str( P_)));
%LET O_VARS    = O_%sysfunc(tranwrd(&vars.,%str( ),%str( O_)));

%LET T_VARS_POST = T_%sysfunc(tranwrd(&vars_post.,%str( ),%str( T_)));
%LET P_VARS_POST = P_%sysfunc(tranwrd(&vars_post.,%str( ),%str( P_)));
%LET O_VARS_POST = O_%sysfunc(tranwrd(&vars_post.,%str( ),%str( O_)));

%put vars = &vars.;
%put vars_post = &vars_post.; 
%put T_vars = &T_vars.; 
%put P_vars = &P_vars.; 
%put O_vars = &O_vars.; 
%put T_vars_post = &T_vars_post.; 
%put P_vars_post = &P_vars_post.; 
%put O_vars_post = &O_vars_post.;


%macro CreateObs;
 proc Summary data=OUTMSR.&OUTFILE_MEAS.;
  class &CUSTOM_STRATUM. PAYCAT YEAR HOSPST POVCAT RACECAT; ways 0 1;
  %if &ref_pop. = 1 %then %do;
  var  TAMH01 TAMH02 TAMH03 TAMH04;
  output out=&OUTFILE_AREAOBS.
        sum(TAMH01 TAMH02 TAMH03 TAMH04  &VARS.) = TAMH01 TAMH02 TAMH03 TAMH04 &T_VARS.
        n  (TAMH01 TAMH02 TAMH03 TAMH04  &VARS.) = PAMH01 PAMH02 PAMH03 PAMH04 &P_VARS.
        mean(TAMH01 TAMH02 TAMH03 TAMH04 &VARS.) = OAMH01 OAMH02 OAMH03 OAMH04 &O_VARS.;
  %end;
  %else %if &ref_pop. = 2 %then %do;
  var  TAMH05 TAMH06 TAMH07;
  output out=&OUTFILE_AREAOBS.
        sum(TAMH05 TAMH06 TAMH07  &VARS_POST.) = TAMH05 TAMH06 TAMH07 &T_VARS_POST.
        n  (TAMH05 TAMH06 TAMH07  &VARS_POST.) = PAMH05 PAMH06 PAMH07 &P_VARS_POST.
        mean(TAMH05 TAMH06 TAMH07 &VARS_POST.) = OAMH05 OAMH06 OAMH07 &O_VARS_POST.;
  %end;
  %else %if &ref_pop. = 3 %then %do;
  var  TAMH08 TAMH09 TAMH10A TAMH10B TAMH10 TAMH11;
  output out=&OUTFILE_AREAOBS.
        sum(TAMH08 TAMH09 TAMH10A TAMH10B TAMH10 TAMH11) = TAMH08 TAMH09 TAMH10A TAMH10B TAMH10 TAMH11
        n  (TAMH08 TAMH09 TAMH10A TAMH10B TAMH10 TAMH11) = PAMH08 PAMH09 PAMH10A PAMH10B PAMH10 PAMH11
        mean(TAMH08 TAMH09 TAMH10A TAMH10B TAMH10 TAMH11)= OAMH08 OAMH09 OAMH10A OAMH10B OAMH10 OAMH11;
  %end;
 run;
 
 proc Sort data=&OUTFILE_AREAOBS.;
  by &CUSTOM_STRATUM. PAYCAT YEAR HOSPST POVCAT RACECAT;
 run;
 

 data OUTAOBS.&OUTFILE_AREAOBS.;
   set &OUTFILE_AREAOBS.;

     %if &ref_pop. = 1 %then %do;
     array PAMH PAMH01 PAMH02 PAMH03 PAMH04 &P_VARS.;
     array OAMH OAMH01 OAMH02 OAMH03 OAMH04 &O_VARS.;
     %end;
     %else %if &ref_pop. = 2 %then %do;
     array PAMH PAMH05 PAMH06 PAMH07 &P_VARS_POST.;
     array OAMH OAMH05 OAMH06 OAMH07 &O_VARS_POST.;
     %end;
     %else %if &ref_pop. = 3 %then %do;
     array PAMH PAMH08 PAMH09 PAMH10A PAMH10B PAMH10 PAMH11;
     array OAMH OAMH08 OAMH09 OAMH10A OAMH10B OAMH10 OAMH11;
     %end;

     do over PAMH;
        if PAMH eq 0 then PAMH = .;
     end;

     do over OAMH;
        OAMH = OAMH*10000;
     end;


     %macro label_qis(qi_num=, qi_name=);
       label
       TA&qi_num. = "&qi_name. (Numerator)"
       PA&qi_num. = "&qi_name. (Population)"
       OA&qi_num. = "&qi_name. (Observed rate)"
       ;
     %mend label_qis;

     %macro label_flags(qi_num=, qi_name=);
       label
       T_&qi_num. = "&qi_name. (Numerator)"
       P_&qi_num. = "&qi_name. (Population)"
       O_&qi_num. = "&qi_name. (Observed rate)"
       ;
     %mend label_flags;

    %if &ref_pop. = 1 %then %do;
    %label_qis(qi_num=MH01         ,qi_name=%quote(Inpatient Severe Maternal Morbidity Rate, at Delivery (20 indicators)));
    %label_qis(qi_num=MH02         ,qi_name=%quote(Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, at Delivery (20 indicators plus in-hospital mortality)));
    %label_qis(qi_num=MH03         ,qi_name=%quote(Refined Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, at Delivery, Beta (20 indicators plus in-hospital mortality)));
    %label_qis(qi_num=MH04         ,qi_name=%quote(Inpatient Mental Health and Substance Use Disorders Rate, at Delivery, Beta));
    %label_flags(qi_num=myocard      ,qi_name=%quote(Acute Myocardial Infarction Rate, at Delivery));
    %label_flags(qi_num=aneurysm     ,qi_name=%quote(Aneurysm Rate, at Delivery));
    %label_flags(qi_num=acute_renal  ,qi_name=%quote(Acute Renal Failure Rate, at Delivery));
    %label_flags(qi_num=acute_renal3 ,qi_name=%quote(Refined Acute Renal Failure Rate, at Delivery));
    %label_flags(qi_num=resp_distress,qi_name=%quote(Adult Respiratory Distress Rate, at Delivery));
    %label_flags(qi_num=am_fluid     ,qi_name=%quote(Amniotic Fluid Embolism Rate, at Delivery));
    %label_flags(qi_num=card_arr     ,qi_name=%quote(Cardiac Arrest/Ventricular Fibrillation Rate, at Delivery));
    %label_flags(qi_num=conv_card    ,qi_name=%quote(Conversion of Cardiac Rhythm Rate, at Delivery));
    %label_flags(qi_num=diss_intra   ,qi_name=%quote(Disseminated Intravascular Coagulation Rate, at Delivery));
    %label_flags(qi_num=diss_intra3  ,qi_name=%quote(Refined Disseminated Intravascular Coagulation Rate, at Delivery));
    %label_flags(qi_num=eclampsia    ,qi_name=%quote(Eclampsia Rate, at Delivery));
    %label_flags(qi_num=heart_fail   ,qi_name=%quote(Heart Failure/Arrest during or following Surgery or Procedure Rate, at Delivery));
    %label_flags(qi_num=puerp        ,qi_name=%quote(Puerperal Cerebrovascular Disorder Rate, at Delivery));
    %label_flags(qi_num=pulm_ed      ,qi_name=%quote(Pulmonary Edema/Acute Heart Failure Rate, at Delivery));
    %label_flags(qi_num=anes_comp    ,qi_name=%quote(Severe Anesthesia Complications Rate, at Delivery));
    %label_flags(qi_num=sepsis       ,qi_name=%quote(Sepsis Rate, at Delivery));
    %label_flags(qi_num=shock        ,qi_name=%quote(Shock Rate, at Delivery));
    %label_flags(qi_num=sickle       ,qi_name=%quote(Sickle Cell Disease with Crisis Rate, at Delivery));
    %label_flags(qi_num=air_thromb   ,qi_name=%quote(Air and Thrombotic Embolism Rate, at Delivery));
    %label_flags(qi_num=hyster       ,qi_name=%quote(Hysterectomy Rate, at Delivery));
    %label_flags(qi_num=tracheo      ,qi_name=%quote(Temporary Tracheostomy Rate, at Delivery));
    %label_flags(qi_num=vent         ,qi_name=%quote(Respiratory Ventilation Rate , at Delivery));
    %label_flags(qi_num=deceased_flag,qi_name=%quote(In-Hospital Mortality Rate, at Delivery));
    %end;
    %else %if &ref_pop. = 2 %then %do;
    %label_qis(qi_num=MH05              ,qi_name=%quote(Inpatient Severe Maternal Morbidity Rate, Delivery through 42 Days Postpartum, Beta (20 indicators)));
    %label_qis(qi_num=MH06              ,qi_name=%quote(Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, Delivery through 42 Days Postpartum, Beta (20 indicators plus in-hospital mortality)));
    %label_qis(qi_num=MH07              ,qi_name=%quote(Refined Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, Delivery through 42 Days Postpartum, Beta (20 indicators plus in-hospital mortality)));
    %label_flags(qi_num=myocard_post      ,qi_name=%quote(Acute Myocardial Infarction Rate through 42 Days postpartum));
    %label_flags(qi_num=aneurysm_post     ,qi_name=%quote(Aneurysm Rate through 42 Days postpartum));
    %label_flags(qi_num=acute_renal_post  ,qi_name=%quote(Acute Renal Failure Rate through 42 Days postpartum));                                                       
    %label_flags(qi_num=acute_renal3_post ,qi_name=%quote(Refined Acute Renal Failure Rate through 42 Days postpartum));                                                               
    %label_flags(qi_num=resp_distress_post,qi_name=%quote(Adult Respiratory Distress Rate through 42 Days postpartum));                                                  
    %label_flags(qi_num=am_fluid_post     ,qi_name=%quote(Amniotic Fluid Embolism Rate through 42 Days postpartum));                                                           
    %label_flags(qi_num=card_arr_post     ,qi_name=%quote(Cardiac Arrest/Ventricular Fibrillation Rate through 42 Days postpartum));                                                      
    %label_flags(qi_num=conv_card_post    ,qi_name=%quote(Conversion of Cardiac Rhythm Rate through 42 Days postpartum));                                                                
    %label_flags(qi_num=diss_intra_post   ,qi_name=%quote(Disseminated Intravascular Coagulation Rate through 42 Days postpartum));                                                     
    %label_flags(qi_num=diss_intra3_post  ,qi_name=%quote(Refined Disseminated Intravascular Coagulation Rate through 42 Days postpartum));                                                             
    %label_flags(qi_num=eclampsia_post    ,qi_name=%quote(Eclampsia Rate through 42 Days postpartum));                                             
    %label_flags(qi_num=heart_fail_post   ,qi_name=%quote(Heart Failure/Arrest during or following Surgery or Procedure Rate through 42 Days postpartum));                                                               
    %label_flags(qi_num=puerp_post        ,qi_name=%quote(Puerperal Cerebrovascular Disorder Rate through 42 Days postpartum));                                                 
    %label_flags(qi_num=pulm_ed_post      ,qi_name=%quote(Pulmonary Edema/Acute Heart Failure Rate through 42 Days postpartum));                                                  
    %label_flags(qi_num=anes_comp_post    ,qi_name=%quote(Severe Anesthesia Complications Rate through 42 Days postpartum));                                                                   
    %label_flags(qi_num=sepsis_post       ,qi_name=%quote(Sepsis Rate through 42 Days postpartum));                                          
    %label_flags(qi_num=shock_post        ,qi_name=%quote(Shock Rate through 42 Days postpartum));                                         
    %label_flags(qi_num=sickle_post       ,qi_name=%quote(Sickle Cell Disease with Crisis Rate through 42 Days postpartum));                                                                   
    %label_flags(qi_num=air_thromb_post   ,qi_name=%quote(Air and Thrombotic Embolism Rate through 42 Days postpartum));                                                               
    %label_flags(qi_num=hyster_post       ,qi_name=%quote(Hysterectomy Rate through 42 Days postpartum));                                                
    %label_flags(qi_num=tracheo_post      ,qi_name=%quote(Temporary Tracheostomy Rate through 42 Days postpartum));                                                          
    %label_flags(qi_num=vent_post         ,qi_name=%quote(Respiratory Ventilation Rate through 42 Days postpartum));                                                 
    %label_flags(qi_num=deceased_flag_post,qi_name=%quote(In-Hospital Mortality Rate through 42 Days postpartum));  
    %end;
    %else %if &ref_pop. = 3 %then %do;
    %label_qis(qi_num=MH08, qi_name=%quote(Emergency Department and Inpatient Mental Health and Substance Use Disorders Rate, Days 1 to 42 Postpartum, Beta));
    %label_qis(qi_num=MH09, qi_name=%quote(Emergency Department and Inpatient Encounters for Intentional Self-Harm Rate, Days 1 to 42 Postpartum, Beta));
    %label_qis(qi_num=MH10A,qi_name=%quote(Emergency Department and Inpatient Substance Use Disorders Rate, Days 1 to 42 Postpartum, Beta));
    %label_qis(qi_num=MH10B,qi_name=%quote(Emergency Department and Inpatient Accidental Overdose Rate, Days 1 to 42 Postpartum, Beta));
    %label_qis(qi_num=MH10, qi_name=%quote(Emergency Department and Inpatient Substance Use Disorders and Accidental Overdose Rate, Days 1 to 42 Postpartum, Beta));
    %label_qis(qi_num=MH11, qi_name=%quote(Emergency Department and Inpatient Perinatal Mood and Anxiety Disorders Rate, Days 1 to 42 Postpartum, Beta));
    %end;

    label _TYPE_ = "Stratification Level";

    drop _FREQ_ ;
run;
%mend CreateObs;
%CreateObs;

* -------------------------------------------------------------- ;
* --- CONTENTS AND MEANS OF OBSERVED OUTPUT FILE             --- ;
* -------------------------------------------------------------- ;
 proc Contents data=OUTAOBS.&OUTFILE_AREAOBS. position;
 run;

***--- TO PRINT VARIABLE LABELS REMOVE "NOLABELS" FROM PROC MEANS STATEMENTS ---***;
%macro means_stratum(stratum_cond, stratum_name);
proc Means data=OUTAOBS.&OUTFILE_AREAOBS.(WHERE=(&stratum_cond.)) n nmiss min max sum nolabels;
   %if &ref_pop. = 1 %then %do;
   var TAMH01-TAMH04 &T_VARS. PAMH01-PAMH04 &P_VARS. OAMH01-OAMH04 &O_VARS.;
   %end;
   %else %if &ref_pop. = 2 %then %do;
   var TAMH05-TAMH07 &T_VARS_POST. PAMH05-PAMH07 &P_VARS_POST. OAMH05-OAMH07 &O_VARS_POST.;
   %end;
   %else %if &ref_pop. = 3 %then %do;
   var TAMH08-TAMH11 TAMH10A TAMH10B PAMH08-PAMH11 PAMH10A PAMH10B OAMH08-OAMH11 OAMH10A OAMH10B;
   %end;
   title  "SUMMARY OF MATERNAL HEALTH INDICATORS NUMERATOR, DENOMINATOR, OBESERVED RATES By &stratum_name.";
run; quit;
%mend means_stratum;

%means_stratum(%str(_TYPE_=0),             Overall);
%means_stratum(%str(not missing(RACECAT)), Race);
%means_stratum(%str(not missing(POVCAT)),  Poverty);
%means_stratum(%str(not missing(HOSPST)),  State);
%means_stratum(%str(not missing(YEAR)),    Year);
%means_stratum(%str(not missing(PAYCAT)),  Payer);

%macro do_means_custom;
%if &CUSTOM_STRATUM. ^=  %then %do;
%means_stratum(%str(not missing(&CUSTOM_STRATUM.)), &CUSTOM_STRATUM.);
%end;
%mend do_means_custom;

%do_means_custom;

* -------------------------------------------------------- ;
* --- PRINT OBSERVED MEANS FILE TO SAS OUTPUT          --- ;
* -------------------------------------------------------- ;
 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(FLAGS, MH,TEXT);

 proc PRINT data=OUTAOBS.&OUTFILE_AREAOBS. LABEL SPLIT='*';

 %IF &FLAGS. = 0 %THEN %DO;  
 var   RACECAT POVCAT HOSPST YEAR PAYCAT &CUSTOM_STRATUM. TAMH&MH. PAMH&MH. OAMH&MH. ;
 label RACECAT = "Race Categories"
        POVCAT  = "FIPS Poverty Categories"
        HOSPST  = "Hospital State Postal Code"
        YEAR    = "Calendar Year"
        PAYCAT  = "Patient Primary Payer"
        TAMH&MH.= "TAMH&MH.*(Numerator)"
        PAMH&MH.= "PAMH&MH.*(Population)"
        OAMH&MH.= "OAMH&MH.*(Observed rate)"
       ;
 format RACECAT RACECAT.
        PAYCAT PAYCAT. 
        POVCAT POVCATLBL.
		TAMH&MH. PAMH&MH. 13.0 OAMH&MH. 8.6
   ;
 title4 "Indicator &MH.: &TEXT";
 %END;
 %ELSE %IF &FLAGS. = 1 %THEN %DO;
 var   RACECAT POVCAT HOSPST YEAR PAYCAT &CUSTOM_STRATUM. T_&MH. P_&MH. O_&MH. ;
 label RACECAT = "Race Categories"
        POVCAT  = "FIPS Poverty Categories"
        HOSPST  = "Hospital State Postal Code"
        YEAR    = "Calendar Year"
        PAYCAT  = "Patient Primary Payer"
        T_&MH.= "T_&MH.*(Numerator)"
        P_&MH.= "P_&MH.*(Population)"
        O_&MH.= "O_&MH.*(Observed rate)"
       ;
 format RACECAT RACECAT.
        PAYCAT PAYCAT. 
        POVCAT POVCATLBL.
		T_&MH. P_&MH. 13.0 O_&MH. 8.6;
   ;
 title4 "Indicator &MH.: &TEXT";
 %END;
 run;

 %MEND PRT;

 %if &ref_pop. = 1 %then %do;
 %PRT(0, 01, %BQUOTE(Inpatient Severe Maternal Morbidity Rate, at Delivery (20 indicators)));
 %PRT(0, 02, %BQUOTE(Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, at Delivery (20 indicators plus in-hospital mortality)));
 %PRT(0, 03, %BQUOTE(Refined Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, at Delivery, Beta (20 indicators plus in-hospital mortality)));
 %PRT(0, 04, %BQUOTE(Inpatient Mental Health and Substance Use Disorders Rate, at Delivery, Beta));
 %PRT(1, myocard      ,%BQUOTE(Acute Myocardial Infarction Rate, at Delivery));
 %PRT(1, aneurysm     ,%BQUOTE(Aneurysm Rate, at Delivery));
 %PRT(1, acute_renal  ,%BQUOTE(Acute Renal Failure Rate, at Delivery));
 %PRT(1, acute_renal3 ,%BQUOTE(Refined Acute Renal Failure Rate, at Delivery));
 %PRT(1, resp_distress,%BQUOTE(Adult Respiratory Distress Rate, at Delivery));
 %PRT(1, am_fluid     ,%BQUOTE(Amniotic Fluid Embolism Rate, at Delivery));
 %PRT(1, card_arr     ,%BQUOTE(Cardiac Arrest/Ventricular Fibrillation Rate, at Delivery));
 %PRT(1, conv_card    ,%BQUOTE(Conversion of Cardiac Rhythm Rate, at Delivery));
 %PRT(1, diss_intra   ,%BQUOTE(Disseminated Intravascular Coagulation Rate, at Delivery));
 %PRT(1, diss_intra3  ,%BQUOTE(Refined Disseminated Intravascular Coagulation Rate, at Delivery));
 %PRT(1, eclampsia    ,%BQUOTE(Eclampsia Rate, at Delivery));
 %PRT(1, heart_fail   ,%BQUOTE(Heart Failure/Arrest during or following Surgery or Procedure Rate, at Delivery));
 %PRT(1, puerp        ,%BQUOTE(Puerperal Cerebrovascular Disorder Rate, at Delivery));
 %PRT(1, pulm_ed      ,%BQUOTE(Pulmonary Edema/Acute Heart Failure Rate, at Delivery));
 %PRT(1, anes_comp    ,%BQUOTE(Severe Anesthesia Complications Rate, at Delivery));
 %PRT(1, sepsis       ,%BQUOTE(Sepsis Rate, at Delivery));
 %PRT(1, shock        ,%BQUOTE(Shock Rate, at Delivery));
 %PRT(1, sickle       ,%BQUOTE(Sickle Cell Disease with Crisis Rate, at Delivery));
 %PRT(1, air_thromb   ,%BQUOTE(Air and Thrombotic Embolism Rate, at Delivery));
 %PRT(1, hyster       ,%BQUOTE(Hysterectomy Rate, at Delivery));
 %PRT(1, tracheo      ,%BQUOTE(Temporary Tracheostomy Rate, at Delivery));
 %PRT(1, vent         ,%BQUOTE(Respiratory Ventilation Rate , at Delivery));
 %PRT(1, deceased_flag,%BQUOTE(In-Hospital Mortality Rate, at Delivery));
 %end;
 %else %if &ref_pop. = 2 %then %do;
 %PRT(0, 05, %BQUOTE(Inpatient Severe Maternal Morbidity Rate, Delivery through 42 Days Postpartum, Beta (20 indicators)));
 %PRT(0, 06, %BQUOTE(Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, Delivery through 42 Days Postpartum, Beta (20 indicators plus in-hospital mortality)));
 %PRT(0, 07, %BQUOTE(Refined Inpatient Severe Maternal Morbidity Plus In-Hospital Mortality Rate, Delivery through 42 Days Postpartum, Beta (20 indicators plus in-hospital mortality)));
 %PRT(1, myocard_post      ,%BQUOTE(Acute Myocardial Infarction Rate through 42 Days postpartum));
 %PRT(1, aneurysm_post     ,%BQUOTE(Aneurysm Rate through 42 Days postpartum));
 %PRT(1, acute_renal_post  ,%BQUOTE(Acute Renal Failure Rate through 42 Days postpartum));                                 
 %PRT(1, acute_renal3_post ,%BQUOTE(Refined Acute Renal Failure Rate through 42 Days postpartum));                         
 %PRT(1, resp_distress_post,%BQUOTE(Adult Respiratory Distress Rate through 42 Days postpartum));                 
 %PRT(1, am_fluid_post     ,%BQUOTE(Amniotic Fluid Embolism Rate through 42 Days postpartum));                             
 %PRT(1, card_arr_post     ,%BQUOTE(Cardiac Arrest/Ventricular Fibrillation Rate through 42 Days postpartum));             
 %PRT(1, conv_card_post    ,%BQUOTE(Conversion of Cardiac Rhythm Rate through 42 Days postpartum));                        
 %PRT(1, diss_intra_post   ,%BQUOTE(Disseminated Intravascular Coagulation Rate through 42 Days postpartum));              
 %PRT(1, diss_intra3_post  ,%BQUOTE(Refined Disseminated Intravascular Coagulation Rate through 42 Days postpartum));      
 %PRT(1, eclampsia_post    ,%BQUOTE(Eclampsia Rate through 42 Days postpartum));                                           
 %PRT(1, heart_fail_post   ,%BQUOTE(Heart Failure/Arrest during or following Surgery or Procedure Rate through 42 Days postpartum));    
 %PRT(1, puerp_post        ,%BQUOTE(Puerperal Cerebrovascular Disorder Rate through 42 Days postpartum));                  
 %PRT(1, pulm_ed_post      ,%BQUOTE(Pulmonary Edema/Acute Heart Failure Rate through 42 Days postpartum));                 
 %PRT(1, anes_comp_post    ,%BQUOTE(Severe Anesthesia Complications Rate through 42 Days postpartum));                     
 %PRT(1, sepsis_post       ,%BQUOTE(Sepsis Rate through 42 Days postpartum));                                          
 %PRT(1, shock_post        ,%BQUOTE(Shock Rate through 42 Days postpartum));                                         
 %PRT(1, sickle_post       ,%BQUOTE(Sickle Cell Disease with Crisis Rate through 42 Days postpartum));                     
 %PRT(1, air_thromb_post   ,%BQUOTE(Air and Thrombotic Embolism Rate through 42 Days postpartum));                         
 %PRT(1, hyster_post       ,%BQUOTE(Hysterectomy Rate through 42 Days postpartum));                                        
 %PRT(1, tracheo_post      ,%BQUOTE(Temporary Tracheostomy Rate through 42 Days postpartum));                              
 %PRT(1, vent_post         ,%BQUOTE(Respiratory Ventilation Rate through 42 Days postpartum));                                         
 %PRT(1, deceased_flag_post,%BQUOTE(In-Hospital Mortality Rate through 42 Days postpartum));  
 %end;
 %else %if &ref_pop. = 3 %then %do;
 %PRT(0, 08,  %BQUOTE(Emergency Department and Inpatient Mental Health and Substance Use Disorders Rate, Days 1 to 42 Postpartum, Beta));
 %PRT(0, 09,  %BQUOTE(Emergency Department and Inpatient Encounters for Intentional Self-Harm Rate, Days 1 to 42 Postpartum, Beta));
 %PRT(0, 10A, %BQUOTE(Emergency Department and Inpatient Substance Use Disorders Rate, Days 1 to 42 Postpartum, Beta));
 %PRT(0, 10B, %BQUOTE(Emergency Department and Inpatient Accidental Overdose Rate, Days 1 to 42 Postpartum, Beta));
 %PRT(0, 10,  %BQUOTE(Emergency Department and Inpatient Substance Use Disorders and Accidental Overdose Rate, Days 1 to 42 Postpartum, Beta));
 %PRT(0, 11,  %BQUOTE(Emergency Department and Inpatient Perinatal Mood and Anxiety Disorders Rate, Days 1 to 42 Postpartum, Beta));
 %end;

 %END;

 %MEND PRT2;

 %PRT2;
 
 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS                           --- ;
 * -------------------------------------------------------------- ;

 %macro do_txt_custom;
 %if &CUSTOM_STRATUM. ^=  %then %do;

 PROC CONTENTS DATA=OUTAOBS.&OUTFILE_AREAOBS.(KEEP=&CUSTOM_STRATUM.) OUT=CONT(KEEP=NAME TYPE LENGTH) NOPRINT; 
 RUN; 
 DATA _NULL_;
    SET CONT;
    CALL SYMPUT("TYP",TYPE);
    CALL SYMPUT("LEN",LENGTH);
 RUN;

 %GLOBAL TYPLEN;
 %IF &TYP.=1 %THEN %DO;
    PROC SQL NOPRINT;
    SELECT LENGTH(STRIP(PUT(MAX(&CUSTOM_STRATUM.),BEST.))) INTO: TYPLEN
    FROM OUTAOBS.&OUTFILE_AREAOBS.;
    QUIT;
 %END;
 %ELSE %IF &TYP.=2 %THEN %DO;
    %LET TYPLEN = %SYSFUNC(COMPRESS($&LEN.));
 %END;
 %PUT TYPLEN=&TYPLEN.;

 %end;
 %mend do_txt_custom;
 %do_txt_custom;


 %MACRO TEXTP1;
 %if &TXTAOBS. = 1 and &CUSTOM_STRATUM. ^=  %then %do;

 data _NULL_;
 set OUTAOBS.&OUTFILE_AREAOBS.;
 file MHTXTAOB lrecl=2000 ;
 if _N_=1 then do;
 put "AHRQ SAS QI v2025 &OUTFILE_AREAOBS data set created with the following CONTROL options:";
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "Race" "," "Poverty"  "," "State"  "," "Year" "," "Payer"  "," "&CUSTOM_STRATUM." ","
     %if &ref_pop. = 1 %then %do;
     "TAMH01"      "," "TAMH02"       "," "TAMH03"          "," "TAMH04"         ","
     "T_MYOCARD"   "," "T_ANEURYSM"   "," "T_ACUTE_RENAL"   "," "T_ACUTE_RENAL3" "," "T_RESP_DISTRESS" "," 
     "T_AM_FLUID"  "," "T_CARD_ARR"   "," "T_CONV_CARD"     "," "T_DISS_INTRA"   "," "T_DISS_INTRA3"   ","  
     "T_ECLAMPSIA" "," "T_HEART_FAIL" "," "T_PUERP"         "," "T_PULM_ED"      "," "T_ANES_COMP"     "," 
     "T_SEPSIS"    "," "T_SHOCK"      "," "T_SICKLE"        "," "T_AIR_THROMB"   "," "T_HYSTER"        "," 
     "T_TRACHEO"   "," "T_VENT"       "," "T_DECEASED_FLAG" "," 
     "PAMH01"      "," "PAMH02"       "," "PAMH03"          "," "PAMH04"         ","  
     "P_MYOCARD"   "," "P_ANEURYSM"   "," "P_ACUTE_RENAL"   "," "P_ACUTE_RENAL3" "," "P_RESP_DISTRESS" "," 
     "P_AM_FLUID"  "," "P_CARD_ARR"   "," "P_CONV_CARD"     "," "P_DISS_INTRA"   "," "P_DISS_INTRA3"   "," 
     "P_ECLAMPSIA" "," "P_HEART_FAIL" "," "P_PUERP"         "," "P_PULM_ED"      "," "P_ANES_COMP"     ","
     "P_SEPSIS"    "," "P_SHOCK"      "," "P_SICKLE"        "," "P_AIR_THROMB"   "," "P_HYSTER"        "," 
     "P_TRACHEO"   "," "P_VENT"       "," "P_DECEASED_FLAG" ","
     "OAMH01"      "," "OAMH02"       "," "OAMH03"          "," "OAMH04"         ","
     "O_MYOCARD"   "," "O_ANEURYSM"   "," "O_ACUTE_RENAL"   "," "O_ACUTE_RENAL3" "," "O_RESP_DISTRESS" "," 
     "O_AM_FLUID"  "," "O_CARD_ARR"   "," "O_CONV_CARD"     "," "O_DISS_INTRA"   "," "O_DISS_INTRA3"   ","  
     "O_ECLAMPSIA" "," "O_HEART_FAIL" "," "O_PUERP"         "," "O_PULM_ED"      "," "O_ANES_COMP"     "," 
     "O_SEPSIS"    "," "O_SHOCK"      "," "O_SICKLE"        "," "O_AIR_THROMB"   "," "O_HYSTER"        "," 
     "O_TRACHEO"   "," "O_VENT"       "," "O_DECEASED_FLAG"
     %end;
     %else %if &ref_pop. = 2 %then %do;
     "TAMH05"           "," "TAMH06"            "," "TAMH07"               ","
     "T_MYOCARD_POST"   "," "T_ANEURYSM_POST"   "," "T_ACUTE_RENAL_POST"   "," "T_ACUTE_RENAL3_POST" "," "T_RESP_DISTRESS_POST" "," 
     "T_AM_FLUID_POST"  "," "T_CARD_ARR_POST"   "," "T_CONV_CARD_POST"     "," "T_DISS_INTRA_POST"   "," "T_DISS_INTRA3_POST"   "," 
     "T_ECLAMPSIA_POST" "," "T_HEART_FAIL_POST" "," "T_PUERP_POST"         "," "T_PULM_ED_POST"      "," "T_ANES_COMP_POST"     "," 
     "T_SEPSIS_POST"    "," "T_SHOCK_POST"      "," "T_SICKLE_POST"        "," "T_AIR_THROMB_POST"   "," "T_HYSTER_POST"        "," 
     "T_TRACHEO_POST"   "," "T_VENT_POST"       "," "T_DECEASED_FLAG_POST" ","
     "PAMH05"           "," "PAMH06"            "," "PAMH07"               ","   
     "P_MYOCARD_POST"   "," "P_ANEURYSM_POST"   "," "P_ACUTE_RENAL_POST"   "," "P_ACUTE_RENAL3_POST" "," "P_RESP_DISTRESS_POST" ","
     "P_AM_FLUID_POST"  "," "P_CARD_ARR_POST"   "," "P_CONV_CARD_POST"     "," "P_DISS_INTRA_POST"   "," "P_DISS_INTRA3_POST"   "," 
     "P_ECLAMPSIA_POST" "," "P_HEART_FAIL_POST" "," "P_PUERP_POST"         "," "P_PULM_ED_POST"      "," "P_ANES_COMP_POST"     "," 
     "P_SEPSIS_POST"    "," "P_SHOCK_POST"      "," "P_SICKLE_POST"        "," "P_AIR_THROMB_POST"   "," "P_HYSTER_POST"        "," 
     "P_TRACHEO_POST"   "," "P_VENT_POST"       "," "P_DECEASED_FLAG_POST" ","
     "OAMH05"           "," "OAMH06"            "," "OAMH07"               ","
     "O_MYOCARD_POST"   "," "O_ANEURYSM_POST"   "," "O_ACUTE_RENAL_POST"   "," "O_ACUTE_RENAL3_POST" "," "O_RESP_DISTRESS_POST" "," 
     "O_AM_FLUID_POST"  "," "O_CARD_ARR_POST"   "," "O_CONV_CARD_POST"     "," "O_DISS_INTRA_POST"   "," "O_DISS_INTRA3_POST"   "," 
     "O_ECLAMPSIA_POST" "," "O_HEART_FAIL_POST" "," "O_PUERP_POST"         "," "O_PULM_ED_POST"      "," "O_ANES_COMP_POST"     "," 
     "O_SEPSIS_POST"    "," "O_SHOCK_POST"      "," "O_SICKLE_POST"        "," "O_AIR_THROMB_POST"   "," "O_HYSTER_POST"        ","
     "O_TRACHEO_POST"   "," "O_VENT_POST"       "," "O_DECEASED_FLAG_POST"
     %end;
     %else %if &ref_pop. = 3 %then %do;
     "TAMH08" "," "TAMH09" "," "TAMH10A" "," "TAMH10B" "," "TAMH10" "," "TAMH11" ","
     "PAMH08" "," "PAMH09" "," "PAMH10A" "," "PAMH10B" "," "PAMH10" "," "PAMH11" "," 
     "OAMH08" "," "OAMH09" "," "OAMH10A" "," "OAMH10B" "," "OAMH10" "," "OAMH11"
     %end;
 ;
 end;

 put RACECAT 3. "," POVCAT 3.  "," HOSPST $2. "," YEAR 4. "," PAYCAT 3. "," &CUSTOM_STRATUM. &TYPLEN.. ","
 %if &ref_pop. = 1 %then %do;
 (TAMH01-TAMH04 &T_VARS.) (7.0 ",")
 ","
 (PAMH01-PAMH04 &P_VARS.) (13.0 ",")
 ","
 (OAMH01-OAMH04 &O_VARS.) (16.10 ",")
 %end;
 %else %if &ref_pop. = 2 %then %do;
 (TAMH05-TAMH07 &T_VARS_POST.) (7.0 ",")
 ","
 (PAMH05-PAMH07 &P_VARS_POST.) (13.0 ",")
 ","
 (OAMH05-OAMH07 &O_VARS_POST.) (16.10 ",")
 %end;
 %else %if &ref_pop. = 3 %then %do;
 (TAMH08 TAMH09 TAMH10A TAMH10B TAMH10 TAMH11) (7.0 ",")
 ","
 (PAMH08 PAMH09 PAMH10A PAMH10B PAMH10 PAMH11) (13.0 ",")
 ","
 (OAMH08 OAMH09 OAMH10A OAMH10B OAMH10 OAMH11) (16.10 ",")
 %end;
 ;
 run;

 %END;

 %else %if &TXTAOBS. = 1 and &CUSTOM_STRATUM. =  %then %do;

 data _NULL_;
 set OUTAOBS.&OUTFILE_AREAOBS.;
 file MHTXTAOB lrecl=2000 ;
 if _N_=1 then do;
 put "AHRQ SAS QI v2025 &OUTFILE_AREAOBS data set created with the following CONTROL options:";
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "Race" "," "Poverty"  "," "State"  "," "Year" "," "Payer"  "," 
     %if &ref_pop. = 1 %then %do;
     "TAMH01"      "," "TAMH02"       "," "TAMH03"          "," "TAMH04"         ","
     "T_MYOCARD"   "," "T_ANEURYSM"   "," "T_ACUTE_RENAL"   "," "T_ACUTE_RENAL3" "," "T_RESP_DISTRESS" "," 
     "T_AM_FLUID"  "," "T_CARD_ARR"   "," "T_CONV_CARD"     "," "T_DISS_INTRA"   "," "T_DISS_INTRA3"   ","  
     "T_ECLAMPSIA" "," "T_HEART_FAIL" "," "T_PUERP"         "," "T_PULM_ED"      "," "T_ANES_COMP"     "," 
     "T_SEPSIS"    "," "T_SHOCK"      "," "T_SICKLE"        "," "T_AIR_THROMB"   "," "T_HYSTER"        "," 
     "T_TRACHEO"   "," "T_VENT"       "," "T_DECEASED_FLAG" "," 
     "PAMH01"      "," "PAMH02"       "," "PAMH03"          "," "PAMH04"         ","  
     "P_MYOCARD"   "," "P_ANEURYSM"   "," "P_ACUTE_RENAL"   "," "P_ACUTE_RENAL3" "," "P_RESP_DISTRESS" "," 
     "P_AM_FLUID"  "," "P_CARD_ARR"   "," "P_CONV_CARD"     "," "P_DISS_INTRA"   "," "P_DISS_INTRA3"   "," 
     "P_ECLAMPSIA" "," "P_HEART_FAIL" "," "P_PUERP"         "," "P_PULM_ED"      "," "P_ANES_COMP"     ","
     "P_SEPSIS"    "," "P_SHOCK"      "," "P_SICKLE"        "," "P_AIR_THROMB"   "," "P_HYSTER"        "," 
     "P_TRACHEO"   "," "P_VENT"       "," "P_DECEASED_FLAG" ","
     "OAMH01"      "," "OAMH02"       "," "OAMH03"          "," "OAMH04"         ","
     "O_MYOCARD"   "," "O_ANEURYSM"   "," "O_ACUTE_RENAL"   "," "O_ACUTE_RENAL3" "," "O_RESP_DISTRESS" "," 
     "O_AM_FLUID"  "," "O_CARD_ARR"   "," "O_CONV_CARD"     "," "O_DISS_INTRA"   "," "O_DISS_INTRA3"   ","  
     "O_ECLAMPSIA" "," "O_HEART_FAIL" "," "O_PUERP"         "," "O_PULM_ED"      "," "O_ANES_COMP"     "," 
     "O_SEPSIS"    "," "O_SHOCK"      "," "O_SICKLE"        "," "O_AIR_THROMB"   "," "O_HYSTER"        "," 
     "O_TRACHEO"   "," "O_VENT"       "," "O_DECEASED_FLAG"
     %end;
     %else %if &ref_pop. = 2 %then %do;
     "TAMH05"           "," "TAMH06"            "," "TAMH07"               ","
     "T_MYOCARD_POST"   "," "T_ANEURYSM_POST"   "," "T_ACUTE_RENAL_POST"   "," "T_ACUTE_RENAL3_POST" "," "T_RESP_DISTRESS_POST" "," 
     "T_AM_FLUID_POST"  "," "T_CARD_ARR_POST"   "," "T_CONV_CARD_POST"     "," "T_DISS_INTRA_POST"   "," "T_DISS_INTRA3_POST"   "," 
     "T_ECLAMPSIA_POST" "," "T_HEART_FAIL_POST" "," "T_PUERP_POST"         "," "T_PULM_ED_POST"      "," "T_ANES_COMP_POST"     "," 
     "T_SEPSIS_POST"    "," "T_SHOCK_POST"      "," "T_SICKLE_POST"        "," "T_AIR_THROMB_POST"   "," "T_HYSTER_POST"        "," 
     "T_TRACHEO_POST"   "," "T_VENT_POST"       "," "T_DECEASED_FLAG_POST" ","
     "PAMH05"           "," "PAMH06"            "," "PAMH07"               ","   
     "P_MYOCARD_POST"   "," "P_ANEURYSM_POST"   "," "P_ACUTE_RENAL_POST"   "," "P_ACUTE_RENAL3_POST" "," "P_RESP_DISTRESS_POST" ","
     "P_AM_FLUID_POST"  "," "P_CARD_ARR_POST"   "," "P_CONV_CARD_POST"     "," "P_DISS_INTRA_POST"   "," "P_DISS_INTRA3_POST"   "," 
     "P_ECLAMPSIA_POST" "," "P_HEART_FAIL_POST" "," "P_PUERP_POST"         "," "P_PULM_ED_POST"      "," "P_ANES_COMP_POST"     "," 
     "P_SEPSIS_POST"    "," "P_SHOCK_POST"      "," "P_SICKLE_POST"        "," "P_AIR_THROMB_POST"   "," "P_HYSTER_POST"        "," 
     "P_TRACHEO_POST"   "," "P_VENT_POST"       "," "P_DECEASED_FLAG_POST" ","
     "OAMH05"           "," "OAMH06"            "," "OAMH07"               ","
     "O_MYOCARD_POST"   "," "O_ANEURYSM_POST"   "," "O_ACUTE_RENAL_POST"   "," "O_ACUTE_RENAL3_POST" "," "O_RESP_DISTRESS_POST" "," 
     "O_AM_FLUID_POST"  "," "O_CARD_ARR_POST"   "," "O_CONV_CARD_POST"     "," "O_DISS_INTRA_POST"   "," "O_DISS_INTRA3_POST"   "," 
     "O_ECLAMPSIA_POST" "," "O_HEART_FAIL_POST" "," "O_PUERP_POST"         "," "O_PULM_ED_POST"      "," "O_ANES_COMP_POST"     "," 
     "O_SEPSIS_POST"    "," "O_SHOCK_POST"      "," "O_SICKLE_POST"        "," "O_AIR_THROMB_POST"   "," "O_HYSTER_POST"        ","
     "O_TRACHEO_POST"   "," "O_VENT_POST"       "," "O_DECEASED_FLAG_POST"
     %end;
     %else %if &ref_pop. = 3 %then %do;
     "TAMH08" "," "TAMH09" "," "TAMH10A" "," "TAMH10B" "," "TAMH10" "," "TAMH11" ","
     "PAMH08" "," "PAMH09" "," "PAMH10A" "," "PAMH10B" "," "PAMH10" "," "PAMH11" "," 
     "OAMH08" "," "OAMH09" "," "OAMH10A" "," "OAMH10B" "," "OAMH10" "," "OAMH11"
     %end;
 ;
 end;

 put RACECAT 3. "," POVCAT 3.  "," HOSPST $2. "," YEAR 4. "," PAYCAT 3. ","
 %if &ref_pop. = 1 %then %do;
 (TAMH01-TAMH04 &T_VARS.) (7.0 ",")
 ","
 (PAMH01-PAMH04 &P_VARS.) (13.0 ",")
 ","
 (OAMH01-OAMH04 &O_VARS.) (16.10 ",")
 %end;
 %else %if &ref_pop. = 2 %then %do;
 (TAMH05-TAMH07 &T_VARS_POST.) (7.0 ",")
 ","
 (PAMH05-PAMH07 &P_VARS_POST.) (13.0 ",")
 ","
 (OAMH05-OAMH07 &O_VARS_POST.) (16.10 ",")
 %end;
 %else %if &ref_pop. = 3 %then %do;
 (TAMH08 TAMH09 TAMH10A TAMH10B TAMH10 TAMH11) (7.0 ",")
 ","
 (PAMH08 PAMH09 PAMH10A PAMH10B PAMH10 PAMH11) (13.0 ",")
 ","
 (OAMH08 OAMH09 OAMH10A OAMH10B OAMH10 OAMH11) (16.10 ",")
 %end;
 ;
 run;

 %END;

 %MEND TEXTP1;

 %TEXTP1;
