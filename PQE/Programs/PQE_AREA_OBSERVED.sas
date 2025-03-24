* ===================== PROGRAM: PQE_AREA_OBSERVED.SAS ===================== ;
*
*  TITLE: AREA LEVEL OBSERVED RATES FOR AHRQ PREVENTION QUALITY 
*         INDICATORS IN EMERGENCY DEPARTMENT SETTINGS (PQE)
*          
*  DESCRIPTION:
*         Calculate observed rates for PQE across stratifiers.
*         Output stratified by AREA, AGECAT, SEXCAT from 
*         population file and PQE_AREA_MEASURES.SAS output.
*         Variables created by this program are PAQExx and OAQExx.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*============================================================================ ;

 title2 'PQE_AREA_OBSERVED PROGRAM';
 title3 'AHRQ PREVENTION QUALITY INDICATORS IN ED SETTINGS (PQE): CALCULATE OBSERVED AREA RATES';

 * ---------------------------------------------------------------- ;   
 * --- POPULATION GROUPS FOR EACH QI BASED ON 18 5-YEAR AGE RANGES  ;
 * ---------------------------------------------------------------- ;
%LET POPCAT_AQE01 = 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18; /* 5+      */
%LET POPCAT_AQE02 = 9,10,11,12,13,14,15,16,17,18;               /* 40+     */
%LET POPCAT_AQE03 = 1,2,3,4,5,6,7,8,9,10,11,12,13;              /* 4m - 64 */
%LET POPCAT_AQE04 = 2,3,4,5,6,7,8;                              /* 5 - 39  */
%LET POPCAT_AQE05 = 5,6,7,8,9,10,11,12,13,14,15,16,17,18;       /* 18+     */

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR                               --- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE     --- ;
 * --- OUTPUT BASED ON AREAS IN PQE_AREA_MEASURES OUTPUT.       --- ;
 * ---------------------------------------------------------------- ;

/*MACRO TO ADJUST AREA AGGREGATION BASED ON MAREA VALUE IN PQE_AREA_CONTROL.*/

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

 data TEMP0;
 set  OUTMSR.&OUTFILE_MEAS.;

    * ------------------------------------------------- ;
    * --- Exclude any record not in one of the PQEs --- ;
    * ------------------------------------------------- ;
    IF MIN(OF EXCLUDE:) = 0 ;                                         
    
	* ------------------------------------------------- ;
    * --- Limit ED visits to patients who reside    --- ;
    * --- in the same state as the ED, residents    --- ;
    * --- of the hospital state.                    --- ;
    * ------------------------------------------------- ;
    IF RESIDENT EQ 1 ;
              
    * --------------------------------------------------- ;
    * --- Call macro to define geographic of interest --- ;
    * --------------------------------------------------- ;
    %CTY2MA
 run;       

/* IDENTIFY UNIQUE MAREA VALUES IN PQE_AREA_MEASURES OUTPUT. */

 proc  Sort data=TEMP0(keep=MAREA) out=MAREA nodupkey;
 	by    MAREA;
 run;

/* FOR COUNTY-LEVEL ANALYSIS, LOAD COUNTY-LEVEL POPULATION DATA.                      */
/* POPULATION IS DETERMINED BY MAREA LEVEL AND YEAR SPECIFIED IN PQE_AREA_CONTROL.SAS */

    DATA QIPOP0;
        LENGTH FIPSTCO $5 SEXCAT POPCAT RACECAT 3 
               POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
               POP_2005 POP_2006 POP_2007 POP_2008 POP_2009
               POP_2010 POP_2011 POP_2012 POP_2013 POP_2014 
			   POP_2015 POP_2016 POP_2017 POP_2018 POP_2019 
			   POP_2020 POP_2021 POP_2022 POP_2023 POP 8
               STATE $2.
        ;
    
        INFILE POPFILE MISSOVER FIRSTOBS=2;
    
		INPUT FIPSTCO SEXCAT POPCAT RACECAT 
			   POP_2000 POP_2001 POP_2002 POP_2003 POP_2004 
			   POP_2005 POP_2006 POP_2007 POP_2008 POP_2009 
			   POP_2010 POP_2011 POP_2012 POP_2013 POP_2014 
			   POP_2015 POP_2016 POP_2017 POP_2018 POP_2019
			   POP_2020 POP_2021 POP_2022 POP_2023;
    
        %CTY2MA
    
        POP = POP_&POPYEAR.; 

        * --- For PQE 03 Acute ACSC, exclude age 3 month or younger (0-3 month) --- ;
        * --- assume uniform distribution in 0-4 year (0-59 month)              --- ;
        IF POPCAT=1 THEN POPX = ROUND(POP * 0.95);
        ELSE POPX = POP;

        STATE = FIPSTATE(INPUT(SUBSTR(FIPSTCO,1,2),2.0)) ;

       

    RUN;
/* END OF COUNTY LEVEL POPULATION */

 proc   Summary data=QIPOP0 nway;
 class  MAREA STATE POPCAT SEXCAT;
 var    POP POPX;
 output out=QIPOP sum=;
 run;

 proc   Sort data=QIPOP;
 by     MAREA STATE POPCAT SEXCAT;
 run;


/* LIMIT POPULATION TOTALS TO MAREA CODES FOUND IN PQE_AREA_MEASURES OUTPUT. */

data   QIPOP(keep=MAREA STATE POPCAT SEXCAT POP POPX);
 merge  MAREA(in=X) QIPOP(in=Y);
 by     MAREA;

 if X and Y;

run;

 * ---------------------------------------------------------------- ;
 * - PREVENTION QUALITY INDICATORS IN ED SETTINGS ADJUSTED RATES  - ;
 * ---------------------------------------------------------------- ;
 * AREA-LEVEL INDICATOR DENOMINATORS ARE ADJUSTED BASED ON THE  --- ;
 * COMBINATION OF COUNTY, AGE, SEX IN THE NUMERATOR.            --- ;
 * THE MOD3 MACRO ITERATES THROUGH EACH MEASURE IN THE          --- ;
 * PQE_AREA_MEASURES OUTPUT AND REDUCES THE AREA POPULATION BY  --- ;
 * THE NUMERATOR TOTAL. THE AREA POPULATION TOTALS ARE THEN     --- ;
 * ADJUSTED BASED ON THE MEASURE RELEVANT POPULATION. ONLY VALID--- ;
 * AREA CODES ARE RETURNED. THE MOD3 MACRO INPUTS ARE:          --- ;
 * --- N - AREA MEASURE NUMBER                                  --- ;
 * --- PQ - THE ED PREVENTION QUALITY INDICATOR NAME WITH THE   --- ;
 *          PREFIX (A)                                          --- ;
 * ---------------------------------------------------------------- ;

%MACRO MOD3(N,PQ);
                                                                   
 /* CREATE TEMPORARY TABLE WITH ALL DISCHARGES IN NUMERATOR FOR MEASURE N. */
 data TEMP_2;
     set TEMP0 (KEEP=KEY FIPSTCO T&PQ. POPCAT SEXCAT);                     
     if T&PQ. IN (1);                  
                           
	%CTY2MA
 run;
    
 /* SUM THE NUMERATOR 'T' FLAGS BY MAREA POPCAT SEXCAT. */
 proc   Summary data=TEMP_2 NWAY;
 class  MAREA POPCAT SEXCAT;
 var    T&PQ.;
 output out=TEMP_3 N=TCOUNT;
 run;

 proc   Sort data=TEMP_3;
 by     MAREA POPCAT SEXCAT;
 run;
    
 /* REDUCE THE DENOMINATOR POPULATION BY THE SUM OF THE NUMERATOR COUNT. */
 data   TEMP_4(drop=TCOUNT);
 merge  %IF &PQ.=AQE03 %THEN %DO;
        QIPOP(in=X keep=MAREA STATE POPCAT SEXCAT POPX rename=(POPX=POP)) 
        %END;
        %ELSE %DO;
        QIPOP(in=X keep=MAREA STATE POPCAT SEXCAT POP) 
        %END;
        TEMP_3(keep=MAREA POPCAT SEXCAT TCOUNT);
 by     MAREA POPCAT SEXCAT;

 if X;

 if TCOUNT > 0 then PCOUNT = POP - TCOUNT;
 else PCOUNT = POP;

 if PCOUNT < 0 then PCOUNT = 0;

 if PCOUNT = 0 then delete;

 run;
  
 /* FOR NUMERATOR, RETAIN ONLY RECORDS WITH A VALID MAREA CODE. */
 data   TEMP_3(drop=POP);
 merge  TEMP_3(in=X keep=MAREA POPCAT SEXCAT TCOUNT)
        QIPOP(keep=MAREA STATE POPCAT SEXCAT POP);
 by     MAREA POPCAT SEXCAT;

 if X;

 if POP <= 0 then PCOUNT = 0;
 else if TCOUNT > 0 then PCOUNT = TCOUNT;
 else PCOUNT = 0;

 if PCOUNT = 0 then delete;

 run;
    
 /* COMBINE THE NUMERATOR AND DENOMINATOR */
 data   TEMP1;
 set    TEMP_3(in=X) TEMP_4;

 if POPCAT IN (&&POPCAT_&PQ.);

 if X then T&PQ. = 1;
 else T&PQ. = 0;

 ATTRIB ONE LENGTH=3 LABEL='DUMMY ONE';                      
 ONE = 1;   
 
 run;
 
 data TEMP1Y;
   set TEMP1;
    %IF &PQ. EQ AQE05 %THEN %DO ;
        IF INDEX("&StatesWithVisitlink_", STRIP(STATE)) > 0 ;
    %END ;
 run;

 * ------------------------------------------------------------------ ;
 * --- AGGREGATE POPULATION COUNTS BY STRATIFIERS.                --- ;
 * --- ADJUST POPULATION OUTPUT AFTER ELIMINATING AREAS           --- ;  
 * --- WITHOUT A MEASURE DISCHARGE AND LIMITING TO MEASURE        --- ;
 * --- RELEVANT SUB-GROUPS.                                       --- ;
 * ------------------------------------------------------------------ ;

 proc   Summary data=TEMP1Y;
 class  MAREA POPCAT SEXCAT;
 var    T&PQ. ONE;
 output out=ADJ_&PQ. sum(T&PQ. ONE)=T&PQ. P&PQ.;
 weight PCOUNT;
 run;

 data ADJ_&PQ. (keep = MAREA POPCAT SEXCAT T&PQ. P&PQ. _TYPE_);
    set ADJ_&PQ.;
    if _TYPE_ in (&TYPELVLA);
 run;

 proc Sort data=ADJ_&PQ.;
   by MAREA POPCAT SEXCAT;
 run; quit;

 proc   Datasets nolist;
 delete TEMP1 TEMP1Y TEMP_2 TEMP_3 TEMP_4;
 run;

%MEND;

%MOD3(01,AQE01);
%MOD3(02,AQE02);
%MOD3(03,AQE03);
%MOD3(04,AQE04);
%MOD3(05,AQE05);

 /* MERGE THE ADJUSTED DENOMINATOR AND NUMERATOR FOR AREA LEVEL PREVENTION QUALITY INDICATORS. */
data TEMP2Y;
  merge ADJ_AQE01-ADJ_AQE05;
  by MAREA POPCAT SEXCAT;
run;


* ------------------------------------------------------------------ ;
* --- PREVENTION QUALITY INDICATORS IN ED SETTINGS (PQE)         --- ;
* --- NAMING CONVENTION:                                         --- ;
* --- THE FIRST LETTER IDENTIFIES THE PREVENTION QUALITY         --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                         --- ;
* ---           (T) NUMERATOR ("TOP") - FROM PQE_AREA_MEASURES   --- ;
* ---           (P) DENOMINATOR ("POPULATION")                   --- ;
* ---           (O) OBSERVED RATES (T/P)                         --- ;
* --- THE SECOND LETTER IDENTIFIES THE INDICATOR AS AN AREA (A)  --- ;
* --- LEVEL INDICATOR.  THE NEXT FOUR CHARACTERS ARE ALWAYS      --- ;
* --- 'QE'. THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.        --- ;
* ------------------------------------------------------------------ ;

/* CALCULATE OBSERVED RATE AS SUM OF NUMERATOR / SUM OF ADJUSTED DENOMINATOR.*/

data &OUTFILE_AREAOBS.;
 set TEMP2Y;

 ARRAY PAQE{5} PAQE01 PAQE02 PAQE03 PAQE04 PAQE05;
 ARRAY TAQE{5} TAQE01 TAQE02 TAQE03 TAQE04 TAQE05;
 ARRAY OAQE{5} OAQE01 OAQE02 OAQE03 OAQE04 OAQE05;

 do J = 1 to 5;
    if TAQE{J} GT 0 and PAQE{J} GT 0 then OAQE{J} = TAQE{J} / PAQE{J};
    else if PAQE{J} GT 0 then OAQE{J} = 0 ;
 end;

 %macro label_qis(qi_num=, qi_name=);
   label
   TA&qi_num. = "&qi_name. (NUMERATOR)"
   PA&qi_num. = "&qi_name. (POPULATION)"
   OA&qi_num. = "&qi_name. (OBSERVED RATE)"
   ;
 %mend label_qis;

 %label_qis(qi_num=QE01, qi_name=PQE 01 Visits for Non-Traumatic Dental Conditions in ED);
 %label_qis(qi_num=QE02, qi_name=PQE 02 Visits for Chronic Ambulatory Care Sensitive Conditions in ED);
 %label_qis(qi_num=QE03, qi_name=PQE 03 Visits for Acute Ambulatory Care Sensitive Conditions in ED); 
 %label_qis(qi_num=QE04, qi_name=PQE 04 Visits for Asthma in ED);
 %label_qis(qi_num=QE05, qi_name=PQE 05 Visits for Back Pain in ED);
 label
 _TYPE_ = 'Stratification Level'
 MAREA  = 'Metro Area Level'
 ;

 DROP J;

 run;

 proc Sort data=&OUTFILE_AREAOBS. out=OUTAOBS.&OUTFILE_AREAOBS.;
 by MAREA POPCAT SEXCAT;
 run;


proc Datasets nolist;
  delete MAREA QIPOP QIPOP0 TEMP0 TEMP2Y
         ADJ_QE01 ADJ_QE02 ADJ_QE03 ADJ_QE04 ADJ_QE05 
		;
run; quit;

 * ------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA OBSERVED OUTPUT FILE --- ;
 * ------------------------------------------------------- ;
 
 proc contents data=OUTAOBS.&OUTFILE_AREAOBS. position;
 run;

 ***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

proc Means data = OUTAOBS.&OUTFILE_AREAOBS.(where=(_TYPE_ in (4))) n nmiss min max sum nolabels;
     var TAQE01 TAQE02 TAQE03 TAQE04 TAQE05;
     title  "ED PREVENTION QUALITY AREA-LEVEL INDICATOR OVERALL NUMERATOR WHEN _TYPE_ =4 ";
run; quit;

proc Means data = OUTAOBS.&OUTFILE_AREAOBS. (where=(_TYPE_ in (4))) n nmiss min max sum nolabels;
     var PAQE01 PAQE02 PAQE03 PAQE04 PAQE05;
     title  "ED PREVENTION QUALITY AREA-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_ =4";
run; quit;

proc Means data = OUTAOBS.&OUTFILE_AREAOBS. (where=(_TYPE_ in (4))) n nmiss min max mean nolabels;
     var OAQE01 OAQE02 OAQE03 OAQE04 OAQE05;
     title  "ED PREVENTION QUALITY AREA-LEVEL INDICATOR AVERAGE OBSERVED RATE (MEAN) WHEN _TYPE_ =4";
run; quit;

 * -------------------------------------------------------------- ;
 * --- PRINT AREA OBSERVED MEANS FILE                        ---- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PQ,TEXT);
 proc  PRINT data= OUTAOBS.&OUTFILE_AREAOBS. label SPLIT='*';
 var   MAREA POPCAT SEXCAT TAQE&PQ. PAQE&PQ. OAQE&PQ. ;
 label MAREA    = "Metro Area Level"
       POPCAT   = "Population Age Categories"
       SEXCAT   = "Sex Categories"
       TAQE&PQ. = "TAQE&PQ.*(Numerator)"
       PAQE&PQ. = "PAQE&PQ.*(Population)"
       OAQE&PQ. = "OAQE&PQ.*(Observed rate)"     
       ;

 format POPCAT POPCAT.   
        SEXCAT SEXCAT.
        TAQE&PQ. PAQE&PQ. COMMA13.0
        OAQE&PQ.  8.6;

 title4 "Indicator &PQ.: &TEXT";

 run;

 %MEND PRT;

 %PRT(01,Visits for Non-Traumatic Dental Conditions in ED);
 %PRT(02,Visits for Chronic Ambulatory Care Sensitive Conditions in ED);
 %PRT(03,Visits for Acute Ambulatory Care Sensitive Conditions in ED); 
 %PRT(04,Visits for Asthma in ED);
 %PRT(05,Visits for Back Pain in ED);

 %END;

 %MEND PRT2 ;

 %PRT2;


 
 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS                           --- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXT;
 
 %macro scale_rates;
   
   %IF &SCALE_RATES = 1 %THEN %DO;
      ARRAY RATES OAQE:;
      do over RATES;
        if not missing(RATES) then RATES = RATES*100000;	
	  end;
	%END;
	
 %mend scale_rates;

  %IF &TXTAOBS. = 1  %THEN %DO;

 data _NULL_;
 set OUTAOBS.&OUTFILE_AREAOBS.;
 %scale_rates;
 file QETXTAOB lrecl=2000;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_AREAOBS data set created with the following CONTROL options:";
 put "&&MALEVL&MALEVL (MALEVL = &MALEVL)";
 put "Population year (POPYEAR) = &POPYEAR";
 put "&&Calibration_OE_to_ref_pop&Calibration_OE_to_ref_pop. (Calibration_OE_to_ref_pop = &Calibration_OE_to_ref_pop)";
 put "States with valid revisit variables (StatesWithVisitlink_) = &StatesWithVisitlink_";
 put "Output stratification includes TYPELVLA = &TYPELVLA";
 put "&&USE_SES&USE_SES (USE_SES = &USE_SES)"; 
 put "Number of diagnoses evaluated = &NDX";
 put "Review the CONTROL program for more information about these options.";
 put ;																							   
 put "MAREA" "," "Age" "," "Sex" "," "Type" ","
 "TAQE01" "," "TAQE02" "," "TAQE03" "," "TAQE04" "," "TAQE05" ","
 "PAQE01" "," "PAQE02" "," "PAQE03" "," "PAQE04" "," "PAQE05" ","
 "OAQE01" "," "OAQE02" "," "OAQE03" "," "OAQE04" "," "OAQE05" ;
 
 end;
 
 put MAREA  $5. "," POPCAT 3. "," SEXCAT 3. "," _TYPE_ 2.  ","
 (TAQE01 TAQE02 TAQE03 TAQE04 TAQE05) (7.0 ",")
  ","
 (PAQE01 PAQE02 PAQE03 PAQE04 PAQE05) (13.0 ",")
 ","
 (OAQE01 OAQE02 OAQE03 OAQE04 OAQE05) %if &SCALE_RATES = 1 %then (12.2 ","); %else (12.10 ",");
 ;
 run;

 %END;

 %MEND TEXT;

 %TEXT;

