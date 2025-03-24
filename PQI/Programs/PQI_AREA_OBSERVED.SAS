* ===================== PROGRAM: PQI_AREA_OBSERVED.SAS ===================== ;
*
*  TITLE: AREA LEVEL OBSERVED RATES FOR AHRQ PREVENTION QUALITY INDICATORS 
*          
*  DESCRIPTION:
*         Calculate observed rates for
*         Prevention Quality Indicators across stratifiers.
*         Output stratified by AREA, AGECAT, SEXCAT and RACECAT from 
*         population file and PQI_AREA_MEASURES.SAS output.
*         Variables created by this program are PAPQxx and OAPQxx.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*============================================================================ ;

 title2 'PROGRAM PQI_AREA_OBSERVED';
 title3 'AHRQ PREVENTION QUALITY INDICATORS: CALCULATE ADJUSTED AREA RATES';

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR                               --- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE     --- ;
 * --- OUTPUT BASED ON AREAS IN PQI_AREA_MEASURES OUTPUT.       --- ;
 * ---------------------------------------------------------------- ;

/*MACRO TO ADJUST AREA AGGREGATION BASED ON MAREA VALUE IN PQI_AREA_CONTROL.*/

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

/* IDENTIFY UNIQUE MAREA VALUES IN PQI_AREA_MEASURES OUTPUT. */

 proc  Sort data=TEMP0 out=MAREA nodupkey;
 by    MAREA;
 run;
 
/* LOAD POPULATION FOR MAREA LEVEL AND YEAR IN PQI_AREA_CONTROL. */

 data QIPOP0;
    length FIPSTCO $5 SEXCAT POPCAT AGECAT RACECAT 3 
            
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

    if POPCAT in (1,2,3,4)            then AGECAT = 0;
    else if POPCAT in (5,6,7,8)       then AGECAT = 1;
    else if POPCAT in (9,10,11,12,13) then AGECAT = 2;
    else if POPCAT in (14,15)         then AGECAT = 3;
    else                                   AGECAT = 4;

 run;

 proc   Summary data=QIPOP0 nway;
 class  MAREA POPCAT AGECAT SEXCAT RACECAT;
 var    POP;
 output out=QIPOP sum=;
 run;

 proc   Sort data=QIPOP;
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;
 run;

/* LIMIT POPULATION TOTALS TO MAREA CODES FOUND IN PQI_AREA_MEASURES OUTPUT. */

 data   QIPOP(keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 merge  MAREA(in=X) QIPOP(in=Y);
 by     MAREA;

 if X and Y;

 run;

 * -------------------------------------------------------------- ;
 * --- PREVENTION QUALITY INDICATORS ADJUSTED RATES ------------- ;
 * -------------------------------------------------------------- ;
 * AREA-LEVEL INDICATOR DENOMINATORS ARE ADJUSTED BASED ON THE    *
 * COMBINATION OF COUNTY, AGE, SEX, AND RACE IN THE NUMERATOR.    *
 * THE MOD3 MACRO ITERATES THROUGH EACH MEASURE IN THE            *
 * PQI_AREA_MEASURES OUTPUT AND REDUCES THE AREA POPULATION BY THE*
 * NUMERATOR TOTAL. THE AREA POPULATION TOTALS ARE THEN ADJUSTED  *
 * BASED ON THE MEASURE RELEVANT POPULATION. ONLY VALID AREA      *
 * CODES ARE RETURNED. THE MOD3 MACRO INPUTS ARE:                 *
 * --- N -  AREA MEASURE NUMBER                               --- *
 * --- PQ - THE PREVENTION QUALITY INDICATOR NAME WITHOUT THE --- *
 *          PREFIX (A)                                        --- ;
 * -------------------------------------------------------------- ;

 %MACRO MOD3(N,PQ);

 /* CREATE TEMPORARY TABLE WITH ALL DISCHARGES IN NUMERATOR FOR MEASURE N. */ 

 data   TEMP_2;
 set    OUTMSR.&OUTFILE_MEAS.(keep=KEY FIPSTCO T&PQ. POPCAT AGECAT SEXCAT RACECAT);

 if T&PQ. in (1);

 %CTY2MA

 run;

/* SUM THE NUMERATOR 'T' FLAGS BY MAREA POPCAT AGECAT SEXCAT RACECAT. */

 proc   Summary data=TEMP_2 NWAY;
 class  MAREA POPCAT AGECAT SEXCAT RACECAT;
 var    T&PQ.;
 output out=TEMP_3 N=TCOUNT;
 run;

 proc   Sort data=TEMP_3;
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;
 run;

 /* REDUCE THE DENOMINATOR POPULATION BY THE SUM OF THE NUMERATOR COUNT. */

 data   TEMP_4(drop=TCOUNT);
 merge  QIPOP(in=X keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP) 
        TEMP_3(keep=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT);
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;

 if X;

 if TCOUNT > 0 then PCOUNT = POP - TCOUNT;
 else PCOUNT = POP;

 if PCOUNT < 0 then PCOUNT = 0;

 if AGECAT in (0) then PCOUNT = 0;

 N = &N.;

 if N in (5) and AGECAT in (1) then PCOUNT = 0;
 if N in (15) and AGECAT in (2,3,4) then PCOUNT = 0;


 if PCOUNT = 0 then delete;

 run;

 /* FOR NUMERATOR, RETAIN ONLY RECORDS WITH A VALID MAREA CODE. */

 data   TEMP_3(drop=POP);
 merge  TEMP_3(in=X keep=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT)
        QIPOP(keep=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 by     MAREA POPCAT AGECAT SEXCAT RACECAT;

 if X;

 if POP < 0 then PCOUNT = 0;
 else if TCOUNT > 0 then PCOUNT = TCOUNT;
 else PCOUNT = 0;

 if PCOUNT = 0 then delete;

 run;

 /* COMBINE THE NUMERATOR AND DENOMINATOR */

 data   TEMP1;
 set    TEMP_3(in=X) TEMP_4;

 if X then T&PQ. = 1;
 else T&PQ. = 0;

 run;

 data TEMP1Y;
   set TEMP1;
   ONE = 1;
 run;

 
 * ------------------------------------------------------------------ ;
 * --- AGGREGATE POPULATION COUNTS BY STRATIFIERS.                --- ;
 * --- ADJUST POPULATION OUTPUT AFTER ELIMINATING AREAS           --- ;  
 * --- WITHOUT A MEASURE DISCHARGE AND LIMITING TO MEASURE        --- ;
 * --- RELEVANT SUB-GROUPS.                                       --- ;
 * ------------------------------------------------------------------ ;

 proc   Summary data=TEMP1Y;
 class  MAREA AGECAT SEXCAT RACECAT;
 var    T&PQ. ONE;
 output out=ADJ_&PQ. sum(T&PQ. ONE)=T&PQ. P&PQ.;
 weight PCOUNT;
 run;

 data ADJ_&PQ.;
    set ADJ_&PQ.;
    if _TYPE_ &TYPELVLA;
    keep MAREA AGECAT SEXCAT RACECAT T&PQ. P&PQ. _TYPE_;
 run;

 proc Sort data=ADJ_&PQ.;
   by MAREA AGECAT SEXCAT RACECAT;
 run; quit;

 proc   Datasets nolist;
 delete TEMP1 TEMP1Y TEMP_2 TEMP_3 TEMP_4;
 run;

 %MEND;

 %MOD3(1,APQ01);
 %MOD3(3,APQ03);
 %MOD3(5,APQ05);
 %MOD3(7,APQ07);
 %MOD3(8,APQ08);
 %MOD3(11,APQ11);
 %MOD3(12,APQ12);
 %MOD3(14,APQ14);
 %MOD3(15,APQ15);
 %MOD3(16,APQ16);
 %MOD3(90,APQ90);
 %MOD3(91,APQ91);
 %MOD3(92,APQ92);
 %MOD3(93,APQ93);

 /* MERGE THE ADJUSTED DENOMINATOR AND NUMERATOR FOR AREA LEVEL PREVENTION QUALITY INDICATORS. */

data TEMP2Y;
  merge ADJ_APQ01  ADJ_APQ03 ADJ_APQ05 ADJ_APQ07 ADJ_APQ08 
        ADJ_APQ11 ADJ_APQ12 ADJ_APQ14 ADJ_APQ15 ADJ_APQ16 ADJ_APQ90 
        ADJ_APQ91 ADJ_APQ92 ADJ_APQ93;
  by MAREA AGECAT SEXCAT RACECAT;
run;

* ----------------------------------------------------------------- ;
* --- PREVENTION QUALITY INDICATOR (PQI) NAMING CONVENTION:     --- ;
* --- THE FIRST LETTER IDENTIFIES THE PREVENTION QUALITY        --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                        --- ;
* ---           (T) NUMERATOR ("TOP") - FROM PQI_AREA_MEASURES  --- ;
* ---           (P) DENOMINATOR ("POPULATION")                  --- ;
* ---           (A) ADJUSTED POPULATION                         --- ;
* ---           (O) OBSERVED RATES (T/P)                        --- ;
* --- THE SECOND LETTER IDENTIFIES THE INDICATOR AS AN AREA (A) --- ;
* --- LEVEL INDICATOR.  THE NEXT TWO CHARACTERS ARE ALWAYS      --- ;
* --- 'PQ'. THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.       --- ;
* ----------------------------------------------------------------- ;

/* CALCULATE OBSERVED RATE AS SUM OF NUMERATOR / SUM OF ADJUSTED DENOMINATOR.*/

data &OUTFILE_AREAOBS.;
 set TEMP2Y;

 ARRAY PPQ2{14} PAPQ01 PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ11 PAPQ12 PAPQ14-PAPQ16 
                PAPQ90-PAPQ93;
 ARRAY TPQ{14} TAPQ01 TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ11 TAPQ12 TAPQ14-TAPQ16
               TAPQ90-TAPQ93;
 ARRAY OPQ{14} OAPQ01 OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ11 OAPQ12 OAPQ14-OAPQ16 
               OAPQ90-OAPQ93;

 do J = 1 to 14;
    if TPQ{J} GT 0 and PPQ2{J} GT 0 then OPQ{J} = TPQ{J} / PPQ2{J};
    else if PPQ2{J} GT 0 then OPQ{J} = 0 ;
 end;

 %macro label_qis(qi_num=, qi_name=);
   label
   TA&qi_num. = "&qi_name. (Numerator)"
   PA&qi_num. = "&qi_name. (Population)"
   OA&qi_num. = "&qi_name. (Observed rate)"
   ;
 %mend label_qis;

 %label_qis(qi_num=PQ01, qi_name=PQI 01 Diabetes Short-Term Complications Admission Rate);
 %label_qis(qi_num=PQ03, qi_name=PQI 03 Diabetes Long-Term Complications Admission Rate);
 %label_qis(qi_num=PQ05, qi_name=PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate);
 %label_qis(qi_num=PQ07, qi_name=PQI 07 Hypertension Admission Rate);
 %label_qis(qi_num=PQ08, qi_name=PQI 08 Heart Failure Admission Rate);
 %label_qis(qi_num=PQ11, qi_name=PQI 11 Community-Acquired Pneumonia Admission Rate);
 %label_qis(qi_num=PQ12, qi_name=PQI 12 Urinary Tract Infection Admission Rate);
 %label_qis(qi_num=PQ14, qi_name=PQI 14 Uncontrolled Diabetes Admission Rate);
 %label_qis(qi_num=PQ15, qi_name=PQI 15 Asthma in Younger Adults Admission Rate);
 %label_qis(qi_num=PQ16, qi_name=PQI 16 Lower-Extremity Amputation Among Patients with Diabetes Rate);
 %label_qis(qi_num=PQ90, qi_name=PQI 90 Prevention Quality Overall Composite);
 %label_qis(qi_num=PQ91, qi_name=PQI 91 Prevention Quality Acute Composite);
 %label_qis(qi_num=PQ92, qi_name=PQI 92 Prevention Quality Chronic Composite);
 %label_qis(qi_num=PQ93, qi_name=PQI 93 Prevention Quality Diabetes Composite);

 label
 _TYPE_ = 'Stratification Level'
 MAREA  = 'Metro Area Level'
 ;

 drop J;

 run;

 proc Sort data=&OUTFILE_AREAOBS. out=OUTAOBS.&OUTFILE_AREAOBS.;
 by MAREA AGECAT SEXCAT RACECAT;
 run;

proc Datasets nolist;
  delete MAREA QIPOP QIPOP0 TEMP0 TEMP2Y
         ADJ_APQ01 ADJ_APQ03 ADJ_APQ05 ADJ_APQ07 ADJ_APQ08 
         ADJ_APQ11 ADJ_APQ12 ADJ_APQ14 ADJ_APQ15 ADJ_APQ16 ADJ_APQ90
         ADJ_APQ91 ADJ_APQ92 ADJ_APQ93;
run; quit;

 * ------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA OBSERVED OUTPUT FILE --- ;
 * ------------------------------------------------------- ;

 proc Contents data=OUTAOBS.&OUTFILE_AREAOBS. position;
 run;

 ***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

proc Means data = OUTAOBS.&OUTFILE_AREAOBS.(where=(_TYPE_ in (8))) n nmiss min max sum nolabels;
     var TAPQ01 TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ11-TAPQ12 TAPQ14-TAPQ16 TAPQ90-TAPQ93;
     title  "PREVENTION QUALITY AREA-LEVEL INDICATOR OVERALL NUMERATOR WHEN _TYPE_ =8 ";
run; quit;

proc Means data = OUTAOBS.&OUTFILE_AREAOBS. (where=(_TYPE_ in (8))) n nmiss min max sum nolabels;
     var PAPQ01 PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ11-PAPQ12 PAPQ14-PAPQ16 PAPQ90-PAPQ93;
     title  "PREVENTION QUALITY AREA-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_ =8";
run; quit;

proc Means data = OUTAOBS.&OUTFILE_AREAOBS. (where=(_TYPE_ in (8))) n nmiss min max mean nolabels;
     var OAPQ01 OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ11-OAPQ12 OAPQ14-OAPQ16 OAPQ90-OAPQ93;
     title  "PREVENTION QUALITY AREA-LEVEL INDICATOR AVERAGE OBSERVED RATE (MEAN) WHEN _TYPE_ =8";
run; quit;

 * -------------------------------------------------------------- ;
 * --- PRINT AREA OBSERVED MEANS FILE TO SAS OUTPUT          ---- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PQ,TEXT);

 proc  PRINT data=OUTAOBS.&OUTFILE_AREAOBS. label SPLIT='*';
 var   MAREA AGECAT SEXCAT RACECAT TAPQ&PQ. PAPQ&PQ. OAPQ&PQ. ;
 label MAREA   = "Metro Area Level"
       AGECAT  = "Age Categories"
       SEXCAT  = "Sex Categories"
       RACECAT = "Race Categories"
       TAPQ&PQ.   = "TAPQ&PQ.*(Numerator)"
       PAPQ&PQ.   = "PAPQ&PQ.*(Population)"
       OAPQ&PQ.   = "OAPQ&PQ.*(Observed rate)"
       ;
 FORMAT AGECAT AGECAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
      TAPQ&PQ. PAPQ&PQ. COMMA13.0
      OAPQ&PQ. 8.6
        ;
 title4 "Indicator &PQ.: &TEXT";
 run;

 %MEND PRT;

 %PRT(01,Diabetes Short-Term Complications Admission Rate);
 %PRT(03,Diabetes Long-Term Complications Admission Rate);
 %PRT(05,Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate);
 %PRT(07,Hypertension Admission Rate);
 %PRT(08,Heart Failure Admission Rate);
 %PRT(11,Community-Acquired Pneumonia Admission Rate);
 %PRT(12,Urinary Tract Infection Admission Rate);
 %PRT(14,Uncontrolled Diabetes Admission Rate);
 %PRT(15,Asthma in Younger Adults Admission Rate);
 %PRT(16,Lower-Extremity Amputation Among Patients with Diabetes Rate);
 %PRT(90,Prevention Quality Overall Composite);
 %PRT(91,Prevention Quality Acute Composite);
 %PRT(92,Prevention Quality Chronic Composite);
 %PRT(93,Prevention Quality Diabetes Composite);

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
 file PQTXTAOB lrecl=1000;
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
 put "MAREA" "," "Age" "," "Sex" "," "Race" "," "Type" ","
 "TAPQ01" ","   "TAPQ03" "," 
 "TAPQ05" "," "TAPQ07" "," "TAPQ08" ","
 "TAPQ11" "," "TAPQ12" "," 
 "TAPQ14" "," "TAPQ15" "," "TAPQ16" ","
 "TAPQ90" "," "TAPQ91" "," "TAPQ92" "," "TAPQ93" ","
 "PAPQ01" ","   "PAPQ03" "," 
 "PAPQ05" "," "PAPQ07" "," "PAPQ08" ","
 "PAPQ11" "," "PAPQ12" "," 
 "PAPQ14" "," "PAPQ15" "," "PAPQ16" ","
 "PAPQ90" "," "PAPQ91" "," "PAPQ92" "," "PAPQ93" ","
 "OAPQ01" ","   "OAPQ03" "," 
 "OAPQ05" "," "OAPQ07" "," "OAPQ08" ","
 "OAPQ11" "," "OAPQ12" "," 
 "OAPQ14" "," "OAPQ15" "," "OAPQ16" ","
 "OAPQ90" "," "OAPQ91" "," "OAPQ92" "," "OAPQ93";
 
 end;

 put MAREA $5. "," AGECAT 3. "," SEXCAT 3. "," RACECAT 3. "," _TYPE_ 2. ","
 (TAPQ01 TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ11 TAPQ12 TAPQ14-TAPQ16 TAPQ90-TAPQ93) (7.0 ",")
 ","
 (PAPQ01 PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ11 PAPQ12 PAPQ14-PAPQ16 PAPQ90-PAPQ93) (13.0 ",") 
 ","
 (OAPQ01 OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ11 OAPQ12 OAPQ14-OAPQ16 OAPQ90-OAPQ93) 
 %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ;
 run;

 %END;

 %MEND TEXT;

 %TEXT;
