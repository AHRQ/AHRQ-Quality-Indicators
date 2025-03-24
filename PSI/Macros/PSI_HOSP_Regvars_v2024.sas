 * ------------------------------------------------------------- ;
 *  TITLE: PSI HOSPITAL REGRESSION VARIABLES                 --- ;
 *                                                           --- ;
 *  DESCRIPTION: Create binary covariates used for scoring   --- ;
 *               discharge records in risk adjustment.       --- ;
 *               Included in PSI_HOSP_RISKADJ.sas program    --- ;
 *               Requires PSI_HOSP_MEASURES.SAS output file  --- ;
 *                                                           --- ;
 *  VERSION: SAS QI v2024                                    --- ;
 *  RELEASE DATE: JULY 2024                                  --- ;
 * ------------------------------------------------------------- ;

* -- macro variables -- * ;
%let ageonly_ = Age_LT30 Age_30_34 Age_35_39 Age_40_44 Age_45_49 Age_50_54 Age_55_59 Age_60_64 Age_65_69 Age_70_74
                Age_75_79 Age_80_84 Age_85_89 Age_90Plus Age_85Plus Age_LT60 Age_70Plus;

%let genderonly_ = MALE;

%let agesx_ = Age_LT30_MALE Age_30_34_MALE Age_35_39_MALE Age_40_44_MALE Age_45_49_MALE Age_50_54_MALE Age_55_59_MALE Age_60_64_MALE Age_70_74_MALE
              Age_75_79_MALE Age_80_84_MALE Age_85_89_MALE Age_90Plus_MALE Age_85Plus_MALE Age_LT60_MALE Age_70Plus_MALE;

%let comorb_ = CMR_AIDS         CMR_ALCOHOL      CMR_ANEMDEF      CMR_AUTOIMMUNE  CMR_BLDLOSS      CMR_CANCER_LYMPH CMR_CANCER_LEUK
               CMR_CANCER_METS  CMR_CANCER_NSITU CMR_CANCER_SOLID CMR_CBVD        CMR_COAG         CMR_DEMENTIA     CMR_DEPRESS      CMR_DIAB_CX
               CMR_DIAB_UNCX    CMR_DRUG_ABUSE   CMR_HF           CMR_HTN_CX      CMR_HTN_UNCX     CMR_LIVER_MLD    CMR_LIVER_SEV    CMR_LUNG_CHRONIC
               CMR_NEURO_MOVT   CMR_NEURO_OTH    CMR_NEURO_SEIZ   CMR_OBESE       CMR_PARALYSIS    CMR_PERIVASC     CMR_PSYCHOSES    CMR_PULMCIRC
               CMR_RENLFL_MOD   CMR_RENLFL_SEV   CMR_THYROID_HYPO CMR_THYROID_OTH CMR_ULCER_PEPTIC CMR_VALVE        CMR_WGHTLOSS;
%let cnum = 38;

%let mdc_ = MDC_1  MDC_2  MDC_3  MDC_4  MDC_5
            MDC_6  MDC_7  MDC_8  MDC_9  MDC_10
            MDC_11 MDC_12 MDC_13 MDC_14 MDC_15
            MDC_16 MDC_17 MDC_18 MDC_19 MDC_20
            MDC_21 MDC_22 MDC_23 MDC_24 MDC_25;

%let qtr_ =  Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8;

%let covidqtr_ =  COVIDDX_Q1 COVIDDX_Q2 COVIDDX_Q3 COVIDDX_Q4 COVIDDX_Q5 COVIDDX_Q6 COVIDDX_Q7 COVIDDX_Q8;

*-- create age sex class variables --* ;

*-- MALE covariate --* ;
length &genderonly_. 3;
if SEX=1 then &genderonly_.=1 ;
else &genderonly_.=0 ;


*-- Age-only dummies --* ;
length &ageonly_. 3 ;
array agekats (17) &ageonly_.;

do i=1 to 17 ;
   agekats(i)=0 ;
end ;

     if age < 30  then Age_LT30=1;
else if age < 35  then Age_30_34=1;
else if age < 40  then Age_35_39=1;
else if age < 45  then Age_40_44=1;
else if age < 50  then Age_45_49=1;
else if age < 55  then Age_50_54=1;
else if age < 60  then Age_55_59=1;
else if age < 65  then Age_60_64=1;
else if age < 70  then Age_65_69=1;
else if age < 75  then Age_70_74=1;
else if age < 80  then Age_75_79=1;
else if age < 85  then Age_80_84=1;
else if age < 90  then Age_85_89=1;
else if age >= 90 then Age_90Plus=1;
     if age >= 85 then Age_85Plus=1;

   /*set up the reference level*/
  Age_65_69=0;
     if age < 60  then Age_LT60=1;
else if age >= 70 then Age_70Plus=1;


*-- Create age-sex interaction terms --* ;
length &agesx_. 3;

Age_LT30_MALE  =Age_LT30*MALE;
Age_30_34_MALE =Age_30_34*MALE;
Age_35_39_MALE =Age_35_39*MALE;
Age_40_44_MALE =Age_40_44*MALE;
Age_45_49_MALE =Age_45_49*MALE;
Age_50_54_MALE =Age_50_54*MALE;
Age_55_59_MALE =Age_55_59*MALE;
Age_60_64_MALE =Age_60_64*MALE;
Age_70_74_MALE =Age_70_74*MALE;
Age_75_79_MALE =Age_75_79*MALE;
Age_80_84_MALE =Age_80_84*MALE;
Age_85_89_MALE =Age_85_89*MALE;
Age_90Plus_MALE=Age_90Plus*MALE;
Age_85Plus_MALE=Age_85Plus*MALE;
Age_LT60_MALE  =Age_LT60*MALE;
Age_70Plus_MALE=Age_70Plus*MALE;

drop i;

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


%let val_MDRG =  101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 201 202 203 204 205 206 301 302 303 304 305 306 307 308 309 310 311 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 501 503 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 522 523 524 525 526 527 528 529 530 531 532 533 534 535 536 540 541 542 543 544 601 602 603 604 607 608 609 610 611 612 613 614 615 616 617 618 619 620 621 622 701 702 703 704 705 706 707 708 709 710 711 712 801 802 803 804 805 806 807 808 809 810 811 812 813 814 815 816 817 818 819 820 821 822 823 824 825 826 827 828 829 830 831 832 833 834 835 836 837 838 839 840 841 901 902 903 904 905 906 907 908 909 910 911 912 913 1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1101 1102 1103 1104 1105 1106 1107 1108 1109 1110 1112 1113 1115 1116 1117 1118 1201 1202 1203 1204 1205 1206 1207 1208 1209 1210 1301 1302 1303 1304 1305 1306 1307 1308 1309 1310 1311 1401 1402 1403 1404 1405 1406 1409 1411 1413 1414 1601 1602 1603 1604 1605 1606 1707 1708 1709 1710 1711 1712 1713 1714 1715 1716 1801 1802 1803 1804 1805 1806 1807 1808 1909 1910 1911 1912 1913 1914 1915 1916 1917 2018 2101 2102 2103 2104 2105 2106 2107 2108 2109 2201 2210 2212 2213 2214 2301 2302 2303 2304 2305 2406 2407 2408 2409 2501 2502 2503 7701 7702 7703 7704 7705 7706 7707;
%let n_MDRG   =  310;
%macro domdrg;
   %do i=1 %to &n_mdrg.;
     %let n=%scan(&val_mdrg.,&i.);
     if MDRG=%eval(&n.) then MDRG_&n. = 1; else MDRG_&n. = 0;
     /*set up the reference level*/
    %if &i.=&n_mdrg. %then %do; MDRG_&n.=0; %end;
   %end;
length MDRG_: 3;
%mend domdrg;
%domdrg;

/*-- HPPS13 -- HPPS13=0 as reference --*/
HPPS13_1=0; HPPS13_2=0; HPPS13_3=0 ;
     if HPPS13 in (1) then HPPS13_1 = 1;
else if HPPS13 in (2) then HPPS13_2 = 1;
else if HPPS13 in (3) then HPPS13_3 = 1;

/*-- HPPS15 --*/
HPPS15_2 = 0; HPPS15_3 = 0; HPPS15_4 =0 ;
HPPS15_5 = 0; HPPS15_6 = 0; HPPS15_7 = 0;
     if HPPS15 in (2)   then HPPS15_2 = 1;
else if HPPS15 in (3)   then HPPS15_3 = 1;
else if HPPS15 in (4)   then HPPS15_4 = 1;
else if HPPS15 in (5)   then HPPS15_5 = 1;
else if HPPS15 in (6)   then HPPS15_6 = 1;
else if HPPS15 in (7)   then HPPS15_7 = 1;


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

if TPPS14_NONOPEN in (0,1) then PS14s=0;
else if TPPS14_OPEN in (0,1) then PS14s=1;

/*-- Create the comorbidity count variables for PSI and PDI --*/
%macro docomorb;
   comorb_NonWt  =sum(%do i = 1 %to %eval(&cnum.-1); %scan(&comorb_.,&i.), %end;  %scan(&comorb_.,&cnum.));
%mend docomorb;
%docomorb;
if 3 < comorb_NonWt <= 5 then PS02_NonWt_1              =1; else PS02_NonWt_1              =0;
if     comorb_NonWt >= 6 then PS02_NonWt_2              =1; else PS02_NonWt_2              =0;
if 1 < comorb_NonWt <= 3 then PS03_NonWt_1              =1; else PS03_NonWt_1              =0;
if     comorb_NonWt >= 4 then PS03_NonWt_2              =1; else PS03_NonWt_2              =0;
if 3 < comorb_NonWt <= 5 then PS04_DVT_PE_NonWt_1       =1; else PS04_DVT_PE_NonWt_1       =0;
if     comorb_NonWt >= 6 then PS04_DVT_PE_NonWt_2       =1; else PS04_DVT_PE_NonWt_2       =0;
if 2 < comorb_NonWt <= 4 then PS04_GIHEMORRHAGE_NonWt_1 =1; else PS04_GIHEMORRHAGE_NonWt_1 =0;
if     comorb_NonWt >= 5 then PS04_GIHEMORRHAGE_NonWt_2 =1; else PS04_GIHEMORRHAGE_NonWt_2 =0;
if 2 < comorb_NonWt <= 4 then PS04_PNEUMONIA_NonWt_1    =1; else PS04_PNEUMONIA_NonWt_1    =0;
if     comorb_NonWt >= 5 then PS04_PNEUMONIA_NonWt_2    =1; else PS04_PNEUMONIA_NonWt_2    =0;
if 1 < comorb_NonWt <= 3 then PS04_SEPSIS_NonWt_1       =1; else PS04_SEPSIS_NonWt_1       =0;
if     comorb_NonWt >= 4 then PS04_SEPSIS_NonWt_2       =1; else PS04_SEPSIS_NonWt_2       =0;
if 1 < comorb_NonWt <= 3 then PS04_SHOCK_NonWt_1        =1; else PS04_SHOCK_NonWt_1        =0;
if     comorb_NonWt >= 4 then PS04_SHOCK_NonWt_2        =1; else PS04_SHOCK_NonWt_2        =0;
if 2 < comorb_NonWt <= 6 then PS06_NonWt_1              =1; else PS06_NonWt_1              =0;
if     comorb_NonWt >= 7 then PS06_NonWt_2              =1; else PS06_NonWt_2              =0;
if 1 < comorb_NonWt <= 3 then PS07_NonWt_1              =1; else PS07_NonWt_1              =0;
if     comorb_NonWt >= 4 then PS07_NonWt_2              =1; else PS07_NonWt_2              =0;
if 3 < comorb_NonWt <= 6 then PS08_NonWt_1              =1; else PS08_NonWt_1              =0;
if     comorb_NonWt >= 7 then PS08_NonWt_2              =1; else PS08_NonWt_2              =0;
if 1 < comorb_NonWt <= 3 then PS09_NonWt_1              =1; else PS09_NonWt_1              =0;
if     comorb_NonWt >= 4 then PS09_NonWt_2              =1; else PS09_NonWt_2              =0;
if 3 < comorb_NonWt <= 5 then PS10_NonWt_1              =1; else PS10_NonWt_1              =0;
if     comorb_NonWt >= 6 then PS10_NonWt_2              =1; else PS10_NonWt_2              =0;
if 2 < comorb_NonWt <= 4 then PS11_NonWt_1              =1; else PS11_NonWt_1              =0;
if     comorb_NonWt >= 5 then PS11_NonWt_2              =1; else PS11_NonWt_2              =0;
if 1 < comorb_NonWt <= 3 then PS12_NonWt_1              =1; else PS12_NonWt_1              =0;
if     comorb_NonWt >= 4 then PS12_NonWt_2              =1; else PS12_NonWt_2              =0;
if 2 < comorb_NonWt <= 4 then PS13_NonWt_1              =1; else PS13_NonWt_1              =0;
if     comorb_NonWt >= 5 then PS13_NonWt_2              =1; else PS13_NonWt_2              =0;
if 0 < comorb_NonWt <= 1 then PS15_NonWt_1              =1; else PS15_NonWt_1              =0;
if     comorb_NonWt >= 2 then PS15_NonWt_2              =1; else PS15_NonWt_2              =0;
 
/*stratification interactions selected */
PS14s_Age_50_54_MALE  = PS14s*Age_50_54_MALE  ;
PS14s_Age_55_59  = PS14s*Age_55_59  ;
PS14s_CMR_ALCOHOL  = PS14s*CMR_ALCOHOL  ;
PS14s_CMR_ANEMDEF  = PS14s*CMR_ANEMDEF  ;
PS14s_CMR_BLDLOSS  = PS14s*CMR_BLDLOSS  ;
PS14s_CMR_CANCER_METS  = PS14s*CMR_CANCER_METS  ;
PS14s_CMR_CANCER_SOLID  = PS14s*CMR_CANCER_SOLID  ;
PS14s_CMR_DIAB_UNCX  = PS14s*CMR_DIAB_UNCX  ;
PS14s_CMR_HTN_CX  = PS14s*CMR_HTN_CX  ;
PS14s_CMR_HTN_UNCX  = PS14s*CMR_HTN_UNCX  ;
PS14s_CMR_OBESE  = PS14s*CMR_OBESE  ;
PS14s_CMR_RENLFL_MOD  = PS14s*CMR_RENLFL_MOD  ;
PS14s_CMR_RENLFL_SEV  = PS14s*CMR_RENLFL_SEV  ;
PS14s_CMR_VALVE  = PS14s*CMR_VALVE  ;
PS14s_MDC_11  = PS14s*MDC_11  ;
PS14s_MDC_13  = PS14s*MDC_13  ;
PS14s_MDC_18  = PS14s*MDC_18  ;
PS14s_MDC_24  = PS14s*MDC_24  ;
PS14s_MDC_4  = PS14s*MDC_4  ;
PS14s_MDC_8  = PS14s*MDC_8  ;
PS14s_MDRG_1103  = PS14s*MDRG_1103  ;
PS14s_MDRG_1304  = PS14s*MDRG_1304  ;
PS14s_MDRG_542  = PS14s*MDRG_542  ;
PS14s_MDRG_602  = PS14s*MDRG_602  ;
PS14s_MDRG_604  = PS14s*MDRG_604  ;
PS14s_TRNSFER  = PS14s*TRNSFER  ;
PS14s_YEAR_2019  = PS14s*YEAR_2019  ;
/*end of interactions selected */
