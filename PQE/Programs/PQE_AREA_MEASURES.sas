* ====================== PROGRAM: PQE_AREA_MEASURES.SAS =========================;
*
*  DESCRIPTION:
*         Assigns the Prevention Quality Indicators in Emergency Department
*         Settings (PQE) outcomes of interest to ED records.
*         Variables created by this program are TAQEnn and EXCLUDEQEnn.
*
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
*
*  USER NOTE: The PQE_AREA_FORMATS.SAS program must be run BEFORE
*             running this program.
*
* ===============================================================================;

TITLE2 'PQE_AREA_MEASURES PROGRAM';
TITLE3 'AHRQ PREVENTION QUALITY INDICATORS IN ED SETTINGS (PQE): ASSIGN OUTCOMES TO DATA';

* -------------------------------------------------------------- ;
* --- IN PREPARATION FOR PQEs THAT TRACK ED PATIENTS OVER    --- ;
* --- TIME, THE INPUT FILE MUST BE PRE-SORTED.               --- ;
* --- SPECIFICATIONS FOR THE INPUT DATA FILE AND DATA        --- ;
* --- ELEMENTS ARE PROVIDED IN THE SAS SOFTWARE INSTRUCTIONS --- ;
* -------------------------------------------------------------- ; 
  
DATA TEMP0;
   SET INMSR.&DISCHARGE.
    (KEEP = KEY FEMALE AGE AGEMONTH HOSPID PSTCO HOSPST
            YEAR DQTR DX1-DX&NDX. EDADMIT
            VisitLink DaysToEvent LOS DIED HCUP_ED &OUTFILE_KEEP);
   if HCUP_ED > 0;
   
   ATTRIB RESIDENT LENGTH=8 LABEL='Whether patient resides in same state as admitting hospital';
   IF FIPSTATE(INPUT(SUBSTR(PUT(PSTCO,Z5.),1,2),8.))=HOSPST AND NOT MISSING(HOSPST) THEN RESIDENT=1; ELSE RESIDENT=0;

   ATTRIB DIED_VISIT LENGTH=8 LABEL='Indicates in-hospital death';
   IF DIED=0 OR MISSING(DIED) THEN DIED_VISIT=0;
   ELSE IF DIED=1 AND EDADMIT=0 THEN DIED_VISIT=1;
   ELSE IF DIED=1 AND EDADMIT=1 THEN DIED_VISIT=2;
RUN;

PROC SORT DATA = TEMP0 ;
    BY HOSPST PSTCO VisitLink DaysToEvent DIED_VISIT EDADMIT LOS KEY;
RUN;

* ------------------------------------------------------------------ ;
* --- PREVENTION QUALITY INDICATORS IN ED SETTING (PQE)          --- ;
* --- NAMING CONVENTION:                                         --- ;
* --- THE FIRST LETTER IDENTIFIES THE PREVENTION QUALITY         --- ;
* --- INDICATOR AS ONE OF THE FOLLOWING:                         --- ;
* ---             (T) NUMERATOR ("TOP")                          --- ;
* --- THE SECOND LETTER IDENTIFIES THE PQE AS AN AREA (A)        --- ;
* --- LEVEL INDICATOR. THE NEXT TWO CHARACTERS ARE ALWAYS QE.    --- ;
* --- THE LAST TWO DIGITS ARE THE INDICATOR NUMBER.              --- ;
* ------------------------------------------------------------------ ;

* ------------------------------------------------------------------ ;
* --- CREATE A PERMANENT DATASET CONTAINING ALL RECORDS          --- ; 
* --- OUTPUT DATA SET INCLUDES ONE EXCLUSION FLAG FOR EACH       --- ;
* --- PQE INDICATING WHY A RECORD WAS EXCLUDED FROM THE          --- ;
* --- MEASURE.                                                   --- ;
* --- FOR EACH QI, THERE ARE VARIABLES:                          --- ;
* ---   TAQEnn: 1 = RECORD IN NUMERATOR, (0,1)= DENOMINATOR      --- ;
* ---   EXCLUDEnn: VALUES>0 ARE EXCLUDED RECORDS FOR VARIOUS     --- ;
* ---       CRITERIA, THE PURPOSE IS TO TALLY COUNTS LATER.      --- ;
* ---       ONLY RECORDS WITH VALUE=0 WILL BE CONSIDERED FOR     --- ;
* ---       NUMERATOR (AND DENOMINATOR FOR SOME).                --- ;
* ------------------------------------------------------------------ ;

DATA OUTMSR.&OUTFILE_MEAS.
                 (KEEP = KEY PSTCO FIPSTCO YEAR DQTR 
                         POPCAT SEXCAT HOSPST VisitLink RESIDENT
                         TAQE: EXCLUDE: 
                         DAYSTOEVENT LOS DX1 &OUTFILE_KEEP)
;
    SET TEMP0 ; 
    BY HOSPST PSTCO VisitLink DaysToEvent;
                                           
    * --------------------------------------------------------------------- ;
    * --- VARIABLES FOR REVISIT ANALYSIS                                --- ;
    * --- FOR REVISIT QI BACK PAIN 05,                                  --- ;
    * --- THE DENOMINATOR IS POPULATION DATA,  BUT THE NUMERATOR IS     --- ;
    * --- # PATIENTS WITH MORE THAN 1 BACK PAIN VISIT, FOR THOSE WITH 2+ -- ;
    * --- VISITS, THE 2ND BACK PAIN VISIT WILL HAVE TAQE05=1, AND SET   --- ;
    * --- BACKPAINVISIT2=1 SO PATIENT IS ONLY COUNTED ONCE.             --- ;
    * --------------------------------------------------------------------- ;
                                                                               
    * -------------------------------------------------------------- ;
    * --- DECLARE VARIABLES                                      --- ;
    * -------------------------------------------------------------- ;
    ATTRIB BackPainVisit1 Length=3 Label='Visit #1 for Back Pain in ED: PQE 05 (0/1)'
           BackPainVisit2 Length=3 Label='Visit #2 for Back Pain in ED: PQE 05 (0/1)';                                                         
    
    * ------------------------------------------------------------ ;
    * --- RETAIN THESE VARIABLES NEEDED FOR REVISIT INDICATOR  --- ;
    * --- PQE 05 : VISITS FOR BACK PAIN                        --- ;
    * ------------------------------------------------------------ ;
    RETAIN BackPainVisit1 BackPainVisit2 ;
                         
    * -------------------------------------------------------------- ;
    * --- RESET THE RETAINED VARIABLES WHEN IT'S THE FIRST VISIT --- ;
    * --- FOR THE PATIENT (VISITLINK)                            --- ;
    * -------------------------------------------------------------- ;
    IF FIRST.VisitLink THEN DO;
        BackPainVisit1  = .;
        BackPainVisit2  = .;
    END;

    * -------------------------------------------------------------- ;
    * --- DEFINE FIPS STATE AND COUNTY CODES BASED ON PATIENT    --- ;
    * --- RESIDENCE                                              --- ;
    * -------------------------------------------------------------- ;
    ATTRIB FIPSTCO LENGTH=$5 LABEL='FIPS STATE COUNTY CODE';
    
    IF NOT MISSING(PSTCO) THEN FIPSTCO = PUT(PSTCO, Z5.);

    * -------------------------------------------------------------- ;
    * --- DEFINE SEX CATEGORY                                    --- ;
    * -------------------------------------------------------------- ;
    ATTRIB SEXCAT LENGTH=3 LABEL='PATIENT SEX' ;

    SELECT (FEMALE);
        WHEN (0)  SEXCAT = 1;
        WHEN (1)  SEXCAT = 2;
        OTHERWISE SEXCAT = 0;
    END; * SELECT SEX ;

    * -------------------------------------------------------------- ;
    * --- DEFINE AGE CATEGORY                                    --- ;
    * -------------------------------------------------------------- ;
    ATTRIB POPCAT LENGTH=3 LABEL='PATIENT AGE IN 18 CATEGORIES' ;

    IF NOT MISSING(AGE) THEN POPCAT=INPUT(PUT(AGE,AGEFMT.),2.0);

    * ---------------------------------------------------------------------------------------- ;
    * --- DEFINE AREA LEVEL PREVENTION QUALITY INDICATORS IN EMERGENCY DEPARTMENT SETTINGS --- ;
    * ---------------------------------------------------------------------------------------- ;

    ATTRIB
        TAQE01 LENGTH=3 LABEL= 'Visits for Non-Traumatic Dental Conditions in ED (Numerator)'
        TAQE02 LENGTH=3 LABEL= 'Visits for Chronic Ambulatory Care Sensitive Conditions in ED (Numerator)'
        TAQE03 LENGTH=3 LABEL= 'Visits for Acute Ambulatory Care Sensitive Conditions in ED (Numerator)'    
        TAQE04 LENGTH=3 LABEL= 'Visits for Asthma in ED (Numerator)'
        TAQE05 LENGTH=3 LABEL= 'Visits for Back Pain in ED (Numerator)'
        EXCLUDEQE01 LENGTH=3 LABEL='EXCLUSION FLAG FOR PQE 01 Visits for Non-Traumatic Dental Conditions in ED'
        EXCLUDEQE02 LENGTH=3 LABEL='EXCLUSION FLAG FOR PQE 02 Visits for Chronic Ambulatory Care Sensitive Conditions in ED' 
        EXCLUDEQE03 LENGTH=3 LABEL='EXCLUSION FLAG FOR PQE 03 Visits for Acute Ambulatory Care Sensitive Conditions in ED'
        EXCLUDEQE04 LENGTH=3 LABEL='EXCLUSION FLAG FOR PQE 04 Visits for Asthma in ED'  
        EXCLUDEQE05 LENGTH=3 LABEL='EXCLUSION FLAG FOR PQE 05 Visits for Back Pain in ED'  ;
	
    * ------------------------------------------------------------------------------------------- ;
    * --- CONSTRUCT AREA LEVEL PREVENTION QUALITY INDICATORS IN EMERGENCY DEPARTMENT SETTINGS --- ;
    * ------------------------------------------------------------------------------------------- ;

    * ----------------------------------------------------------- ;
    * --- PQE 01 : VISITS FOR NON-TRAUMATIC DENTAL CONDITIONS --- ;
    * ----------------------------------------------------------- ;
            
    * --- EXCLUSION FLAG FOR PQE 01 : DENTAL VISITS                  --- ;
    * --- Exclusion 1:  Missing data (age, sex, DX1, patient county) --- ;
    * --- Exclusion 2:  Age under 5                                  --- ;  
    * --- Exclusion 3:  Exclude facial trauma, any position.         --- ;
    
    IF MISSING(AGE) 
    OR MISSING(FEMALE) 
    OR MISSING(DX1) 
    OR RESIDENT NE 1 
    OR MISSING(PSTCO)          THEN EXCLUDEQE01 = 1;
    ELSE IF AGE LT 5            THEN EXCLUDEQE01 = 2;
    ELSE IF %MDX(TraumaToFace.) THEN EXCLUDEQE01 = 3;
    ELSE                             EXCLUDEQE01 = 0; 

    * --- NUMERATOR:                                                --- ;
    * ---   ED visits with a first listed DX of a dental condition. --- ;
    * --- DENOMINATOR:                                              --- ;
    * ---   Area population                                         --- ;
    
    IF EXCLUDEQE01 = 0 THEN DO;
        IF %MDX1(DentalVisit.) THEN TAQE01 = 1;
    END;    

    * --- END OF PQE 01 DENTAL VISIT --- ;

    * ------------------------------------------------------------------------------- ; 
    * --- PQE 02 : VISITS FOR CHRONIC AMBULATORY CARE SENSITIVE CONDITIONS (ACSC) --- ;
    * ------------------------------------------------------------------------------- ;    

    * --- EXCLUSION FLAG FOR PQE 02 : CHRONIC ACSC                   --- ;
    * --- Exclusion 1:  Missing data (age, sex, DX1, patient county) --- ;
    * --- Exclusion 2:  Age under 40                                 --- ;  
    
    IF MISSING(AGE) 
    OR MISSING(FEMALE) 
    OR MISSING(DX1) 
    OR RESIDENT NE 1
    OR MISSING(PSTCO) THEN EXCLUDEQE02 = 1;
    ELSE IF AGE LE 39  THEN EXCLUDEQE02 = 2;
    ELSE                    EXCLUDEQE02 = 0; 

    * --- NUMERATOR:                                                                 --- ;
    * ---   ED visits with first-listed diagnoses of:                                --- ;
  	* ---   Asthma, COPD, heart failure, or acute diabetic hyper- and hypoglycemic   --- ;
    * ---   complications, or chronic kidney disease.                                --- ; 
    * ---   Also included is a first-listed diagnosis of lower respiratory infection --- ;
    * ---   with a second-listed of COPD or asthma.                                  --- ;
    * --- DENOMINATOR:                                                               --- ;
    * ---   Area population                                                          --- ;
    
    IF EXCLUDEQE02 = 0 THEN DO;
        IF ( %MDX1(HeartFailure.) )
        OR ( %MDX1(COPD.)         )
        OR ( %MDX1(Asthma.)       )
        OR ( %MDX1(DMSTCX.)       )
        OR ( %MDX1(CKD.)          )
        OR ( (%MDX1(LowerRespInfection.) ) AND ( (%MDX2(COPD.) ) OR ( %MDX2(Asthma.) ) ) )
            THEN TAQE02 = 1;
    END;             
             
    * --- END OF PQE 02 CHRONIC ACSC --- ;  

    * ---------------------------------------------------------------------- ;
    * --- PQE 03 : VISITS FOR ACUTE AMBULATORY CARE SENSITIVE CONDITIONS --- ;        
    * ---------------------------------------------------------------------- ;

    * --- EXCLUSION FLAG FOR PQE 03 : ACUTE ACSC                                --- ;
    * --- Exclusion 1:  Missing data (age, sex, DX1, patient county)            --- ;
    * --- Exclusion 2:  Age 65 and above                                        --- ;  
    * --- Exclusion 3:  Cellulitis DX1 and diabetes secondary                   --- ;
    * --- Exclusion 4:  Any diagnosis of immunocompromised state                --- ;
    * --- Exclusion 5:  Age 3 months and younger                                --- ;
    * --- Exclusion 6:  Treat and admitted (EDADMIT=1)                          --- ;
    * --- Exclusion 7:  UTI DX1 and second listed of urinary tract malformation --- ;
    *                   for females age 18-34 years                             --- ;
     
    IF MISSING(AGE) 
    OR MISSING(FEMALE) 
    OR MISSING(DX1) 
    OR RESIDENT NE 1
    OR MISSING(PSTCO)                                   THEN EXCLUDEQE03 = 1;
    ELSE IF AGE GE 65                                    THEN EXCLUDEQE03 = 2;
    ELSE IF %MDX1(Cellulitis.) AND %MDX2(diabetes.)      THEN EXCLUDEQE03 = 3;
    ELSE IF %MDX(immunocompromised.)                     THEN EXCLUDEQE03 = 4;
    ELSE IF AGEMONTH LE 3 AND AGE=0                      THEN EXCLUDEQE03 = 5;
    ELSE IF EDADMIT=1                                    THEN EXCLUDEQE03 = 6;
    ELSE IF %MDX1(QE03EXC_UTI.) AND %MDX2(QE03EXC_UTM.)
            AND FEMALE=1 AND (18 LE AGE) AND (AGE LE 34) THEN EXCLUDEQE03 = 7;
    ELSE                                                      EXCLUDEQE03 = 0;

    * --- NUMERATOR:                                              --- ;
    * ---   ED visits with a first listed diagnosis of:           --- ;
    * ---   Cellulitis, pyoderma, local skin infection            --- ; 
    * ---   Uncomplicated cystitis among women age 18-34 years    --- ;  
    * ---   Upper respiratory infection (URI), allergic rhinitis, --- ;
    * ---   chronic and acute otitis media                        --- ; 
    * ---   Influenza without pneumonia, viral syndrome           --- ; 
    * --- DENOMINATOR:                                            --- ;
    * ---   Area population                                       --- ;
	
    IF EXCLUDEQE03 = 0 THEN DO;
        IF ( %MDX1(Cellulitis.)         )
        OR ( %MDX1(UTI_NonCx.) AND FEMALE=1 AND (18 LE AGE) AND (AGE LE 34) )
        OR ( %MDX1(UpperRespInfection.) )
        OR ( %MDX1(Influenza.)          )
            THEN TAQE03 = 1;        
    END;  

    * --- END OF PQE 03 ACUTE ACSC --- ;        
  
    * ---------------------------------- ;
    * --- PQE 04 : VISITS FOR ASTHMA --- ;     
	* ---------------------------------- ;

    * --- EXCLUSION FLAG FOR PQE 04 : ASTHMA                         --- ;
    * --- Exclusion 1:  Missing data (age, sex, DX1, patient county) --- ;
    * --- Exclusion 2:  Age under 5 or age 40 and older              --- ; 
    * --- Exclusion 3:  ICD-9-CM DX for cystic fibrosis, respiratory --- ;
    *                   anomalies , and pneumonia                    --- ;
    
    IF MISSING(AGE) 
    OR MISSING(FEMALE) 
    OR MISSING(DX1) 
    OR RESIDENT NE 1
    OR MISSING(PSTCO)                  THEN EXCLUDEQE04 = 1;
    ELSE IF AGE LT 5 OR AGE GE 40       THEN EXCLUDEQE04 = 2;
    ELSE IF %MDX(CysticFibrosis.) 
         OR %MDX(RespiratoryAnomalies.)
         OR %MDX(QE4EXC_PNEUMONIA.  )   THEN EXCLUDEQE04 = 3;
    ELSE                                     EXCLUDEQE04 = 0;

    * --- NUMERATOR:                                            --- ;
    * ---   ED visits with a first listed diagnosis of asthma   --- ;
    * ---   with and without exacerbation or status asthmaticus --- ;
    * ---   or a first listed diagnosis of bronchitis           --- ;
    * ---   with any listed diagnosis of asthma                 --- ;
    * --- DENOMINATOR:                                          --- ;
    * ---   Area population                                     --- ;
	
    IF EXCLUDEQE04 = 0 THEN DO;
        IF  %MDX1(Asthma.) 
        OR (%MDX1(QE4Bronchitis.) AND %MDX2(Asthma.)) THEN TAQE04 = 1;         
    END;            

    * --- END OF PQE 04 ASTHMA --- ;        
  
    * ------------------------------------- ;
    * --- PQE 05 : VISITS FOR BACK PAIN --- ;
    * ------------------------------------- ;	

    * --- EXCLUSION FLAG FOR PQE 05 : BACK PAIN                                 --- ;
    * --- Exclusion 1:  Missing data (age, sex, DX1, patient county)            --- ;
    * --- Exclusion 2:  Missing VisitLink and DaysToEvent                       --- ;
    * --- Exclusion 3:  Age under 18                                            --- ;  
    * --- Exclusion 4:  Any diagnosis code of trauma.                           --- ;  
    * --- Exclusion 5:  Any diagnosis code of cancer.                           --- ; 
    * --- Exclusion 6:  Any diagnosis code of urinary tract infection.          --- ; 
    * --- Exclusion 7:  Any diagnosis code of fever.                            --- ; 
    * --- Exclusion 8:  Exclude cauda equina syndrome, spinal epidural abscess, --- ;
    * ---               and cord compression.                                   --- ;
    
    IF MISSING(AGE) 
    OR MISSING(FEMALE) 
    OR MISSING(DX1) 
    OR RESIDENT NE 1
    OR MISSING(PSTCO)                     THEN EXCLUDEQE05 = 1;
    ELSE IF MISSING(VisitLink) 
         OR MISSING(DaysToEvent)           THEN EXCLUDEQE05 = 2;
    ELSE IF AGE LT 18                      THEN EXCLUDEQE05 = 3;
    ELSE IF %MDX(TRAUMAF.)                 THEN EXCLUDEQE05 = 4;
    ELSE IF %MDX(BPExcludeCancer.)         THEN EXCLUDEQE05 = 5;
    ELSE IF %MDX(BPExcludeUTI.)            THEN EXCLUDEQE05 = 6;
    ELSE IF %MDX(BPExcludeFever.)          THEN EXCLUDEQE05 = 7;
    ELSE IF %MDX(BPExcludeCES.)            THEN EXCLUDEQE05 = 8;
    ELSE IF %MDX(BPEXCLUDEGALLSTONE.)      THEN EXCLUDEQE05 = 9;
    ELSE IF %MDX(BPEXCLUDEKIDNEYSTONE.)    THEN EXCLUDEQE05 = 10;
    ELSE                                   EXCLUDEQE05 = 0;

    * --- NUMERATOR:                                                --- ;
    * ---   Patients with two or more ED visits with                --- ;
    * ---   a first listed diagnosis of back pain or back disorders --- ;
    * --- DENOMINATOR:                                              --- ;
    * ---   Area population                                         --- ;
	
    IF EXCLUDEQE05 = 0 AND %MDX1(BACKPAIN.) THEN DO;  
        IF BackPainVisit1 = . THEN BackPainVisit1 = 1;             * this is the 1st back pain visit ;
        ELSE IF BackPainVisit1 = 1 AND BackPainVisit2 = . THEN DO; * this is the 2nd back pain visit ;
            BackPainVisit2 = 1;                                    * found the 2nd back pain visit   ;
            TAQE05 = 1;        * only count the 2nd if there are more than 2 visits for back pain in ED;
        END;
    END;            

    * --- END OF PQE 05 BACK PAIN --- ;          
  
RUN;  

 * ------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MEASURES OUTPUT FILE      --- ;
 * ------------------------------------------------------- ;

PROC CONTENTS DATA=OUTMSR.&OUTFILE_MEAS. POSITION;
RUN;

***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA = OUTMSR.&OUTFILE_MEAS. N NMISS MIN MAX NOLABELS ;
     VAR YEAR DQTR POPCAT SEXCAT;
     TITLE4 "ED PREVENTION QUALITY INDICATOR CATEGORICAL VARIABLES AND RANGES OF VALUES";
RUN; QUIT;

PROC MEANS DATA = OUTMSR.&OUTFILE_MEAS. N NMISS MIN MEAN SUM MAXDEC=2 NOLABELS ;
     VAR TAQE01-TAQE05;
     TITLE5 "ED PREVENTION QUALITY INDICATOR NUMERATORS (COUNT=SUM)";
RUN; QUIT;


* -------------------------------------------------------------------------- ;
* --- DESCRIPTIVE STATISTICS ON OUTPUT FILE                              --- ;
* -------------------------------------------------------------------------- ;

PROC MEANS DATA=OUTMSR.&OUTFILE_MEAS. N NMISS MIN MAX MEAN SUM MAXDEC=2 NOLABELS;
RUN;

PROC CONTENTS DATA=OUTMSR.&OUTFILE_MEAS. ;
RUN;

* -------------------------------------------------------------------------- ;
* --- PRINT COUNTS FOR EXCLUDED RECORD FOR EACH PQE INDICATOR            --- ;
* -------------------------------------------------------------------------- ;

%MACRO EXCLUSION_COUNTS_(QINUM_=01, QILabel_=)  ; 
    
    TITLE3 "EXCLUSION COUNTS FOR P&QInum_: &QILabel_" ;   
    PROC SUMMARY DATA = OUTMSR.&OUTFILE_MEAS. ;
        CLASS EXCLUDE&QINUM_.;
        VAR KEY ;
        OUTPUT OUT = EXCOUNTS (DROP=_FREQ_) N=COUNT;
    RUN;
    DATA EXCOUNTS;
        SET EXCOUNTS (WHERE=(_TYPE_=1)) ; /* BY EXCLUSION */
        IF _N_ = 1 THEN SET EXCOUNTS 
            (WHERE=(_TYPE_=0) KEEP=COUNT _TYPE_ RENAME=(COUNT=TOTALCOUNT));  /* OVERALL */
        PERCENT = COUNT / TOTALCOUNT * 100;
        DROP TOTALCOUNT _TYPE_;
    RUN;
    PROC PRINT DATA=EXCOUNTS NOOBS ;
        FORMAT EXCLUDE&QINUM_. EXCLUDE&QINUM_.F. COUNT COMMA12. PERCENT 6.2 ;
    RUN;
%MEND EXCLUSION_COUNTS_ ;

%EXCLUSION_COUNTS_(QINUM_=QE01, QILabel_=Visits for Non-Traumatic Dental Conditions in ED);
%EXCLUSION_COUNTS_(QINUM_=QE02, QILabel_=Visits for Chronic Ambulatory Care Sensitive Conditions in ED);
%EXCLUSION_COUNTS_(QINUM_=QE03, QILabel_=Visits for Acute Ambulatory Care Sensitive Conditions in ED); 
%EXCLUSION_COUNTS_(QINUM_=QE04, QILabel_=Visits for Asthma in ED);
%EXCLUSION_COUNTS_(QINUM_=QE05, QILabel_=Visits for Back Pain in ED);
