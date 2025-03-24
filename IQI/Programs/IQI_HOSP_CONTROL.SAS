* =======================PROGRAM: IQI_HOSP_CONTROL.SAS ========================;
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
* =============================================================================;
* The Inpatient Quality Indicator (IQI) module of the AHRQ Quality
  Indicators software includes the following programs:
   
   1. IQI_HOSP_CONTROL.SAS   Assigns user inputs required by other programs
                             and optional output features.  
                             
   2. IQI_HOSP_FORMATS.SAS   Creates SAS format library used by other programs.
                             
   3. IQI_HOSP_MEASURES.SAS  Assigns numerator, denominator, and comorbidity flags for
                             Inpatient Quality Indicators.
                             Refer to technical specification documents for details. 
                             
   4. IQI_HOSP_OBSERVED.SAS  Calculates observed rates for hospital level indicators.

   5. IQI_HOSP_RISKADJ.SAS   Calculates risk adjusted rates for hospital level indicators.

   6. IQI_HOSP_COMPOSITE.SAS Calculates composite measures for hospital level indicators.

 * The software also requires the following files (all included except discharges):
 
  1. discharges.sas7bdat  User supplied discharge level file organized according 
                          to the software instructions.
                          The file name is up to the user but must be listed below.
                     
  2. IQI_HOSP_Dx_Pr_Macros_v2024.sas  Standard processes used by the other SAS programs.
                                      The user does not need to open.

  3. IQI_HOSP_DXCCSR_Format_v2024.sas  Creates formats assigning diagnosis Clinical Classification 
                                     Software-Refined (CCSR) variables.

  4. IQI_HOSP_DXCCSR_Code_v2024.sas  Creates CCSR variables based on the presence of diagnoses.

  5. IQI_HOSP_PRCCSR_Format_v2024.sas  Creates formats assigning procedure Clinical Classification 
                                     Software-Refined (CCSR) variables.

  6. IQI_HOSP_PRCCSR_Code_v2024.sas  Creates CCSR variables based on the presence of procedures.
  
  7. IQI_HOSP_Regvars_v2024.sas Creates age, sex, flag variables for use by risk adjustment. 
  
  8. IQI_HOSP_Sigvar_Array_v2024.sas Arrays for signal variance and reference population rates used 
                                     by risk adjustment program.
  
  9. IQI_HOSP_Composite_Arrays_v2024.sas Arrays used in IQI_HOSP_COMPOSITE.SAS program.
  
 10. IQI_HOSP_Composite_Wt_v2024.sas Provides weights for composite measures.

 11. IQI_HOSP_OE_Array_v2024.sas  Array for OE ratio adjustment from reference population 
                                  based on risk adjustment models. 
                                  The software provides two options to use OE ratio adjustment.

***************************************************************************** ;
******************************* PLEASE READ ********************************* ;
***************************************************************************** ;

  * The AHRQ Quality Indicator software is intended for use with discharges
   coded according to the standards in place on the date of the discharge. 
   Discharges should be classified under the ICD-10-CM/PCS specifications 
   effective on or after 10/1/2015. All diagnosis codes require a corresponding Present
   on Admission, POA, value coded according to UB04 standards. 
   Although results can be generated with inputs coded under ICD9 and 
   converted to ICD10 with General Equivalence Mappings, the mapping process
   may produce unrepresentative results. ICD10 observed rate calculations
   should not be used to produce ICD9 risk adjusted outputs.
 
 * The USER MUST modify portions of the following code in order to
   run this software.  The only changes necessary to run
   this software are changes in this program (IQI_HOSP_CONTROL.SAS). 
   The modifications include such items as specifying the name and location
   of the input data set, the year of population data to be used, and the 
   name and location of output data sets.
 
 * NOTE: IQI_HOSP_CONTROL.SAS provides the option to read data in and write 
         data out to different locations.  For example, "libname INMSR" points
         to the location of the input data set for the IQI_HOSP_MEASURES program
         and "libname OUTMSR" points to the location of the output data set
         created by the IQI_HOSP_MEASURES program. The location and file name of 
         each input and output can be assigned separately below. The default 
         values will place output in a SASData folder with standard names for
         each file based on the location of the IQI folder listed in the 
         PATHNAME variable.

 * NOTE: Beginning with v2022, APR-DRGs and Risk of Mortality (ROM) scores 
         have been substituted by AHRQ's Clinical Classifications Software 
         Refined (CCSR) for ICD-10-CM Diagnoses and ICD-10-PCS Procedures.
         IQI risk adjustment no longer requires APR-DRG or ROM 
         values on the discharge input file.
         
 * See the AHRQ_IQI_SAS_v2024_ICD10_Release_Notes.txt file for version change details.

 Generally speaking, a first-time user of this software would proceed 
 as outlined below:

    1.  Modify and save all required user inputs in IQI_HOSP_CONTROL.SAS. (This program - MUST be done.)

    2.  Select the programs to run by updating the flags (EXE_FMT,EXE_MSR, EXE_HOBS, EXE_HRSK, EXE_HCMP).
        The default option will run all programs. Programs must be run in order and will not execute if 
        the required input is not available. See log for details. 

    3.  Run (submit) the IQI_HOSP_CONTROL.SAS. (MUST be done.) 

 * ------------------------------------------------------------------ ;
 * ---                 INPUTS FOR ALL PROGRAMS                    --- ;
 * ------------------------------------------------------------------ ;

*PATHNAME specifies the location of the IQI folder which includes the
          Programs, Macros, ParmFiles, and SASData subfolders;
%LET PATHNAME=C:\Pathname\IQI;                   *<===USER MUST modify;

*DISFOLDER specifies the folder that contains the discharge data;
%LET DISFOLDER=C:\Pathname;                      *<===USER MUST modify;

*DISCHARGE specifies the name of the discharge data file;
%LET DISCHARGE=discharges;                       *<===USER MUST modify;

*SUFX specifies an identifier suffix to be placed on output datasets;
%LET SUFX =v2024;                                 *<===USER may modify;

*LIBRARY is where formats generated by IQI_HOSP_FORMATS will be saved;
libname LIBRARY  "&PATHNAME.\SASData";           *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE IF RECORDS SHOULD BE PRINTED IN SAS OUTPUT AT     --- ;
 * --- END OF EACH PROGRAM.  0 = NO, 1 = YES                      --- ;
 * ------------------------------------------------------------------ ;
%LET PRINT = 0;                                   *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE IF O_E RATIO ADJUSTMENT IS FROM REFERENCE POPULATION  ;
 * --- 1 = YES, DEFAULT AND RECOMMENDED                           --- ;
 * --- 0 = NO,  O_E RATIOS BASED ON USER DATA WILL BE CALCULATED  --- ; 
 * ---         AND USED. USE WITH CAUTION.                        --- ;
 * ------------------------------------------------------------------ ;
%LET Calibration_OE_to_ref_pop = 1;               *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- ADD OPTION TO COMPRESS OUTPUT. RECOMMENDED WITH            --- ;
 * --- LARGE FILES. TO RESTORE RUN:                               --- ;
 * ---   options compress = no                                    --- ;
 * ------------------------------------------------------------------ ;
options compress = YES;                           *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF SAS MACRO LIBRARY                          --- ;
 * ------------------------------------------------------------------ ;
filename MacLib "&PATHNAME.\Macros";              *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * ---              PROGRAM: IQI_HOSP_MEASURES.SAS                --- ;
 * ------------------------------------------------------------------ ;
 
 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF IQI_HOSP_MEASURES.SAS INPUT DATA           --- ;
 * ------------------------------------------------------------------ ;
libname INMSR  "&DISFOLDER.";                      *<==USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF IQI_HOSP_MEASURES.SAS OUTPUT DATA          --- ;
 * ------------------------------------------------------------------ ;
libname OUTMSR "&PATHNAME.\SASData";               *<==USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET NAME OF OUTPUT FILE FROM IQI_HOSP_MEASURES.SAS         --- ;
 * ------------------------------------------------------------------ ;
%LET OUTFILE_MEAS = IQMSR_&SUFX.;                 *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE ADDITIONAL INPUT VARIABLES TO KEEP ON OUTPUT      --- ;
 * --- DATA FILE FROM IQI_HOSP_MEASURES.SAS.                      --- ;
 * --- INPUT VARIABLES ALWAYS INCLUDED ON THE OUTPUT FILE ARE:    --- ;
 * --- KEY HOSPID DRG MDC SEX AGE YEAR DQTR                       --- ;
 * ------------------------------------------------------------------ ;
%LET OUTFILE_KEEP = ;                             *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- MODIFY INPUT AND OUTPUT FILE                               --- ;
 * ------------------------------------------------------------------ ;
 * --- PROGRAM DEFAULT ASSUMES THERE ARE                          --- ;
 * ---     35 DIAGNOSES (DX1-DX35)                                --- ;
 * ---     30 PROCEDURES (PR1-PR30)                               --- ;
 * ------------------------------------------------------------------ ;
 * --- MODIFY NUMBER OF DIAGNOSIS AND PROCEDURE VARIABLES TO      --- ;
 * --- MATCH USER DISCHARGE INPUT DATA.                           --- ;
 * --- VALUES MUST BE GREATER THAN ZERO.                          --- ;
 * ------------------------------------------------------------------ ;
%LET NDX = 35;                                    *<===USER may modify;
%LET NPR = 30;                                    *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE WHETHER DISCHARGES INCLUDE MDC DATA               --- ;
 * ---     1 = DATA HAS MDC FROM CMS MS-DRG GROUPER (DEFAULT)     --- ;
 * ---         MDC SHOULD NOT BE IMPUTED OR MAPPED FROM MS-DRGS   --- ;
 * ---         RECORDS SHOULD HAVE AN MDC BETWEEN 01 AND 25       --- ;
 * ---     0 = DATA HAS MDC WITH ALL MISSING VALUES               --- ;
 * --- MDC_PROVIDED = 0 WILL SUPPRESS RISK-ADJUSTED RATES         --- ;
 * ------------------------------------------------------------------ ;
%LET MDC_PROVIDED = 1;                            *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * - INDICATE WHETHER DATA REGARDING THE NUMBER OF DAYS           --- ;
 * - FROM ADMISSION TO PROCEDURE (PRDAY) IS AVAILABLE             --- ;
 * -      0 = PRDAY IS NOT INCLUDED                               --- ;
 * -      1 = PRDAY IS INCLUDED                                   --- ;
 * - PRDAY = 0 WILL SUPPRESS RISK-ADJUSTED RATES FOR THE          --- ;
 * - FOLLOWING INDICATORS REQUIRING PRDAY FOR PRCCSR CALCULATION  --- ;
 * - IQI 08, IQI 09, IQI 11, IQI 12, IQI 30, IQI 31               --- ;
 * ------------------------------------------------------------------ ;
%LET PRDAY  = 1;                                  *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * - CREATE PERMANENT SAS DATASET TO STORE RECORDS THAT WILL      --- ;
 * - NOT BE INCLUDED IN CALCULATIONS BECAUSE KEY VARIABLE         --- ;
 * - VALUES ARE MISSING.  THIS DATASET SHOULD BE REVIEWED AFTER   --- ;
 * - RUNNING IQI_HOSP_MEASURES.SAS.                               --- ;
 * ------------------------------------------------------------------ ;
%LET DELFILE  = IQI_DELETED_&SUFX.;               *<===USER may modify;
 
 * ------------------------------------------------------------------ ;
 * ---       PROGRAM: IQI_HOSP_OBSERVED.SAS - OBSERVED RATES      --- ;
 * ------------------------------------------------------------------ ;
 
 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF IQI_HOSP_OBSERVED.SAS OUTPUT DATA          --- ;
 * ------------------------------------------------------------------ ;
libname OUTHOBS "&PATHNAME.\SASData";             *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- TYPELVLH indicates the levels (or _TYPE_) of               --- ;
 * --- summarization to be kept in the output.                    --- ;
 * ---                                                            --- ;
 * ---  TYPELVLH      Stratification                              --- ;
 * ---  --------  ------------------------------------            --- ;
 * ---     0      overall                                         --- ;
 * ---     1                                      race            --- ;
 * ---     2                              payer                   --- ;
 * ---     3                              payer * race            --- ;
 * ---     4                        sex                           --- ;
 * ---     5                        sex         * race            --- ;
 * ---     6                        sex * payer                   --- ;
 * ---     7                        sex * payer * race            --- ;
 * ---     8                  age                                 --- ;
 * ---     9                  age               * race            --- ;
 * ---    10                  age       * payer                   --- ;
 * ---    11                  age       * payer * race            --- ;
 * ---    12                  age * sex                           --- ;
 * ---    13                  age * sex         * race            --- ;
 * ---    14                  age * sex * payer                   --- ;
 * ---    15                  age * sex * payer * race            --- ;
 * ---    16       hospital                                       --- ;
 * ---    17       hospital                     * race            --- ;
 * ---    18       hospital             * payer                   --- ;
 * ---    19       hospital             * payer * race            --- ;
 * ---    20       hospital       * sex                           --- ;
 * ---    21       hospital       * sex         * race            --- ;
 * ---    22       hospital       * sex * payer                   --- ;
 * ---    23       hospital       * sex * payer * race            --- ;
 * ---    24       hospital * age                                 --- ;
 * ---    25       hospital * age               * race            --- ;
 * ---    26       hospital * age       * payer                   --- ;
 * ---    27       hospital * age       * payer * race            --- ;
 * ---    28       hospital * age * sex                           --- ;
 * ---    29       hospital * age * sex         * race            --- ;
 * ---    30       hospital * age * sex * payer                   --- ;
 * ---    31       hospital * age * sex * payer * race            --- ;
 * ---                                                            --- ;
 * --- The default TYPELVLH (0,16) will provide overall and       --- ;
 * --- hospital-level risk-adjusted rates, smoothed rates, and    --- ;
 * --- corresponding variance estimates. For more granular        --- ;
 * --- TYPELVLH that include stratifiers, only risk-adjusted      --- ;
 * --- rates and variance are calculated. However, the user       --- ;
 * --- should note that any stratification that includes age or   --- ;
 * --- sex are not supported because these factors are included   --- ;
 * --- as covariates in risk adjustment. Thus risk-adjusted       --- ;
 * --- rates for stratifiers that include age or sex are          --- ;
 * --- suppressed from the output.                                --- ;
 * ------------------------------------------------------------------ ;
%LET TYPELVLH = IN (0,16);                        *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- NAME OF SAS DATASET OUTPUT FROM IQI_HOSP_OBSERVED.SAS      --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED HOSPITAL RATES.            --- ;
 * ------------------------------------------------------------------ ;
%LET  OUTFILE_HOSPOBS = IQHO_&SUFX.;              *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_HOSPOBS --- ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.         --- ;
 * ---    0 = NO, 1 = YES.                                        --- ;
 * ------------------------------------------------------------------ ;
%LET TXTHOBS=0;                                   *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,                 --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                          --- ;
 * ------------------------------------------------------------------ ;
filename IQTXTHOB "&PATHNAME.\SASData\IQHO_&SUFX..TXT"; *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * ---   Program: IQI_HOSP_RISKADJ.SAS - RISK-ADJUSTED RATES      --- ;
 * ------------------------------------------------------------------ ;

 * -------------------------------------------------------------------- ;
 * --- INDICATE THE LENGTH AND TYPE OF HOSPID ON THE DISCHARGE DATA --- ;
 * --- IF HOSPID IS NUMERIC, SET HOSP_TYP TO THE LENGTH OF HOSPID   --- ;
 * --- IF HOSPID IS ALPHANUMERIC, INCLUDE "$" PRIOR TO THE LENGTH   --- ;
 * --- THE DEFAULT VALUE OF HOSPID_TYP IS NUMERIC LENGTH 5          --- ;
 * --- THIS IS USED IN RISK-ADJUSTMENT ONLY                         --- ;
 * -------------------------------------------------------------------- ;
%LET HOSPID_TYP = 5;                               *<===USER MUST modify;

 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF IQI_HOSP_RISKADJ.SAS OUTPUT DATA           --- ;
 * ------------------------------------------------------------------ ;
libname OUTHRISK "&PATHNAME.\SASData";            *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET NAME OF RISK ADJUSTMENT PARAMETERS DIRECTORY           --- ;
 * ------------------------------------------------------------------ ;
%LET RADIR = &PATHNAME.\ParmFiles;                *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET NAME OF IQI_HOSP_RISKADJ.SAS OUTPUT FILE               --- ;
 * ------------------------------------------------------------------ ;
%LET  OUTFILE_HOSPRISK = IQHRSKADJ_&SUFX.;        *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_HOSPRISK--- ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.         --- ;
 * ---    0 = NO, 1 = YES.                                        --- ;
 * ------------------------------------------------------------------ ;
%LET TXTHRISK=0;                                  *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,                 --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                          --- ;
 * ------------------------------------------------------------------ ;
filename IQTXTHRA "&PATHNAME.\SASData\IQHRSKADJ_&SUFX..TXT";  *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * ---   Program: IQI_HOSP_COMPOSITE.SAS - COMPOSITE RATES        --- ;
 * ------------------------------------------------------------------ ;
 
 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF IQI_HOSP_COMPOSITE.SAS OUTPUT DATA         --- ;
 * ------------------------------------------------------------------ ;
libname OUTHCOMP "&PATHNAME.\SASData";            *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET NAME OF IQI_HOSP_COMPOSITE.SAS OUTPUT FILE             --- ;
 * ------------------------------------------------------------------ ;
%LET OUTFILE_COMP = IQCOMP_&SUFX.;                *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_COMP  --- ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.       --- ;
 * ---     0 = NO, 1 = YES.                                     --- ;
 * ---------------------------------------------------------------- ;
%LET TXTCOMP=0;                                 *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,               --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                        --- ;
 * ---------------------------------------------------------------- ;
filename IQTXTCMP "&PATHNAME.\SASData\IQCOMP_&SUFX..TXT"; *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE WHETHER THE MEASURES SHOULD BE REPORTED PER     --- ;
 * --- 1,000 DISCHARGES IN OUTPUT TEXT FILES : 0 = NO, 1 = YES. --- ;
 * ---------------------------------------------------------------- ;
%LET SCALE_RATES = 0;                           *<===USER may modify;


************************* Programs to execute ********************************* ;
 * ---------------------------------------------------------------------------- ;
 * --- SET FLAGS TO RUN INDIVIDUAL PROGRAMS WHEN CONTROL PROGRAM RUNS.      --- ;
 * --- 0 = NO, 1 = YES                                                      --- ;
 * ---------------------------------------------------------------------------- ;
%LET EXE_FMT  = 0;  * Format Library created if not present. Set to 1 if replacing existing library;
%LET EXE_MSR  = 1;  * Execute IQI_HOSP_MEASURES program; 
%LET EXE_HOBS = 1;  * Execute IQI_HOSP_OBSERVED program; 
%LET EXE_HRSK = 1;  * Execute IQI_HOSP_RISKADJ program;
%LET EXE_HCMP = 1;  * Execute IQI_HOSP_COMPOSITE program;


************************* END USER INPUT ***************************************;
* --- Include standard diagnosis and procedure macros.                      --- ;
%include MacLib(IQI_HOSP_Dx_Pr_Macros_v2024.sas);

* --- Check the values of the macro variables                               --- ;
* --- If the user-provided values are out of range, the software will abort --- ;
* --- MDC_PROVIDED: 0, 1                                                    --- ;
* --- PRDAY:        0, 1                                                    --- ;
 %check_macroval;

* --- Execute Control Program to run flagged programs.                      --- ;
%PROG_EXE(&PATHNAME.,&EXE_FMT.,&EXE_MSR.,&EXE_HOBS.,&EXE_HRSK.,&EXE_HCMP.);
