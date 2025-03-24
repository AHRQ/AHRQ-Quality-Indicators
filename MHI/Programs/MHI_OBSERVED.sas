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
*  VERSION: SAS Beta version of MHI v2024
*  RELEASE DATE: SEPTEMBER 2024
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

 proc Summary data=OUTMSR.&OUTFILE_MEAS.;
  class &CUSTOM_STRATUM. PAYCAT YEAR HOSPST POVCAT RACECAT; ways 0 1;
  var  TAMH01 TAMH02 TAMH03;
  output out=&OUTFILE_AREAOBS.
        sum(TAMH01 TAMH02 TAMH03) = TAMH01 TAMH02 TAMH03
        n  (TAMH01 TAMH02 TAMH03) = PAMH01 PAMH02 PAMH03
        mean(TAMH01 TAMH02 TAMH03)= OAMH01 OAMH02 OAMH03;
 run;
 
 proc Sort data=&OUTFILE_AREAOBS.;
  by &CUSTOM_STRATUM. PAYCAT YEAR HOSPST POVCAT RACECAT;
 run;
 

 data OUTAOBS.&OUTFILE_AREAOBS.;
   set &OUTFILE_AREAOBS.;

     array PAMH PAMH01 PAMH02 PAMH03;

     do over PAMH;
        if PAMH eq 0 then PAMH = .;
     end;

     array OAMH OAMH01 OAMH02 OAMH03;

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

    %label_qis(qi_num=MH01,qi_name=%quote(Severe Maternal Morbidity Rate (20 Indicators)));
    %label_qis(qi_num=MH02,qi_name=%quote(Severe Maternal Morbidity (20 Indicators) Plus In-Hospital Mortality Rate));
    %label_qis(qi_num=MH03,qi_name=%quote(Refined Severe Maternal Morbidity (20 Indicators) Plus In-Hospital Mortality Rate, Beta));
    label _TYPE_ = "Stratification Level";

    drop _FREQ_ ;
run;

* -------------------------------------------------------------- ;
* --- CONTENTS AND MEANS OF OBSERVED OUTPUT FILE             --- ;
* -------------------------------------------------------------- ;
 proc Contents data=OUTAOBS.&OUTFILE_AREAOBS. position;
 run;

***--- TO PRINT VARIABLE LABELS REMOVE "NOLABELS" FROM PROC MEANS STATEMENTS ---***;
%macro means_stratum(stratum_cond, stratum_name);
proc Means data=OUTAOBS.&OUTFILE_AREAOBS.(WHERE=(&stratum_cond.)) n nmiss min max sum nolabels;
   var TAMH01-TAMH03 PAMH01-PAMH03 OAMH01-OAMH03;
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

 %MACRO PRT(MH,TEXT,VOLUME);

 proc PRINT data=OUTAOBS.&OUTFILE_AREAOBS. LABEL SPLIT='*';
 %IF &VOLUME=0 %THEN %DO;
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
 format TAMH&MH. PAMH&MH. 13.0 OAMH&MH. 8.6;
 %END;
 %ELSE %DO;
 var   RACECAT POVCAT HOSPST YEAR PAYCAT &CUSTOM_STRATUM. TAMH&MH. ;
 label RACECAT = "Race Categories"
        POVCAT  = "FIPS Poverty Categories"
        HOSPST  = "Hospital State Postal Code"
        YEAR    = "Calendar Year"
        PAYCAT  = "Patient Primary Payer"
        TAMH&MH.= "TAMH&MH.*(Numerator)"
       ;
 format TAMH&MH. 13.0;
 %END;
 format RACECAT RACECAT.
        PAYCAT PAYCAT. 
        POVCAT POVCATLBL.
   ;
 title4 "Indicator &MH.: &TEXT";
 run;

 %MEND PRT;
 %PRT(01, %BQUOTE(Severe Maternal Morbidity Rate (20 Indicators)),0);
 %PRT(02, %BQUOTE(Severe Maternal Morbidity (20 Indicators) Plus In-Hospital Mortality Rate),0);
 %PRT(03, %BQUOTE(Refined Severe Maternal Morbidity (20 Indicators) Plus In-Hospital Mortality Rate, Beta),0);
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
 put "AHRQ SAS QI v2024 &OUTFILE_AREAOBS data set created with the following CONTROL options:";
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "Race" "," "Poverty"  "," "State"  "," "Year" "," "Payer"  "," "&CUSTOM_STRATUM." ","
     "TAMH01" "," "TAMH02" "," "TAMH03" ","
     "PAMH01" "," "PAMH02" "," "PAMH03" ","   
     "OAMH01" "," "OAMH02" "," "OAMH03" 
 ;
 end;

 put RACECAT 3. "," POVCAT 3.  "," HOSPST $2. "," YEAR 4. "," PAYCAT 3. "," &CUSTOM_STRATUM. &TYPLEN.. ","
 (TAMH01-TAMH03) (7.0 ",")
 ","
 (PAMH01-PAMH03) (13.2 ",")
 ","
 (OAMH01-OAMH03) (12.10 ",")
 ;
 run;

 %END;

 %else %if &TXTAOBS. = 1 and &CUSTOM_STRATUM. =  %then %do;

 data _NULL_;
 set OUTAOBS.&OUTFILE_AREAOBS.;
 file MHTXTAOB lrecl=2000 ;
 if _N_=1 then do;
 put "AHRQ SAS QI v2024 &OUTFILE_AREAOBS data set created with the following CONTROL options:";
 put "Number of diagnoses evaluated = &NDX";
 put "Number of procedures evaluated = &NPR";
 put "Review the CONTROL program for more information about these options.";
 put ;
 put "Race" "," "Poverty"  "," "State"  "," "Year" "," "Payer"  "," 
     "TAMH01" "," "TAMH02" "," "TAMH03" ","
     "PAMH01" "," "PAMH02" "," "PAMH03" ","   
     "OAMH01" "," "OAMH02" "," "OAMH03" 
 ;
 end;

 put RACECAT 3. "," POVCAT 3.  "," HOSPST $2. "," YEAR 4. "," PAYCAT 3. ","
 (TAMH01-TAMH03) (7.0 ",")
 ","
 (PAMH01-PAMH03) (13.2 ",")
 ","
 (OAMH01-OAMH03) (12.10 ",")
 ;
 run;

 %END;

 %MEND TEXTP1;

 %TEXTP1;
