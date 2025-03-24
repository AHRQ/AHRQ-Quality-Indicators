 * ------------------------------------------------------------- ;
 *  TITLE: IQI HOSPITAL REGRESSION VARIABLES                 --- ;
 *                                                           --- ;
 *  DESCRIPTION: Create binary covariates used for scoring   --- ;
 *               discharge records in risk adjustment.       --- ;
 *               Included in IQI_HOSP_RISKADJ.sas program    --- ;
 *               Requires IQI_HOSP_MEASURES.SAS output file  --- ;
 *                                                           --- ;
 *  VERSION: SAS QI v2024                                    --- ;
 *  RELEASE DATE: JULY 2024                                  --- ;
 * ------------------------------------------------------------- ;

* -- macro variables -- * ;
%let ageonly_ = Age_LT30 Age_30_34 Age_35_39 Age_40_44 Age_45_49 Age_50_54 Age_55_59 Age_60_64 Age_65_69 Age_70_74
                Age_75_79 Age_80_84 Age_85_89 Age_90Plus Age_85Plus Age_LT60;

%let genderonly_ = MALE;

%let agesx_ = Age_LT30_MALE Age_30_34_MALE Age_35_39_MALE Age_40_44_MALE Age_45_49_MALE Age_50_54_MALE Age_55_59_MALE Age_60_64_MALE Age_65_69_MALE Age_70_74_MALE
              Age_75_79_MALE Age_80_84_MALE Age_85_89_MALE Age_90Plus_MALE Age_85Plus_MALE Age_LT60_MALE;

%let mdc_ =  MDC_1  MDC_2  MDC_3  MDC_4  MDC_5
                MDC_6  MDC_7  MDC_8  MDC_9  MDC_10
                MDC_11 MDC_12 MDC_13 MDC_14 MDC_15
                MDC_16 MDC_17 MDC_18 MDC_19 MDC_20
                MDC_21 MDC_22 MDC_23 MDC_24 MDC_25 ;

%let qtr_ =  Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8;

%let covidqtr_ =  COVIDDX_Q1 COVIDDX_Q2 COVIDDX_Q3 COVIDDX_Q4 COVIDDX_Q5 COVIDDX_Q6 COVIDDX_Q7 COVIDDX_Q8;

*-- create age sex class variables --* ;

*-- MALE covariate --* ;
length &genderonly_. 3;
if SEX=1 then &genderonly_.=1 ;
else &genderonly_.=0 ;


*-- Age-only dummies --* ;
length &ageonly_. 3 ;
array agekats (16) &ageonly_.;

do i=1 to 16 ;
   agekats(i)=0 ;
end ;

     if age < 30  then Age_LT30=1   ;
else if age < 35  then Age_30_34=1  ;
else if age < 40  then Age_35_39=1  ;
else if age < 45  then Age_40_44=1  ;
else if age < 50  then Age_45_49=1  ;
else if age < 55  then Age_50_54=1  ;
else if age < 60  then Age_55_59=1  ;
else if age < 65  then Age_60_64=1  ;
else if age < 70  then Age_65_69=1  ;
else if age < 75  then Age_70_74=1  ;
else if age < 80  then Age_75_79=1  ;
else if age < 85  then Age_80_84=1  ;
else if age < 90  then Age_85_89=1  ;
else if age >= 90 then Age_90Plus=1 ;
     if age < 60  then Age_LT60=1   ;
     if age >= 85 then Age_85Plus=1 ;
   /*set up the reference level*/
  Age_65_69=0;


*-- Create age-sex interaction terms --* ;
length &agesx_. 3;

Age_LT30_MALE  =Age_LT30*MALE ;
Age_30_34_MALE =Age_30_34*MALE;
Age_35_39_MALE =Age_35_39*MALE;
Age_40_44_MALE =Age_40_44*MALE;
Age_45_49_MALE =Age_45_49*MALE;
Age_50_54_MALE =Age_50_54*MALE;
Age_55_59_MALE =Age_55_59*MALE;
Age_60_64_MALE =Age_60_64*MALE;
Age_65_69_MALE =Age_65_69*MALE;
Age_70_74_MALE =Age_70_74*MALE;
Age_75_79_MALE =Age_75_79*MALE;
Age_80_84_MALE =Age_80_84*MALE;
Age_85_89_MALE =Age_85_89*MALE;
Age_90Plus_MALE=Age_90Plus*MALE;
Age_85Plus_MALE=Age_85Plus*MALE;
Age_LT60_MALE  =Age_LT60*MALE;

drop i;

*-- Create COVID, QUARTER dummies and interaction--* ;
length YEAR_2019 &qtr_. 3 ;
YEAR_2019=0;
Q1=0;Q2=0;Q3=0;Q4=0;Q5=0;Q6=0;Q7=0;Q8=0;
if YEAR<=2019 then do;
  YEAR_2019=1;
end;
else if YEAR=2020 then do;
  if DQTR=1 then Q1=1;
  if DQTR=2 then Q2=1;
  if DQTR=3 then Q3=1;
  if DQTR=4 then Q4=1;
end;
else if YEAR=2021 then do;
  if DQTR=1 then Q5=1;
  if DQTR=2 then Q6=1;
  if DQTR=3 then Q7=1;
  if DQTR=4 then Q8=1;
end;
else if YEAR >= 2022 then do;
  Q8=1;
end;

*-- Create covid quarter interaction terms --* ;
length &covidqtr_. 3;
COVIDDX_Q1  = COVIDDX*Q1 ;
COVIDDX_Q2  = COVIDDX*Q2 ;
COVIDDX_Q3  = COVIDDX*Q3 ;
COVIDDX_Q4  = COVIDDX*Q4 ;
COVIDDX_Q5  = COVIDDX*Q5 ;
COVIDDX_Q6  = COVIDDX*Q6 ;
COVIDDX_Q7  = COVIDDX*Q7 ;
COVIDDX_Q8  = COVIDDX*Q8 ;

*-- Create stratum variable --* ;
if TPIQ09_WITH_CANCER in (0,1) then IQ09s=0;
else if TPIQ09_WITHOUT_CANCER in (0,1) then IQ09s=1;

if TPIQ11_OPEN_RUPTURED in (0,1) then IQ11s=0;
else if TPIQ11_OPEN_UNRUPTURED in (0,1) then IQ11s=1;
else if TPIQ11_ENDO_RUPTURED in (0,1) then IQ11s=2;
else if TPIQ11_ENDO_UNRUPTURED in (0,1) then IQ11s=3;

if TPIQ17_HEMSTROKE_SUBARACH in (0,1) then IQ17s=0;
else if TPIQ17_HEMSTROKE_INTRACER in (0,1) then IQ17s=1;
else if TPIQ17_ISCHEMSTROKE in (0,1) then IQ17s=2;

*-- Create stratum dummies --* ;
length IQ11s0 IQ11s1 IQ11s2 IQ17s0 IQ17s1 3;
IQ11s0=0;IQ11s1=0;IQ11s2=0;IQ17s0=0;IQ17s1=0;
if IQ11s=0 then IQ11s0=1;
if IQ11s=1 then IQ11s1=1;
if IQ11s=2 then IQ11s2=1;
if IQ17s=0 then IQ17s0=1;
if IQ17s=1 then IQ17s1=1;

*-- Create MDC dummies --* ;
length &mdc_. 3 ;
%macro domdc;
   %do i = 1 %to 25;
      if MDC=&i. then MDC_&i. = 1; else MDC_&i. = 0; 
   %end;
   /*set up the reference level*/
   MDC_25=0;
%mend domdc;
%domdc;
  
/*stratification interactions selected */
IQ09s_MDC_17  = IQ09s*MDC_17  ;
IQ09s_d_DXCCSR_DIG020  = IQ09s*d_DXCCSR_DIG020  ;
IQ09s_d_DXCCSR_NEO073  = IQ09s*d_DXCCSR_NEO073  ;
IQ09s_d_IQ09_PRCCSR_URN008  = IQ09s*d_IQ09_PRCCSR_URN008  ;
IQ11s0_TRNSFER  = IQ11s0*TRNSFER  ;
IQ11s0_d_DXCCSR_CIR008  = IQ11s0*d_DXCCSR_CIR008  ;
IQ11s0_d_DXCCSR_CIR019  = IQ11s0*d_DXCCSR_CIR019  ;
IQ11s0_d_DXCCSR_DIG025  = IQ11s0*d_DXCCSR_DIG025  ;
IQ11s0_d_DXCCSR_END008  = IQ11s0*d_DXCCSR_END008  ;
IQ11s0_d_DXCCSR_END010  = IQ11s0*d_DXCCSR_END010  ;
IQ11s0_d_DXCCSR_END011  = IQ11s0*d_DXCCSR_END011  ;
IQ11s0_d_DXCCSR_FAC009  = IQ11s0*d_DXCCSR_FAC009  ;
IQ11s0_d_DXCCSR_GEN002  = IQ11s0*d_DXCCSR_GEN002  ;
IQ11s0_d_DXCCSR_GEN003  = IQ11s0*d_DXCCSR_GEN003  ;
IQ11s0_d_DXCCSR_RSP012  = IQ11s0*d_DXCCSR_RSP012  ;
IQ11s0_d_DXCCSR_SYM003  = IQ11s0*d_DXCCSR_SYM003  ;
IQ11s0_d_IQ11_PRCCSR_CAR007  = IQ11s0*d_IQ11_PRCCSR_CAR007  ;
IQ11s0_d_IQ11_PRCCSR_CAR008  = IQ11s0*d_IQ11_PRCCSR_CAR008  ;
IQ11s0_d_IQ11_PRCCSR_CAR012  = IQ11s0*d_IQ11_PRCCSR_CAR012  ;
IQ11s0_d_IQ11_PRCCSR_CAR014  = IQ11s0*d_IQ11_PRCCSR_CAR014  ;
IQ11s1_TRNSFER  = IQ11s1*TRNSFER  ;
IQ11s1_d_DXCCSR_CIR008  = IQ11s1*d_DXCCSR_CIR008  ;
IQ11s1_d_DXCCSR_CIR019  = IQ11s1*d_DXCCSR_CIR019  ;
IQ11s1_d_DXCCSR_DIG025  = IQ11s1*d_DXCCSR_DIG025  ;
IQ11s1_d_DXCCSR_END008  = IQ11s1*d_DXCCSR_END008  ;
IQ11s1_d_DXCCSR_END010  = IQ11s1*d_DXCCSR_END010  ;
IQ11s1_d_DXCCSR_END011  = IQ11s1*d_DXCCSR_END011  ;
IQ11s1_d_DXCCSR_FAC009  = IQ11s1*d_DXCCSR_FAC009  ;
IQ11s1_d_DXCCSR_GEN002  = IQ11s1*d_DXCCSR_GEN002  ;
IQ11s1_d_DXCCSR_GEN003  = IQ11s1*d_DXCCSR_GEN003  ;
IQ11s1_d_DXCCSR_RSP012  = IQ11s1*d_DXCCSR_RSP012  ;
IQ11s1_d_DXCCSR_SYM003  = IQ11s1*d_DXCCSR_SYM003  ;
IQ11s1_d_IQ11_PRCCSR_CAR007  = IQ11s1*d_IQ11_PRCCSR_CAR007  ;
IQ11s1_d_IQ11_PRCCSR_CAR008  = IQ11s1*d_IQ11_PRCCSR_CAR008  ;
IQ11s1_d_IQ11_PRCCSR_CAR012  = IQ11s1*d_IQ11_PRCCSR_CAR012  ;
IQ11s1_d_IQ11_PRCCSR_CAR014  = IQ11s1*d_IQ11_PRCCSR_CAR014  ;
IQ11s2_TRNSFER  = IQ11s2*TRNSFER  ;
IQ11s2_d_DXCCSR_CIR008  = IQ11s2*d_DXCCSR_CIR008  ;
IQ11s2_d_DXCCSR_CIR019  = IQ11s2*d_DXCCSR_CIR019  ;
IQ11s2_d_DXCCSR_DIG025  = IQ11s2*d_DXCCSR_DIG025  ;
IQ11s2_d_DXCCSR_END008  = IQ11s2*d_DXCCSR_END008  ;
IQ11s2_d_DXCCSR_END010  = IQ11s2*d_DXCCSR_END010  ;
IQ11s2_d_DXCCSR_END011  = IQ11s2*d_DXCCSR_END011  ;
IQ11s2_d_DXCCSR_FAC009  = IQ11s2*d_DXCCSR_FAC009  ;
IQ11s2_d_DXCCSR_GEN002  = IQ11s2*d_DXCCSR_GEN002  ;
IQ11s2_d_DXCCSR_GEN003  = IQ11s2*d_DXCCSR_GEN003  ;
IQ11s2_d_DXCCSR_RSP012  = IQ11s2*d_DXCCSR_RSP012  ;
IQ11s2_d_DXCCSR_SYM003  = IQ11s2*d_DXCCSR_SYM003  ;
IQ11s2_d_IQ11_PRCCSR_CAR007  = IQ11s2*d_IQ11_PRCCSR_CAR007  ;
IQ11s2_d_IQ11_PRCCSR_CAR008  = IQ11s2*d_IQ11_PRCCSR_CAR008  ;
IQ11s2_d_IQ11_PRCCSR_CAR012  = IQ11s2*d_IQ11_PRCCSR_CAR012  ;
IQ11s2_d_IQ11_PRCCSR_CAR014  = IQ11s2*d_IQ11_PRCCSR_CAR014  ;
IQ17s0_DNR  = IQ17s0*DNR  ;
IQ17s0_TRNSFER  = IQ17s0*TRNSFER  ;
IQ17s0_d_DXCCSR_CIR007  = IQ17s0*d_DXCCSR_CIR007  ;
IQ17s0_d_DXCCSR_CIR009  = IQ17s0*d_DXCCSR_CIR009  ;
IQ17s0_d_DXCCSR_CIR017  = IQ17s0*d_DXCCSR_CIR017  ;
IQ17s0_d_DXCCSR_CIR019  = IQ17s0*d_DXCCSR_CIR019  ;
IQ17s0_d_DXCCSR_CIR021  = IQ17s0*d_DXCCSR_CIR021  ;
IQ17s0_d_DXCCSR_END008  = IQ17s0*d_DXCCSR_END008  ;
IQ17s0_d_DXCCSR_END010  = IQ17s0*d_DXCCSR_END010  ;
IQ17s0_d_DXCCSR_END011  = IQ17s0*d_DXCCSR_END011  ;
IQ17s0_d_DXCCSR_FAC009  = IQ17s0*d_DXCCSR_FAC009  ;
IQ17s0_d_DXCCSR_GEN002  = IQ17s0*d_DXCCSR_GEN002  ;
IQ17s0_d_DXCCSR_MBD024  = IQ17s0*d_DXCCSR_MBD024  ;
IQ17s0_d_DXCCSR_NEO070  = IQ17s0*d_DXCCSR_NEO070  ;
IQ17s0_d_DXCCSR_NVS008  = IQ17s0*d_DXCCSR_NVS008  ;
IQ17s0_d_DXCCSR_NVS020  = IQ17s0*d_DXCCSR_NVS020  ;
IQ17s0_d_DXCCSR_RSP002  = IQ17s0*d_DXCCSR_RSP002  ;
IQ17s0_d_DXCCSR_RSP010  = IQ17s0*d_DXCCSR_RSP010  ;
IQ17s0_d_DXCCSR_RSP012  = IQ17s0*d_DXCCSR_RSP012  ;
IQ17s0_d_DXCCSR_SYM005  = IQ17s0*d_DXCCSR_SYM005  ;
IQ17s1_DNR  = IQ17s1*DNR  ;
IQ17s1_TRNSFER  = IQ17s1*TRNSFER  ;
IQ17s1_d_DXCCSR_CIR007  = IQ17s1*d_DXCCSR_CIR007  ;
IQ17s1_d_DXCCSR_CIR009  = IQ17s1*d_DXCCSR_CIR009  ;
IQ17s1_d_DXCCSR_CIR017  = IQ17s1*d_DXCCSR_CIR017  ;
IQ17s1_d_DXCCSR_CIR019  = IQ17s1*d_DXCCSR_CIR019  ;
IQ17s1_d_DXCCSR_CIR021  = IQ17s1*d_DXCCSR_CIR021  ;
IQ17s1_d_DXCCSR_END008  = IQ17s1*d_DXCCSR_END008  ;
IQ17s1_d_DXCCSR_END010  = IQ17s1*d_DXCCSR_END010  ;
IQ17s1_d_DXCCSR_END011  = IQ17s1*d_DXCCSR_END011  ;
IQ17s1_d_DXCCSR_FAC009  = IQ17s1*d_DXCCSR_FAC009  ;
IQ17s1_d_DXCCSR_GEN002  = IQ17s1*d_DXCCSR_GEN002  ;
IQ17s1_d_DXCCSR_MBD024  = IQ17s1*d_DXCCSR_MBD024  ;
IQ17s1_d_DXCCSR_NEO070  = IQ17s1*d_DXCCSR_NEO070  ;
IQ17s1_d_DXCCSR_NVS008  = IQ17s1*d_DXCCSR_NVS008  ;
IQ17s1_d_DXCCSR_NVS020  = IQ17s1*d_DXCCSR_NVS020  ;
IQ17s1_d_DXCCSR_RSP002  = IQ17s1*d_DXCCSR_RSP002  ;
IQ17s1_d_DXCCSR_RSP010  = IQ17s1*d_DXCCSR_RSP010  ;
IQ17s1_d_DXCCSR_RSP012  = IQ17s1*d_DXCCSR_RSP012  ;
IQ17s1_d_DXCCSR_SYM005  = IQ17s1*d_DXCCSR_SYM005  ;
/*end of interactions selected */
