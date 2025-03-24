 * ------------------------------------------------------------- ;
 *  TITLE: PDI HOSPITAL REGRESSION VARIABLES                 --- ;
 *                                                           --- ;
 *  DESCRIPTION: Create binary covariates used for scoring   --- ;
 *               discharge records in risk adjustment.       --- ;
 *               Included in PDI_HOSP_RISKADJ.sas program    --- ;
 *               Requires PDI_ALL_MEASURES.SAS output file   --- ;
 *                                                           --- ;
 *  VERSION: SAS QI v2024                                    --- ;
 *  RELEASE DATE: JULY 2024                                  --- ;
 * ------------------------------------------------------------- ;

* -- macro variables -- * ;
%let ageonly_ =AGE_1 AGE_2 AGE_3 AGE_1_2 AGE_2_3 AGE_5 AGE_6 AGE_7 AGEDAY_0;

%let genderonly_ = MALE;

%let agesx_ = AGE_1_MALE AGE_2_MALE AGE_3_MALE AGE_1_2_MALE AGE_2_3_MALE AGE_5_MALE AGE_6_MALE AGE_7_MALE AGEDAY_0_MALE;

%let comorb_ = CMR_AIDS        CMR_ALCOHOL      CMR_ANEMDEF      CMR_AUTOIMMUNE  CMR_BLDLOSS      CMR_CANCER_LYMPH CMR_CANCER_LEUK
               CMR_CANCER_METS  CMR_CANCER_NSITU CMR_CANCER_SOLID CMR_CBVD        CMR_COAG         CMR_DEMENTIA     CMR_DEPRESS      CMR_DIAB_CX
               CMR_DIAB_UNCX    CMR_DRUG_ABUSE   CMR_HF           CMR_HTN_CX      CMR_HTN_UNCX     CMR_LIVER_MLD    CMR_LIVER_SEV    CMR_LUNG_CHRONIC
               CMR_NEURO_MOVT   CMR_NEURO_OTH    CMR_NEURO_SEIZ   CMR_OBESE       CMR_PARALYSIS    CMR_PERIVASC     CMR_PSYCHOSES    CMR_PULMCIRC
               CMR_RENLFL_MOD   CMR_RENLFL_SEV   CMR_THYROID_HYPO CMR_THYROID_OTH CMR_ULCER_PEPTIC CMR_VALVE        CMR_WGHTLOSS;
%let cnum = 38;

%let qtr_ =  Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8;

%let covidqtr_ =  COVIDDX_Q1 COVIDDX_Q2 COVIDDX_Q3 COVIDDX_Q4 COVIDDX_Q5 COVIDDX_Q6 COVIDDX_Q7 COVIDDX_Q8;


*-- create age sex class variables --* ;

*-- MALE covariate --* ;
length &genderonly_. 3;
if SEX=1 then &genderonly_.=1 ;
else &genderonly_.=0 ;


*-- Age-only dummies --* ;
length &ageonly_. 3 ;
array agekats (9) &ageonly_.;

do i=1 to 9 ;
   agekats(i)=0 ;
end ;

if 0 <= ageday <=59  then AGE_1 =1;
else if 60 <= ageday <=179 then AGE_2 =1;
else if 180<= ageday <=364 then AGE_3 =1;
if 0 <= ageday <=179 then AGE_1_2 =1;
if 60<= ageday <=364 then AGE_2_3 =1;
if 4 <= age <=9 then AGE_5=1;
else if 10 <= age <=14 then AGE_6=1;
else if 15 <= age <=17 then AGE_7=1;
if ageday=0 then AGEDAY_0=1;


*-- Create age-sex interaction terms --* ;
length &agesx_. 3;

AGE_1_MALE  = AGE_1*MALE;
AGE_2_MALE  = AGE_2*MALE;
AGE_3_MALE  = AGE_3*MALE;
AGE_1_2_MALE= AGE_1_2*MALE;
AGE_2_3_MALE= AGE_2_3*MALE;
AGE_5_MALE  = AGE_5*MALE;
AGE_6_MALE  = AGE_6*MALE;
AGE_7_MALE  = AGE_7*MALE;
AGEDAY_0_MALE = AGEDAY_0*MALE;

drop i;

%let val_MDRG =  101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 201 202 203 204 205 206 301 302 303 304 305 306 307 308 309 310 311 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 501 503 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 522 523 524 525 526 527 528 529 530 531 532 533 534 535 536 540 541 542 543 544 601 602 603 604 607 608 609 610 611 612 613 614 615 616 617 618 619 620 621 622 701 702 703 704 705 706 707 708 709 710 711 712 801 802 803 804 805 806 807 808 809 810 811 812 813 814 815 816 817 818 819 820 821 822 823 824 825 826 827 828 829 830 831 832 833 834 835 836 837 838 839 840 841 901 902 903 904 905 906 907 908 909 910 911 912 913 1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1101 1102 1103 1104 1105 1106 1107 1108 1109 1110 1112 1113 1115 1116 1117 1118 1201 1202 1203 1204 1205 1206 1207 1208 1209 1210 1301 1302 1303 1304 1305 1306 1307 1308 1309 1310 1311 1401 1402 1405 1406 1411 1502 1503 1504 1505 1506 1507 1601 1602 1603 1604 1605 1606 1707 1708 1709 1710 1711 1712 1713 1714 1715 1716 1801 1802 1803 1804 1805 1806 1807 1808 1909 1910 1911 1912 1913 1914 1915 1916 1917 2018 2101 2102 2103 2104 2105 2106 2107 2108 2109 2201 2210 2212 2213 2214 2301 2302 2303 2304 2305 2406 2407 2408 2409 2501 2502 2503 7701 7702 7703 7704 7705 7707;
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


/*-- GPPD08 --*/
GPPD08_2=0;
if GPPD08 in (2) then GPPD08_2 = 1;

/*-- GPPD10 --*/
GPPD10_2 = 0; GPPD10_3 = 0; GPPD10_4 =0; GPPD10_5 =0; GPPD10_6 =0;
     if GPPD10 in (2) then GPPD10_2 = 1;
else if GPPD10 in (3) then GPPD10_3 = 1;
else if GPPD10 in (4) then GPPD10_4 = 1;
else if GPPD10 in (5) then GPPD10_5 = 1;
else if GPPD10 in (6) then GPPD10_6 = 1;

/*-- GPPD12 --*/
GPPD12_2 = 0; GPPD12_3 = 0;
     if GPPD12 in (2) then GPPD12_2 = 1;
else if GPPD12 in (3) then GPPD12_3 = 1;

/*-- HPPD01 --*/
HPPD01_2 = 0; HPPD01_3 = 0; HPPD01_4 =0 ;
HPPD01_5 = 0; HPPD01_6 = 0; HPPD01_7 = 0;
     if HPPD01 in (2)   then HPPD01_2 = 1;
else if HPPD01 in (3)   then HPPD01_3 = 1;
else if HPPD01 in (4)   then HPPD01_4 = 1;
else if HPPD01 in (5)   then HPPD01_5 = 1;
else if HPPD01 in (6)   then HPPD01_6 = 1;
else if HPPD01 in (7)   then HPPD01_7 = 1;

/*-- HPPD10 --HPPD10=0 as reference */
HPPD10_1=0; HPPD10_2=0; HPPD10_3=0 ;
     if HPPD10 in (1) then HPPD10_1 = 1;
else if HPPD10 in (2) then HPPD10_2 = 1;
else if HPPD10 in (3) then HPPD10_3 = 1;


/*-- BWHTCAT --*/
BWHTCAT_2 = 0; BWHTCAT_3 = 0; BWHTCAT_4 =0 ;
BWHTCAT_5 = 0; BWHTCAT_6 = 0; BWHTCAT_7 = 0; BWHTCAT_8 = 0; 
     if BWHTCAT in (8)   then BWHTCAT_2 = 1;
else if BWHTCAT in (7)   then BWHTCAT_3 = 1;
else if BWHTCAT in (6)   then BWHTCAT_4 = 1;
else if BWHTCAT in (5)   then BWHTCAT_5 = 1;
else if BWHTCAT in (4)   then BWHTCAT_6 = 1;
else if BWHTCAT in (3)   then BWHTCAT_7 = 1;
else if BWHTCAT in (1,2)   then BWHTCAT_8 = 1;


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


/*-- Create the comorbidity count variables for PSI and PDI --*/
%macro docomorb;
   comorb_NonWt  =sum(%do i = 1 %to %eval(&cnum.-1); %scan(&comorb_.,&i.), %end;  %scan(&comorb_.,&cnum.));
%mend docomorb;
%docomorb;
if     comorb_NonWt >= 1 then PD01_NonWt_1 =1; else PD01_NonWt_1 =0;
if     comorb_NonWt >= 2 then PD05_NonWt_1 =1; else PD05_NonWt_1 =0;
if 0 < comorb_NonWt <= 1 then PD08_NonWt_1 =1; else PD08_NonWt_1 =0;
if     comorb_NonWt >= 2 then PD08_NonWt_2 =1; else PD08_NonWt_2 =0;
if 0 < comorb_NonWt <= 2 then PD09_NonWt_1 =1; else PD09_NonWt_1 =0;
if     comorb_NonWt >= 3 then PD09_NonWt_2 =1; else PD09_NonWt_2 =0;
if 1 < comorb_NonWt <= 2 then PD10_NonWt_1 =1; else PD10_NonWt_1 =0;
if     comorb_NonWt >= 3 then PD10_NonWt_2 =1; else PD10_NonWt_2 =0;
if     comorb_NonWt >= 2 then PD12_NonWt_1 =1; else PD12_NonWt_1 =0;
