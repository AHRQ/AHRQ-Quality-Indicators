* ====================== Program : PDI_AREA_OBSERVED.SAS =====================;
*
*  TITLE:  AREA OBSERVED RATES FOR AHRQ PEDIATRIC QUALITY INDICATORS
*
*  DESCRIPTION:
*         Calculate observed rates for
*         Pediatric Quality Indicators across stratifiers.
*         Output stratified by AREA, SEXCAT and RACECAT 
*         from population file and PDI_ALL_MEASURE.SAS output.
*         Variables created by this program are PAPDXX and OAPDXX.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*=============================================================================;

 title2 'PROGRAM PDI_AREA_OBSERVED';
 title3 'AHRQ PEDIATRIC QUALITY INDICATORS: CALCULATE ADJUSTED AREA RATES';

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR                               --- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE     --- ;
 * --- OUTPUT BASED ON AREAS IN PDI_ALL_MEASURES OUTPUT.        --- ;
 * ---------------------------------------------------------------- ;

 /*MACRO TO ADJUST AREA AGGREGATION BASED ON MAREA VALUE IN PDI_ALL_CONTROL.*/

 %MACRO CTY2MA;
    %IF &MALEVL EQ 0 %THEN %DO;
        attrib MAREA length=$5
          label='FIPS State County Code';
        MAREA = FIPSTCO;
    %END;
    %ELSE %IF &MALEVL EQ 1 %THEN %DO;
        attrib MAREA length=$5
          label='MODIFIED FIPS';
        MAREA = input(put(FIPSTCO,$M1AREA.),$5.);
    %END;
    %ELSE %IF &MALEVL EQ 2 %THEN %DO;
        attrib MAREA length=$5
          label='OMB 1999 METRO AREA';
        MAREA = input(put(FIPSTCO,$M2AREA.),$5.);
    %END;
    %ELSE %IF &MALEVL EQ 3 %THEN %DO;
        attrib MAREA length=$5
          label='OMB 2003 METRO AREA';
        MAREA = input(put(FIPSTCO,$M3AREA.),$5.);
    %END;
 %MEND;

 data   TEMP0 (keep=MAREA);
 set    OUTMSR.&OUTFILE_MEAS.;

 %CTY2MA

 run;

/* IDENTIFY UNIQUE MAREA VALUES IN PDI_ALL_MEASURES OUTPUT. */

 proc   Sort data=TEMP0 out=MAREA nodupkey;
 by     MAREA;
 run;

/* LOAD POPULATION FOR MAREA LEVEL AND YEAR IN PDI_ALL_CONTROL. */

 data QIPOP0;
    length FIPSTCO $5 SEXCAT POPCAT RACECAT 3 

           POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
           POP_2005 POP_2006 POP_2007 POP_2008 POP_2009 
           POP_2010 POP_2011 POP_2012 POP_2013 POP_2014
           POP_2015 POP_2016 POP_2017 POP_2018 POP_2019 
           POP_2020 POP_2021 POP_2022 POP_2023 POP 8;

    infile POPFILE missover firstobs=2;

   input FIPSTCO SEXCAT POPCAT RACECAT 

          POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
          POP_2005 POP_2006 POP_2007 POP_2008 POP_2009
          POP_2010 POP_2011 POP_2012 POP_2013 POP_2014
          POP_2015 POP_2016 POP_2017 POP_2018 POP_2019
          POP_2020 POP_2021 POP_2022 POP_2023;

    %CTY2MA

    POP = POP_&POPYEAR.;

    if POPCAT in (1,2,3,4);

 run;

 proc   Summary data=QIPOP0 nway ;           
 class  MAREA POPCAT SEXCAT RACECAT;
 var    POP;
 output out=QIPOP sum=;
 run;

 proc   Sort data=QIPOP;
 by     MAREA POPCAT SEXCAT RACECAT;
 run;

/* LIMIT POPULATION TOTALS TO MAREA CODES FOUND IN PDI_ALL_MEASURES OUTPUT. */

 data   QIPOP(keep=MAREA POPCAT SEXCAT RACECAT POP);
 merge  MAREA(in=X) QIPOP(in=Y);
 by     MAREA;

 if X and Y;

 run;

* --------------------------------------------------------------- *
 * --- PEDIATRIC QUALITY INDICATORS ADJUSTED RATES -------------- *
 * -------------------------------------------------------------- *
 * AREA-LEVEL INDICATOR DENOMINATORS ARE ADJUSTED BASED ON THE    *
 * COMBINATION OF COUNTY, AGE, SEX, AND RACE IN THE NUMERATOR.    *
 * THIS STEP ITERATES THROUGH THE OUTPUT FROM PDI_MEASURES FOR    *
 * EACH MEASURE AND REDUCES THE POPULATION SUM BY THE NUMERATOR   *
 * TOTAL. THE MOD3 MACRO ADJUSTS THE RESIDENTIAL POPULATION TOTAL *
 * BASED ON THE MEASURE RELEVANT POPULATION. ONLY VALID AREA      *
 * CODES ARE RETURNED. THE MOD3 INPUTS ARE:                       *
 * --- N - AREA MEASURE NUMBER                                --- *
 * --- PD - THE PEDIATRIC QUALITY INDICATOR NAME WITHOUT THE  --- *
 * ---      PREFIX (A)                                        --- *
 * -------------------------------------------------------------- ;

 %MACRO MOD3(N,PD);

 /* CREATE TEMPORARY TABLE WITH ALL DISCHARGES IN NUMERATOR FOR MEASURE N. */ 

 data   TEMP_2;
 set    OUTMSR.&OUTFILE_MEAS.(keep=KEY FIPSTCO T&PD. POPCAT SEXCAT RACECAT);

 if T&PD. in (1);
 if POPCAT in (1,2,3,4);

 %CTY2MA

 run;

/* SUM THE NUMERATOR 'T' FLAGS BY MAREA POPCAT SEXCAT RACECAT. */

 proc   Summary data=TEMP_2 NWAY;
 class  MAREA POPCAT SEXCAT RACECAT;
 var    T&PD.;
 output out=TEMP_3 N=TCOUNT;
 run;

 proc   Sort data=TEMP_3;
 by     MAREA POPCAT SEXCAT RACECAT;
 run;

/* REDUCE THE DENOMINATOR POPULATION BY THE SUM OF THE NUMERATOR COUNT. */

 data   TEMP_4(drop=TCOUNT N);
 merge  QIPOP(in=X keep=MAREA POPCAT SEXCAT RACECAT POP)
        TEMP_3(keep=MAREA POPCAT SEXCAT RACECAT TCOUNT);
 by     MAREA POPCAT SEXCAT RACECAT;

 if X;

 N = &N.;

 if POPCAT in (1) then do;
    if N = 14 then POP = POP * 0.60; /* AGE < 2 */
    if N = 15 then POP = .;          /* AGE < 6 */
    if N = 16 then POP = POP * 0.95; /* AGEDAY < 90 */
    if N = 18 then POP = POP * 0.95; /* AGEDAY < 90 */
    if N = 90 then POP = .;          /* AGE < 6 */
    if N = 91 then POP = .;          /* AGE < 6 */
    if N = 92 then POP = .;          /* AGE < 6 */
 end;
 else if POPCAT in (2) then do;
   if N = 15 then POP = POP * 0.80; /* AGE < 6 */
   if N = 90 then POP = POP * 0.80; /* AGE < 6 */
   if N = 91 then POP = POP * 0.80; /* AGE < 6 */
   if N = 92 then POP = POP * 0.80; /* AGE < 6 */
 end;

 if TCOUNT > 0 then PCOUNT = POP - TCOUNT;
 else PCOUNT = POP;

 if PCOUNT < 0 then PCOUNT = 0;

 if PCOUNT = 0 then delete;
 
 run;

 /* FOR NUMERATOR, RETAIN ONLY RECORDS WITH A VALID MAREA CODE. */

 data   TEMP_3(drop=POP);
 merge  TEMP_3(in=X keep=MAREA POPCAT SEXCAT RACECAT TCOUNT)
        QIPOP(keep=MAREA POPCAT SEXCAT RACECAT POP);
 by     MAREA POPCAT SEXCAT RACECAT;

 if X;

 if POP < 0 then PCOUNT = 0;
 else if TCOUNT > 0 then PCOUNT = TCOUNT;
 else PCOUNT = 0;

 if PCOUNT = 0 then delete;
 
 run;

 /* COMBINE THE NUMERATOR AND DENOMINATOR */

 data   TEMP1;
 set    TEMP_3(in=X) TEMP_4;

 if X then T&PD. = 1;
 else T&PD. = 0;

 run;

 data   TEMP1Y;
 set    TEMP1;
 ONE = 1;
 run;

 * ------------------------------------------------------------------ ;
 * --- AGGREGATE POPULATION COUNTS BY STRATIFIERS.                --- ;
 * --- ADJUST POPULATION OUTPUT AFTER ELIMINATING AREAS           --- ;  
 * --- WITHOUT A MEASURE DISCHARGE AND LIMITING TO MEASURE        --- ;
 * --- RELEVANT SUB-GROUPS.                                       --- ;
 * ------------------------------------------------------------------ ;

 proc   Summary data=TEMP1Y;
 class  MAREA POPCAT SEXCAT RACECAT;
 var    T&PD. ONE;
 output out=ADJ_&PD. SUM(T&PD. ONE)=T&PD. P&PD.;
 weight PCOUNT;
 run;

 data   ADJ_&PD.(keep=MAREA POPCAT SEXCAT RACECAT _TYPE_ T&PD. P&PD.);
 set    ADJ_&PD.;

 if _TYPE_ &TYPELVLA;

 run;

 proc Sort data=ADJ_&PD.;
     by MAREA POPCAT SEXCAT RACECAT;
 run; quit;

 proc   Datasets NOLIST;
 delete TEMP1 TEMP1Y TEMP_2 TEMP_3 TEMP_4;
 run;

 %MEND;

 %MOD3(14,APD14);
 %MOD3(15,APD15);
 %MOD3(16,APD16);
 %MOD3(18,APD18);
 %MOD3(90,APD90);
 %MOD3(91,APD91);
 %MOD3(92,APD92);

/* MERGE THE ADJUSTED DENOMINATOR AND NUMERATOR FOR AREA LEVEL PEDIATRIC QUALITY INDICATORS. */
 
data TEMP2Y;
  merge ADJ_APD14 ADJ_APD15 ADJ_APD16 ADJ_APD18 
        ADJ_APD90 ADJ_APD91 ADJ_APD92;
  by MAREA POPCAT  SEXCAT RACECAT;
run;

* ----------------------------------------------------------------- ;
* --- PEDIATRIC QUALITY INDICATOR (PDI) NAMING CONVENTION:      --- ;
* --- THE FIRST LETTER IDENTIFIES THE PEDIATRIC QUALITY         --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                        --- ;
* ---           (T) NUMERATOR ("TOP") - FROM PDI_ALL_MEASURES   --- ;
* ---           (P) DENOMINATOR ("POPULATION")                  --- ;
* ---           (A) ADJUSTED POPULATION                         --- ;
* ---           (O) OBSERVED RATES (T/P)                        --- ;
* --- THE SECOND LETTER IDENTIFIES THE INDICATOR AS AN AREA (A) --- ;
* --- LEVEL INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS      --- ;
* --- 'PD'. THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.       --- ;
* ----------------------------------------------------------------- ;

/* CALCULATE OBSERVED RATE AS SUM OF NUMERATOR / SUM OF ADJUSTED DENOMINATOR.*/

 data &OUTFILE_AREAOBS.;
 set TEMP2Y;

 array PPD2{7} PAPD14-PAPD16 PAPD18 PAPD90-PAPD92 ;
 array TPD{7}  TAPD14-TAPD16 TAPD18 TAPD90-TAPD92 ;
 array OPD{7}  OAPD14-OAPD16 OAPD18 OAPD90-OAPD92 ;

 do J = 1 to 7;
    if TPD{J} GT 0 and PPD2{J} GT 0 then OPD{J} = TPD{J} / PPD2{J};
    else if PPD2{J} GT 0 then OPD{J} = 0;
 end;
  

 %macro label_qis(qi_num=, qi_name=);
   label 
   TA&qi_num. = "&qi_name. (Numerator)"
   PA&qi_num. = "&qi_name. (Population)"
   OA&qi_num. = "&qi_name. (Observed rate)"
   ;
 %mend label_qis;

 %label_qis(qi_num=PD14, qi_name=PDI 14 Asthma Admission Rate);
 %label_qis(qi_num=PD15, qi_name=PDI 15 Diabetes Short-Term Complications Admission Rate);
 %label_qis(qi_num=PD16, qi_name=PDI 16 Gastroenteritis Admission Rate);
 %label_qis(qi_num=PD18, qi_name=PDI 18 Urinary Tract Infection Admission Rate);
 %label_qis(qi_num=PD90, qi_name=PDI 90 Pediatric Quality Overall Composite);
 %label_qis(qi_num=PD91, qi_name=PDI 91 Pediatric Quality Acute Composite);
 %label_qis(qi_num=PD92, qi_name=PDI 92 Pediatric Quality Chronic Composite);

 label
 _TYPE_ = 'Stratification Level'
 MAREA  = 'Metro Area Level'
 ;

 drop J;

 run;

 proc Sort data=&OUTFILE_AREAOBS. OUT=OUTAOBS.&OUTFILE_AREAOBS.;
 by MAREA POPCAT SEXCAT RACECAT;
 run;

proc Datasets NOLIST;
  delete MAREA QIPOP QIPOP0 TEMP0 TEMP2Y
         ADJ_APD14 ADJ_APD15 ADJ_APD16 ADJ_APD18 
         ADJ_APD90 ADJ_APD92 ;
run; quit;

 * ------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA OBSERVED OUTPUT FILE --- ;
 * ------------------------------------------------------- ;

 proc Contents data=OUTAOBS.&OUTFILE_AREAOBS. position;
 run;

 ***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

proc Means data=OUTAOBS.&OUTFILE_AREAOBS. (WHERE=(_TYPE_ in (8))) n nmiss min max sum nolabels;
   var TAPD14-TAPD16 TAPD18 TAPD90-TAPD92 ;
   title  'SUMMARY OF PEDIATRIC AREA-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=8';
run; quit;

proc Means data=OUTAOBS.&OUTFILE_AREAOBS. (WHERE=(_TYPE_ in (8))) n nmiss min max sum nolabels;
   var PAPD14-PAPD16 PAPD18 PAPD90-PAPD92;
   title  'SUMMARY OF PEDIATRIC AREA-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=8';
run; quit;

proc Means data=OUTAOBS.&OUTFILE_AREAOBS. (WHERE=(_TYPE_ in (8))) n nmiss min max mean nolabels;
   var OAPD14-OAPD16 OAPD18 OAPD90-OAPD92 ;
   title  'SUMMARY OF PEDIATRIC AREA-LEVEL OBSERVED INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=8';
run; quit;

 * -------------------------------------------------------------- ;
 * --- PRINT AREA OBSERVED MEANS FILE TO SAS OUTPUT          ---- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PD,TEXT);

 proc  PRINT data=OUTAOBS.&OUTFILE_AREAOBS. label SPLIT='*';
 var   MAREA POPCAT SEXCAT RACECAT TA&PD. PA&PD. OA&PD. ;
 label MAREA    = "Metro Area Level"
       POPCAT   = "Population Age Categories"
       SEXCAT   = "Sex Categories"
       RACECAT  = "Race Categories"
       TA&PD.   = "TA&PD.*(Numerator)"
       PA&PD.   = "PA&PD.*(Population)"
       OA&PD.   = "OA&PD.*(Observed rate)"
       ;
 format POPCAT POPCAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
        TA&PD. PA&PD. COMMA13.0
        OA&PD. 8.6
        ;
 title4 "Indicator &PD.: &TEXT";
 run;

 %MEND PRT;

 %PRT(PD14,Asthma Admission Rate);
 %PRT(PD15,Diabetes Short-Term Complications Admission Rate);
 %PRT(PD16,Gastroenteritis Admission Rate);
 %PRT(PD18,Urinary Tract Infection Admission Rate);

 %END;

 %MEND PRT2;

 %PRT2; 

 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS                          ---- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXT;
 
 %macro scale_rates;
   
   %IF &SCALE_RATES = 1 %THEN %DO;
      ARRAY RATES OAP:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*100000;	
	  end;
	%END;
	
 %mend scale_rates;

 %IF &TXTAOBS. = 1  %THEN %DO;

 data _NULL_;
 set OUTAOBS.&OUTFILE_AREAOBS.;
 %scale_rates;
 file PDTXTAOB lrecl=2000;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_AREAOBS data set created with the following CONTROL options:";
 put "&&MALEVL&MALEVL (MALEVL = &MALEVL)";
 put "Population year (POPYEAR) = &POPYEAR";
 put "&&Calibration_OE_to_ref_pop&Calibration_OE_to_ref_pop. (Calibration_OE_to_ref_pop = &Calibration_OE_to_ref_pop)";
 put "Output stratification includes TYPELVLA = &TYPELVLA";
 put "&&USE_SES&USE_SES (USE_SES = &USE_SES)"; 
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "MAREA"  "," "Age"  "," "Sex"  "," "Race"  "," "Type" ","
 "TAPD14" "," "TAPD15" "," "TAPD16" "," 
 "TAPD18" ","
 "TAPD90" "," "TAPD91" "," "TAPD92" ","
 "PAPD14" "," "PAPD15" "," "PAPD16" ","
 "PAPD18" ","
 "PAPD90" "," "PAPD91" "," "PAPD92" ","
 "OAPD14" "," "OAPD15" "," "OAPD16" ","
 "OAPD18" ","
 "OAPD90" "," "OAPD91" "," "OAPD92"
;
 end;

 put MAREA $5. "," POPCAT 3. "," SEXCAT 3. "," RACECAT 3.  "," _TYPE_ 2.  ","
 (TAPD14-TAPD16 TAPD18 TAPD90-TAPD92) (7.0 ",")
 ","
 (PAPD14-PAPD16 PAPD18 PAPD90-PAPD92) (13.0 ",")
 ","
 (OAPD14-OAPD16 OAPD18 OAPD90-OAPD92) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ;
 run;

 %END;

 %MEND TEXT;

 %TEXT;
