* ================================ Program: PDI_ALL_CONTROL.SAS ============================== ;
* VERSION: SAS QI v2024
* RELEASE DATE: JULY 2024
* ============================================================================================ ;
* The Pediatric Quality Indicator (PDI) module of the AHRQ Quality
  Indicators software includes the following programs:

   1. PDI_ALL_CONTROL.SAS   Assigns user inputs required by other programs
                            and optional output options.

   2. PDI_ALL_FORMATS.SAS   Creates SAS format library used by other programs.

   3. PDI_ALL_MEASURES.SAS  Assigns Pediatric Quality Indicators to inpatient records.
                            Refer to technical specification documents for details.

   4. PDI_HOSP_OBSERVED.SAS Calculates observed rates for hospital level indicators.

   5. PDI_HOSP_STRATIFIED.SAS Calculates observed rates stratified by risk group
                              categories that are specific to each indicator.

   6. PDI_AREA_OBSERVED.SAS Calculates observed rates for area level indicators.

   7. PDI_AREA_RISKADJ.SAS  Calculates risk-adjusted rates for area level indicators.

   8. PDI_HOSP_RISKADJ.SAS  Calculates risk-adjusted rates for hospital level indicators.

 * The software also requires the following files:

   1. discharges.sas7bdat  User supplied discharge level file organized according
                           to the software instructions.
                           The file name is up to the user but must be listed below.

   2. PDI_Dx_Pr_Macros_v2024.sas  Standard processes used by the other SAS programs.
                                  The user does not need to open.

   3. PDI_CCSR_Format_v2024.sas  Creates formats assigning Clinical Classification 
                                 Software-Refined (CCSR) variables.

   4. PDI_CCSR_Code_v2024.sas  Creates CCSR variables based on the presence of diagnoses.

   5. PDI_Comorb_Format_v2024.sas  Creates formats assigning comorbidity groups based on 
                                   ICD-10-CM ELIXHAUSER COMORBIDITY software.
	
   6. PDI_Comorb_Code_v2024.sas  Creates comorbidity variables based on the presence
                                 of secondary diagnoses and redefines comorbidity group by
                                 eliminating DRGs directly related to them.

   7. 2000-2023_Population_Files_v2024.txt  Population file with counts by area, age, and sex.
                                            Required for area rate calculation. Available as a
                                            separate download from the AHRQ website.
						   
   8. PDI_AREA_SIGVAR_ARRAY_v2024.SAS  File with noise and signal variance estimates 
                                       and reference rates for smoothing by age and sex.

   9. PDI_AREA_SIGVAR_ARRAY_SES_v2024.SAS  File with noise and signal variance estimates 
                                           and reference rates for smoothing by age, sex and SES.
  
  10. PDI_AREA_OE_Array_v2024.SAS  Array for OE ratio adjustment from reference population 
                                   based on risk adjustment models. The software provides 
                                   two options to use OE ratio adjustment.

  11. PDI_AREA_OE_Array_SES_v2024.SAS  Array for OE ratio adjustment from reference population 
                                       based on risk adjustment models. The software provides 
                                       two options to use OE ratio adjustment by age, sex and SES. 
                                             
  12. PDI_HOSP_Regvars_v2024.sas  Creates age, sex, MDRG flag variables for use by risk adjustment.  
  
  13. PDI_HOSP_Sigvar_Array_v2024.sas  Arrays for signal variance and reference population rates used 
                                       by risk adjustment program.
                          
  14. PDI_HOSP_OE_Array_v2024.sas  Array for OE ratio adjustment from reference population based 
                                   on risk adjustment models. 
                                   The software provides two options to use OE ratio adjustment.
                                    
***************************************************************************** ;
******************************* PLEASE READ ********************************* ;
***************************************************************************** ;
 * The AHRQ Quality Indicator software is intended for use with discharges
   coded according to the standards in place at the date of the discharge.
   Discharges should be classified under the ICD-10-CM/PCS specifications
   effective 10/1/2015. All diagnosis codes require a corresponding Present
   on Admission value, POA coded according to UB04 standards.
   Although results can be generated with inputs coded under ICD9 and
   converted to ICD10 with General Equivalence Mappings, the mapping process
   may produce unrepresentative results. ICD10 observed rate calculations
   should not be used to produce ICD9 risk adjusted outputs.

 * The USER MUST modify portions of the following code in order to
   run this software.  The only changes necessary to run
   this software are changes in this program (PDI_ALL_CONTROL.SAS).
   The modifications include such items as specifying the name and location
   of the input data set, the year of population data to be used, and the
   name and location of output data sets.

 * NOTE: PDI_ALL_CONTROL.SAS provides the option to read data in and write
         data out to different locations.  For example, "libname INMSR" points
         to the location of the input data set for the PDI_ALL_MEASURES program
         and "libname OUTMSR" points to the location of the output data set
         created by the PDI_ALL_MEASURES program.  The location and file name of
         each input and output can be assigned separately below. The default
         values will place output in a SASData folder with standard names for
         each file based on the location of the PDI folder listed in the
         PATHNAME variable.

 * See the AHRQ_PDI_SAS_v2024_ICD10_Release_Notes.txt file for version change details.

 Generally speaking, a first-time user of this software would proceed 
 as outlined below:

    1.  Modify and save all required user inputs in PDI_ALL_CONTROL.SAS. (This program - MUST be done.)

    2.  Select the programs to run by updating the flags (EXE_FMT,EXE_MSR,EXE_HOBS,EXE_HSTR,EXE_AOBS,EXE_ARSK).
        The default option will run all programs. Programs must be run in order and will not execute if 
        the required input is not available. See log for details. 

    3.  Run (submit) the PDI_ALL_CONTROL.SAS. (MUST be done.) 

 * ------------------------------------------------------------------ ;
 * --------------    INPUTS FOR ALL PROGRAMS    --------------------- ;
 * ------------------------------------------------------------------ ;

*PATHNAME specifies the location of the PDI folder which includes the
          Programs, Macros, ParmFiles, and SASData subfolders;
%LET PATHNAME=C:\Pathname\PDI;                 *<===USER MUST modify;

*DISFOLDER specifies the folder that contains the discharge data;
%LET DISFOLDER=C:\Pathname;                    *<===USER MUST modify;

*DISCHARGE specifies the name of the discharge data file;
%LET DISCHARGE=discharges;                       *<===USER MUST modify;

*SUFX specifies an identifier suffix to be placed on output datasets;
%LET SUFX = v2024;                               *<===USER may modify;

*LIBRARY is where formats generated by PDI_ALL_FORMATS will be saved;
LIBNAME LIBRARY  "&PATHNAME.\SASData";          *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF COUNTY-LEVEL AREAS SHOULD BE CONVERTED TO MAs -- ;
 * ---     0 - County level with U.S. Census FIPS                -- ;
 * ---     1 - County level with Modified FIPS                   -- ;
 * ---     2 - Metro Area level with OMB 1999 definition         -- ;
 * ---     3 - Metro Area level with OMB 2003 definition         -- ;
 * ---------------------------------------------------------------- ;
%LET MALEVL = 0;                                *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SELECT THE POPULATION DATA FOR THE YEAR THAT BEST MATCHES -- ; 
 * --- THE DISCHARGE DATA. POPYEAR WILL IDENTIFY POPULATION USED -- ;
 * --- BY THE PDI_AREA_OBSERVED AND PDI_AREA_RISKADJ PROGRAM     -- ;
 * ---------------------------------------------------------------- ;
%LET POPYEAR = 2023;   *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF POPULATION FILE                          --- ;
 * ---------------------------------------------------------------- ;
filename POPFILE  "&PATHNAME.\ParmFiles\2000-2023_Population_Files_v2024.txt";  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF RECORDS SHOULD BE PRINTED IN SAS OUTPUT AT   --- ;
 * --- END OF EACH PROGRAM.  0 = NO, 1 = YES                    --- ;
 * ---------------------------------------------------------------- ;
%LET PRINT = 0;                                 *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF O_E RATIO ADJUSTMENT IS FROM REFERENCE POPULATION;
 * --- 1 = YES, DEFAULT AND RECOMMENDED                         --- ;
 * --- 0 = NO,  O_E RATIOS BASED ON USER DATA WILL BE CALCULATED--- ; 
 * ---         AND USED. USE WITH CAUTION.                      --- ;
 * ---------------------------------------------------------------- ;
%LET Calibration_OE_to_ref_pop = 1;             *<===USER may modify;
 
 * ---------------------------------------------------------------- ;
 * --- ADD OPTION TO COMPRESS OUTPUT.                           --- ;
 * --- RECOMMENDED WITH LARGE FILES. TO RESTORE, RUN:           --- ;
 * --- options compress = no                                    --- ;
 * ---------------------------------------------------------------- ;
options compress = YES ;                        *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF SAS MACRO LIBRARY                        --- ;
 * ---------------------------------------------------------------- ;
filename MacLib "&PATHNAME.\Macros";            *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---          PROGRAM : PDI_ALL_MEASURES.SAS                  --- ;
 * ---------------------------------------------------------------- ;
 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PDI_ALL_MEASURES.SAS INPUT DATA          --- ;
 * ---------------------------------------------------------------- ;
libname INMSR  "&DISFOLDER.";                    *<==USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PDI_ALL_MEASURES.SAS OUTPUT DATA         --- ;
 * ---------------------------------------------------------------- ;
libname OUTMSR "&PATHNAME.\SASData";             *<==USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF OUTPUT FILE FROM PDI_ALL_MEASURES.SAS        --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_MEAS = PDMSR_&SUFX.;                *<==USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE ADDITIONAL INPUT VARIABLES TO KEEP ON OUTPUT    --- ;
 * --- DATA FILE FROM PDI_ALL_MEASURES.SAS.                     --- ;
 * --- INPUT VARIABLES ALWAYS INCLUDED ON THE OUTPUT FILE ARE:  --- ;
 * --- KEY HOSPID DRG MDC SEX AGE AGEDAY YEAR DQTR LOS          --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_KEEP = ;                           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- MODIFY INPUT AND OUTPUT FILE                             --- ;
 * ---------------------------------------------------------------- ;
 * --- PROGRAM DEFAULT ASSUMES THERE ARE                        --- ;
 * ---     35 DIAGNOSES (DX1-DX35)                              --- ;
 * ---     30 PROCEDURES (PR1-PR30)                             --- ;
 * ---------------------------------------------------------------- ;
 * --- MODIFY NUMBER OF DIAGNOSIS AND PROCEDURE VARIABLES TO    --- ;
 * --- MATCH USER DISCHARGE INPUT DATA.                         --- ;
 * --- VALUES MUST BE GREATER THAN ZERO.                        --- ;
 * ---------------------------------------------------------------- ;
%LET NDX = 35;                                  *<===USER may modify;
%LET NPR = 30;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- FOR HOSPITAL-LEVEL PDI:                                  --- ;
 * --- INDICATE WHETHER DISCHARGES INCLUDE MDC DATA             --- ;
 * ---     1 = DATA HAS MDC FROM CMS MS-DRG GROUPER (DEFAULT)   --- ;
 * ---         MDC SHOULD NOT BE IMPUTED OR MAPPED FROM MS-DRGS --- ;
 * ---         RECORDS SHOULD HAVE AN MDC BETWEEN 01 AND 25     --- ;
 * ---     0 = DATA HAS MDC WITH ALL MISSING VALUES             --- ;
 * ---------------------------------------------------------------- ;
 * --- FOR AREA-LEVEL PDI:                                      --- ;
 * --- THIS VALUE WILL NOT AFFECT SOFTWARE RESULTS              --- ;
 * ---------------------------------------------------------------- ;
%LET MDC_PROVIDED = 1;                          *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * - INDICATE WHETHER DATA REGARDING THE NUMBER OF DAYS         --- ;
 * - FROM ADMISSION TO PROCEDURE (PRDAY) IS AVAILABLE           --- ;
 * -      0 = PRDAY IS NOT INCLUDED                             --- ;
 * -      1 = PRDAY IS INCLUDED                                 --- ;
 * - PRDAY = 0 WILL SUPPRESS RISK-ADJUSTED RATES FOR THE        --- ;
 * - FOLLOWING INDICATORS REQUIRING PRDAY FOR CALCULATION       --- ;
 * - PDI 08, PDI 09                                             --- ;
 * ---------------------------------------------------------------- ;
%LET PRDAY  = 1;                                *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * - CREATE PERMANENT SAS DATASET TO STORE RECORDS THAT WILL    --- ;
 * - NOT BE INCLUDED IN CALCULATIONS BECAUSE KEY VARIABLE       --- ;
 * - VALUES ARE MISSING.  THIS DATASET SHOULD BE REVIEWED AFTER --- ;
 * - RUNNING PDI_ALL_MEASURES.                                  --- ;
 * ---------------------------------------------------------------- ;
%LET DELFILE  = PDI_DELETED_&SUFX.;             *<===USER may modify;

 * ================================================================ ;
 * ============HOSPITAL-LEVEL PEDIATRIC QUALITY INDICATORS========= ;
 * ================================================================ ;
 
 * ---------------------------------------------------------------- ;
 * ---    PROGRAM: PDI_HOSP_OBSERVED.SAS - OBSERVED RATES       --- ;
 * ---------------------------------------------------------------- ;
 
 * ---------------------------------------------------------------- ;
 * ---    SET LOCATION OF PDI_HOSP_OBSERVED.SAS OUTPUT DATA     --- ;
 * ---------------------------------------------------------------- ;
libname OUTHOBS "&PATHNAME.\SASData";           *<===USER may modify;

 * ----------------------------------------------------------------------- ;
 * --- TYPELVLH indicates the levels (or _TYPE_) of                    --- ;
 * --- summarization to be kept in the output.                         --- ;
 * ---                                                                 --- ;
 * ---  TYPELVLH      stratification                                   --- ;
 * ---  --------  ---------------------------------------------------- --- ;
 * ---     0      overall                                              --- ;
 * ---     1                                                      race --- ;
 * ---     2                                              payer        --- ;
 * ---     3                                              payer * race --- ;
 * ---     4                                        sex                --- ;
 * ---     5                                        sex         * race --- ;
 * ---     6                                        sex * payer        --- ;
 * ---     7                                        sex * payer * race --- ;
 * ---     8                                  age                      --- ;
 * ---     9                                  age               * race --- ;
 * ---    10                                  age       * payer        --- ;
 * ---    11                                  age       * payer * race --- ;
 * ---    12                                  age * sex                --- ;
 * ---    13                                  age * sex         * race --- ;
 * ---    14                                  age * sex * payer        --- ;
 * ---    15                                  age * sex * payer * race --- ;
 * ---    16                         ageday                            --- ;
 * ---    17                         ageday                     * race --- ;
 * ---    18                         ageday             * payer        --- ;
 * ---    19                         ageday             * payer * race --- ;
 * ---    20                         ageday       * sex                --- ;
 * ---    21                         ageday       * sex         * race --- ;
 * ---    22                         ageday       * sex * payer        --- ;
 * ---    23                         ageday       * sex * payer * race --- ;
 * ---    24                         ageday * age                      --- ;
 * ---    25                         ageday * age               * race --- ;
 * ---    26                         ageday * age       * payer        --- ;
 * ---    27                         ageday * age       * payer * race --- ;
 * ---    28                         ageday * age * sex                --- ;
 * ---    29                         ageday * age * sex         * race --- ;
 * ---    30                         ageday * age * sex * payer        --- ;
 * ---    31                         ageday * age * sex * payer * race --- ;
 * ---    32                  bwht                                     --- ;
 * ---    33                  bwht                              * race --- ;
 * ---    34                  bwht                      * payer        --- ;
 * ---    35                  bwht                      * payer * race --- ;
 * ---    36                  bwht                * sex                --- ;
 * ---    37                  bwht                * sex         * race --- ;
 * ---    38                  bwht                * sex * payer        --- ;
 * ---    39                  bwht                * sex * payer * race --- ;
 * ---    40                  bwht          * age                      --- ;
 * ---    41                  bwht          * age               * race --- ;
 * ---    42                  bwht          * age       * payer        --- ;
 * ---    43                  bwht          * age       * payer * race --- ;
 * ---    44                  bwht          * age * sex                --- ;
 * ---    45                  bwht          * age * sex         * race --- ;
 * ---    46                  bwht          * age * sex * payer        --- ;
 * ---    47                  bwht          * age * sex * payer * race --- ;
 * ---    48                  bwht * ageday                            --- ;
 * ---    49                  bwht * ageday                     * race --- ;
 * ---    50                  bwht * ageday             * payer        --- ;
 * ---    51                  bwht * ageday             * payer * race --- ;
 * ---    52                  bwht * ageday       * sex                --- ;
 * ---    53                  bwht * ageday       * sex         * race --- ;
 * ---    54                  bwht * ageday       * sex * payer        --- ;
 * ---    55                  bwht * ageday       * sex * payer * race --- ;
 * ---    56                  bwht * ageday * age                      --- ;
 * ---    57                  bwht * ageday * age               * race --- ;
 * ---    58                  bwht * ageday * age       * payer        --- ;
 * ---    59                  bwht * ageday * age       * payer * race --- ;
 * ---    60                  bwht * ageday * age * sex                --- ;
 * ---    61                  bwht * ageday * age * sex         * race --- ;
 * ---    62                  bwht * ageday * age * sex * payer        --- ;
 * ---    63                  bwht * ageday * age * sex * payer * race --- ;
 * ---    64       hospital                                            --- ;
 * ---    65       hospital                                     * race --- ;
 * ---    66       hospital                             * payer        --- ;
 * ---    67       hospital                             * payer * race --- ;
 * ---    68       hospital                       * sex                --- ;
 * ---    69       hospital                       * sex         * race --- ;
 * ---    70       hospital                       * sex * payer        --- ;
 * ---    71       hospital                       * sex * payer * race --- ;
 * ---    72       hospital                 * age                      --- ;
 * ---    73       hospital                 * age               * race --- ;
 * ---    74       hospital                 * age       * payer        --- ;
 * ---    75       hospital                 * age       * payer * race --- ;
 * ---    76       hospital                 * age * sex                --- ;
 * ---    77       hospital                 * age * sex         * race --- ;
 * ---    78       hospital                 * age * sex * payer        --- ;
 * ---    79       hospital                 * age * sex * payer * race --- ;
 * ---    80       hospital        * ageday                            --- ;
 * ---    81       hospital        * ageday                     * race --- ;
 * ---    82       hospital        * ageday             * payer        --- ;
 * ---    83       hospital        * ageday             * payer * race --- ;
 * ---    84       hospital        * ageday       * sex                --- ;
 * ---    85       hospital        * ageday       * sex         * race --- ;
 * ---    86       hospital        * ageday       * sex * payer        --- ;
 * ---    87       hospital        * ageday       * sex * payer * race --- ;
 * ---    88       hospital        * ageday * age                      --- ;
 * ---    89       hospital        * ageday * age               * race --- ;
 * ---    90       hospital        * ageday * age       * payer        --- ;
 * ---    91       hospital        * ageday * age       * payer * race --- ;
 * ---    92       hospital        * ageday * age * sex                --- ;
 * ---    93       hospital        * ageday * age * sex         * race --- ;
 * ---    94       hospital        * ageday * age * sex * payer        --- ;
 * ---    95       hospital        * ageday * age * sex * payer * race --- ;
 * ---    96       hospital * bwht                                     --- ;
 * ---    97       hospital * bwht                              * race --- ;
 * ---    98       hospital * bwht                      * payer        --- ;
 * ---    99       hospital * bwht                      * payer * race --- ;
 * ---   100       hospital * bwht                * sex                --- ;
 * ---   101       hospital * bwht                * sex         * race --- ;
 * ---   102       hospital * bwht                * sex * payer        --- ;
 * ---   103       hospital * bwht                * sex * payer * race --- ;
 * ---   104       hospital * bwht          * age                      --- ;
 * ---   105       hospital * bwht          * age               * race --- ;
 * ---   106       hospital * bwht          * age       * payer        --- ;
 * ---   107       hospital * bwht          * age       * payer * race --- ;
 * ---   108       hospital * bwht          * age * sex                --- ;
 * ---   109       hospital * bwht          * age * sex         * race --- ;
 * ---   110       hospital * bwht          * age * sex * payer        --- ;
 * ---   111       hospital * bwht          * age * sex * payer * race --- ;
 * ---   112       hospital * bwht * ageday                            --- ;
 * ---   113       hospital * bwht * ageday                     * race --- ;
 * ---   114       hospital * bwht * ageday             * payer        --- ;
 * ---   115       hospital * bwht * ageday             * payer * race --- ;
 * ---   116       hospital * bwht * ageday       * sex                --- ;
 * ---   117       hospital * bwht * ageday       * sex         * race --- ;
 * ---   118       hospital * bwht * ageday       * sex * payer        --- ;
 * ---   119       hospital * bwht * ageday       * sex * payer * race --- ;
 * ---   120       hospital * bwht * ageday * age                      --- ;
 * ---   121       hospital * bwht * ageday * age               * race --- ;
 * ---   122       hospital * bwht * ageday * age       * payer        --- ;
 * ---   123       hospital * bwht * ageday * age       * payer * race --- ;
 * ---   124       hospital * bwht * ageday * age * sex                --- ;
 * ---   125       hospital * bwht * ageday * age * sex         * race --- ;
 * ---   126       hospital * bwht * ageday * age * sex * payer        --- ;
 * ---   127       hospital * bwht * ageday * age * sex * payer * race --- ;
 * ---                                                                 --- ;
 * --- The default TYPELVLH (0,64) will provide overall and hospital-  --- ;
 * --- level risk-adjusted rates, smoothed rates, and corresponding    --- ;
 * --- variance estimates. For more granular TYPELVLH that include     --- ;
 * --- stratifiers, only risk-adjusted rates and variance are          --- ;
 * --- calculated. However, the user should note that any              --- ;
 * --- stratification that includes age, sex, ageday, and bwht are not --- ;
 * --- supported because these factors are included as covariates in   --- ;
 * --- risk adjustment. Thus risk-adjusted rates for stratifiers that  --- ;
 * --- include any of those variables are suppressed from the output.  --- ;
 * ----------------------------------------------------------------------- ;
%LET TYPELVLH = IN (0,64);                             *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- NAME SAS DATASET OUTPUT FROM PROGRAM PDI_HOSP_OBSERVED.SAS --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED HOSPITAL RATES.            --- ;
 * ------------------------------------------------------------------ ;
%LET  OUTFILE_HOSPOBS  = PDHO_&SUFX.;             *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_HOSPOBS --- ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.         --- ;
 * ---     0 = NO, 1 = YES.                                       --- ;
 * ------------------------------------------------------------------ ;
%LET TXTHOBS=0;                                   *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,                 --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                          --- ;
 * ------------------------------------------------------------------ ;
filename PDTXTHOB "&PATHNAME.\SASData\PDHO_&SUFX..TXT";  *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * ---    PROGRAM: PDI_HOSP_STRATIFIED.SAS - STRATIFIED RATES     --- ;
 * ------------------------------------------------------------------ ;
 
 * ------------------------------------------------------------------ ;
 * ---   SET LOCATION OF PDI_HOSP_STRATIFIED.SAS OUTPUT DATA      --- ;
 * ------------------------------------------------------------------ ;
libname OUTST "&PATHNAME.\SASData";                *<==USER may modify;

 * ------------------------------------------------------------------ ;
 * --- NAME SAS DATASET OUTPUT FROM PROGRAM PDI_HOSP_STRATIFIED.SAS-- ;
 * --- SUMMARY OUTPUT FILE OF HOSPITAL RATES BY RISK CATEGORY.    --- ;
 * ------------------------------------------------------------------ ;
%LET  OUTFILE_STRAT = PDSTRAT_&SUFX.;             *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_STRAT   --- ;  
 * --- SHOULD BE GENERATED FOR  EXPORT INTO A SPREADSHEET.        --- ;
 * ---     0 = NO, 1 = YES.                                       --- ;
 * ------------------------------------------------------------------ ;
%LET TXTSTRAT=0;                                  *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,                 --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                          --- ;
 * ------------------------------------------------------------------ ;
filename PDTXTSTR "&PATHNAME.\SASData\PDST_&SUFX..TXT";  *<===USER may modify;

 * -------------------------------------------------------------------- ;
 * ---   PROGRAM: PDI_HOSP_RISKADJ.SAS - RISK-ADJUSTED RATES        --- ;
 * -------------------------------------------------------------------- ;
 
 * -------------------------------------------------------------------- ;
 * --- INDICATE THE LENGTH AND TYPE OF HOSPID ON THE DISCHARGE DATA --- ;
 * --- IF HOSPID IS NUMERIC, SET HOSP_TYP TO THE LENGTH OF HOSPID   --- ;
 * --- IF HOSPID IS ALPHANUMERIC, INCLUDE "$" PRIOR TO THE LENGTH   --- ;
 * --- THE DEFAULT VALUE OF HOSPID_TYP IS NUMERIC LENGTH 5          --- ;
 * --- THIS IS USED IN RISK-ADJUSTMENT ONLY                         --- ;
 * -------------------------------------------------------------------- ;
%LET HOSPID_TYP = 5;                               *<===USER MUST modify;
 
 * ------------------------------------------------------------------- ; 
 * --- SET LOCATION OF PDI_HOSP_RISKADJ.SAS OUTPUT DATA            --- ;
 * ------------------------------------------------------------------- ;
libname OUTHRISK "&PATHNAME.\SASData";             *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET NAME OF RISK ADJUSTMENT PARAMETERS DIRECTORY           --- ;
 * ------------------------------------------------------------------ ;
%LET HQIRADIR = &PATHNAME.\ParmFiles;                *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET NAME OF PDI_HOSP_RISKADJ.SAS OUTPUT FILE               --- ;
 * ------------------------------------------------------------------ ;
%LET OUTFILE_HOSPRISK = PDHRSKADJ_&SUFX.;         *<===USER may modify;

 * ----------------------------------------------------------------- ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_HOSPRISK - ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.        --- ;
 * ---    0 = NO, 1 = YES.                                       --- ;
 * ----------------------------------------------------------------- ;
%LET TXTHRISK=0;                                 *<===USER may modify;

 * ----------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,                --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                         --- ;
 * ----------------------------------------------------------------- ;
filename PDTXTHRA "&PATHNAME.\SASData\PDHRSKADJ_&SUFX..TXT"; *<===USER may modify;

 * ================================================================= ;
 * =========== AREA-LEVEL PEDIATRIC QUALITY INDICATORS ============= ;
 * ================================================================= ;
 
 * ----------------------------------------------------------------- ;
 * ---     PROGRAM: PDI_AREA_OBSERVED.SAS - OBSERVED RATES      ---  ;
 * ----------------------------------------------------------------  ;
 
 * ----------------------------------------------------------------  ;
 * ---     SET LOCATION OF PDI_AREA_OBSERVED.SAS OUTPUT DATA    ---  ;
 * ----------------------------------------------------------------  ;
libname OUTAOBS "&PATHNAME.\SASData";            *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- TYPELVLA indicates the levels (or _TYPE_) of             --- ;
 * --- summarization to be kept in the output.                  --- ;
 * ---                                                          --- ;
 * ---  TYPELVLA      stratification                            --- ;
 * ---  --------  -------------------------                     --- ;
 * ---     0      overall                                       --- ;
 * ---     1                           race                     --- ;
 * ---     2                     sex                            --- ;
 * ---     3                     sex * race                     --- ;
 * ---     4               age                                  --- ;
 * ---     5               age *       race                     --- ;
 * ---     6               age * sex                            --- ;
 * ---     7               age * sex * race                     --- ;
 * ---     8       area                                         --- ;
 * ---     9       area  *             race                     --- ;
 * ---    10       area  *       sex                            --- ;
 * ---    11       area  *       sex * race                     --- ;
 * ---    12       area  * age                                  --- ;
 * ---    13       area  * age *       race                     --- ;
 * ---    14       area  * age * sex                            --- ;
 * ---    15       area  * age * sex * race                     --- ;
 * ---                                                          --- ;
 * --- The default TYPELVLA (0,8) will provide an overall       --- :
 * --- total and an area-level total.                           --- ;
 * ---------------------------------------------------------------- ;
%LET TYPELVLA = IN (0,8);                       *<===USER may modify;

 * ------------------------------------------------------------------;
 * --- NAME OF SAS DATASET OUTPUT FROM PROGRAM PDI_AREA_OBSERVED.SAS ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED AREA RATES.               --- ;
 * ----------------------------------------------------------------- ;
%LET  OUTFILE_AREAOBS = PDAO_&SUFX.;             *<===USER may modify;

 * ----------------------------------------------------------------- ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_AREAOBS -- ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.        --- ;
 * ---    0 = NO, 1 = YES.                                       --- ;
 * ----------------------------------------------------------------- ;
%LET TXTAOBS=0;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,               --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                        --- ;
 * ---------------------------------------------------------------- ;
filename PDTXTAOB "&PATHNAME.\SASData\PDAO_&SUFX..TXT";  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---   PROGRAM: PDI_AREA_RISKADJ.SAS - RISK-ADJUSTED RATES    --- ;
 * ---------------------------------------------------------------- ;
 
 * ---------------------------------------------------------------- ;
 * ---   SET LOCATION OF PDI_AREA_RISKADJ.SAS OUTPUT DATA       --- ;
 * ---------------------------------------------------------------- ;
libname OUTARSK "&PATHNAME.\SASData";           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- TO USE SOCIOECONOMIC STATUS IN AREA RISK ADJUSTMENT      --- ;
 * --- SET USE_SES=1 BELOW.                                     --- ;
 * ---------------------------------------------------------------- ;
%LET USE_SES = 0;                               *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF RISK ADJUSTMENT PARAMETERS DIRECTORY         --- ;
 * ---------------------------------------------------------------- ;
%LET AQIRADIR = &PATHNAME.\ParmFiles;           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- NAME SAS DATASET OUTPUT FROM PROGRAM PDI_AREA_RISKADJ.SAS--- ;
 * --- AREA LEVEL OUTPUT FILE.                                  --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_AREARISK = PDARSKADJ_&SUFX.;       *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF YOU WANT TO CREATE A COMMA-DELIMITED TEXT    --- ;
 * --- FILE OF OUTFILE_AREARISK FOR EXPORT INTO A SPREADSHEET.  --- ;
 * ---    0 = NO, 1 = YES.                                      --- ;
 * ---------------------------------------------------------------- ;
%LET TXTARSK = 0;                               *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,               --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                        --- ;
 * ---------------------------------------------------------------- ;
filename PDTXTARA "&PATHNAME.\SASData\PDARSKADJ_&SUFX..TXT"; *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE WHETHER THE MEASURES SHOULD BE REPORTED PER     --- ;
 * --- 1,000 DISCHARGES FOR HOSPITAL LEVEL OUTPUT TEXT FILES OR --- ;
 * --- PER 100,000 POPULATION FOR AREA LEVEL OUTPUT TEXT FILES. --- ;
 * --- 0 = NO, 1 = YES                                          --- ;
 * ---------------------------------------------------------------- ;
%LET SCALE_RATES = 0;                           *<===USER may modify;

 
************************* Programs to execute ********************************* ;
 * ---------------------------------------------------------------------------- ;
 * --- SET FLAGS TO RUN INDIVIDUAL PROGRAMS WHEN CONTROL PROGRAM RUNS.      --- ;
 * --- 0 = NO, 1 = YES                                                      --- ;
 * ---------------------------------------------------------------------------- ;
%LET EXE_FMT =  0;  * Format Library created if not present. Set to 1 if replacing existing library;
%LET EXE_MSR =  1;  * Execute PDI_ALL_MEASURES program; 
%LET EXE_HOBS = 1;  * Execute PDI_HOSP_OBSERVED program; 
%LET EXE_HSTR = 1;  * Execute PDI_HOSP_STRATIFIED program;
%LET EXE_HRSK = 1;  * Execute PDI_HOSP_RISKADJ program;
%LET EXE_AOBS = 1;  * Execute PDI_AREA_OBSERVED program;
%LET EXE_ARSK = 1;  * Execute PDI_AREA_RISKADJ program;


************************* END USER INPUT ***************************************;
* --- Include standard diagnosis and procedure macros.                      --- ;
%include MacLib(PDI_Dx_Pr_Macros_v2024.sas);

* --- Check the values of the macro variables                               --- ;
* --- If the user-provided values are out of range, the software will abort --- ;
* --- MDC_PROVIDED: 0, 1                                                    --- ;
* --- PRDAY:        0, 1                                                    --- ;
 %check_macroval;

* --- Execute Macro to run Measure and Observed rate calculations.          --- ;
%PROG_EXE(&PATHNAME.,&EXE_FMT.,&EXE_MSR.,&EXE_HOBS.,&EXE_HSTR.,&EXE_HRSK.,&EXE_AOBS.,&EXE_ARSK.);
