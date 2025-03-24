* ======================= PROGRAM: PQI_AREA_CONTROL.SAS ======================= ;
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
* ============================================================================= ;
* The Prevention Quality Indicator (PQI) module of the AHRQ Quality
  Indicators software includes the following programs:
   
   1. PQI_AREA_CONTROL.SAS    Assigns user inputs required by other programs
                              and optional output options.  
                        
   2. PQI_AREA_FORMATS.SAS    Creates SAS format library used by other programs.

   3. PQI_AREA_MEASURES.SAS   Assigns Prevention Quality Indicators to inpatient records. 
							  Refer to technical specification documents for details. 

   4. PQI_AREA_OBSERVED.SAS   Calculates observed rates for area-level indicators.

   5. PQI_AREA_RISKADJ.SAS    Calculates risk adjusted rates for area level indicators. 

 * The software also requires the following files:
 
   1. discharges.sas7bdat  User supplied discharge level file organized according 
                           to the layout in the software instructions.
                           The file name is up to the user but must be listed below.
                            
   2. PQI_Dx_Pr_Macros_v2024.SAS Standard processes used by the other SAS programs.
                                 The user does not need to open.
                            
   3. 2000-2023_Population_Files_v2024.txt  Population file with counts by area, age, and sex.
                                            Required for area rate calculation. Available as a 
                                            separate download from the AHRQ website.

   4. PQI_AREA_Sigvar_Array_v2024.SAS  File with noise and signal variance estimates 
                                       and reference rates for smoothing by age and sex.

   5. PQI_AREA_Sigvar_Array_SES_v2024.SAS  File with noise and signal variance estimates 
                                           and reference rates for smoothing by age, sex and SES.

   6. PQI_AREA_OE_Array_v2024.SAS  Array for OE ratio adjustment from reference population 
                                   based on risk adjustment models. The software provides 
                                   two options to use OE ratio adjustment.

   7. PQI_AREA_OE_Array_SES_v2024.SAS  Array for OE ratio adjustment from reference population 
                                       based on risk adjustment models. The software provides 
                                       two options to use OE ratio adjustment by age, sex and SES. 
        
***************************************************************************** ;
******************************* PLEASE READ ********************************* ;
***************************************************************************** ;
 * The AHRQ Quality Indicator software is intended for use with discharges
   coded according to the standards in place at the date of the discharge. 
   Discharges should be classified under the ICD-10-CM/PCS specifications 
   effective 10/1/2015. Although results can be generated with inputs coded 
   under ICD9 and converted to ICD10 with General Equivalence Mappings, the 
   mapping process may produce unrepresentative results. ICD10 observed rate 
   calculations should not be used to produce ICD9 risk adjusted outputs.
   
 * The USER MUST modify portions of the following code in order to
   run this software.  The only changes necessary to run
   this software are changes in this program (PQI_AREA_CONTROL.SAS). 
   The modifications include such items as specifying the name and location
   of the input data set, the year of population data to be used, and the 
   name and location of output data sets.
 
 * NOTE:  PQI_AREA_CONTROL.SAS provides the option to read data in and write 
          data out to different locations.  For example, "libname INMSR" points
          to the location of the input data set for the PQI_AREA_MEASURES program
          and "libname OUTMSR" points to the location of the output data set
          created by the PQI_AREA_MEASURES program.  The location and file name of 
          each input and output can be assigned separately below. The default 
          values will place output in a SASData folder with standard names for
          each file based on the location of the PQI folder listed in the 
          PATHNAME variable.
          
 * See the AHRQ_PQI_SAS_v2024_ICD10_Release_Notes.txt file for version change details.

 Generally speaking, a first-time user of this software would proceed 
 as outlined below:

    1.  Modify and save all required user inputs in PQI_AREA_CONTROL.SAS. (This program - MUST be done.)

    2.  Select the programs to run by updating the flags (EXE_FMT, EXE_MSR, EXE_AOBS, EXE_ARSK).
        The default option will run all programs. Programs must be run in order and will not execute if 
        the required input is not available. See log for details. 

    3.  Run (submit) the PQI_AREA_CONTROL.SAS. (MUST be done.) 
    
 * ---------------------------------------------------------------- ;
 * --------------    INPUTS FOR ALL PROGRAMS    ------------------- ;
 * ---------------------------------------------------------------- ;

*PATHNAME specifies the location of the PQI folder which includes the
          Programs, Macros, and SASData subfolders;
%LET PATHNAME= C:\Pathname\PQI;                *<===USER MUST modify;

*DISFOLDER specifies the folder that contains the discharge data;
%LET DISFOLDER=C:\Pathname;                    *<===USER MUST modify;

*DISCHARGE specifies the name of the discharge data file;
%LET DISCHARGE= discharges;                    *<===USER MUST modify;

*SUFX specifies an identifier suffix to be placed on output datasets;
%LET SUFX =  v2024;                             *<===USER may modify;

*LIBRARY is where formats generated by PQI_AREA_FORMATS will be saved.;
libname LIBRARY  "&PATHNAME.\SASData";          *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF COUNTY-LEVEL AREAS SHOULD BE CONVERTED TO    --- ;
 * --- METROPOLITAIN AREAS                                      --- ;
 * ---     0 - County level with U.S. Census FIPS               --- ;
 * ---     1 - County level with Modified FIPS                  --- ;
 * ---     2 - Metro Area level with OMB 1999 definition        --- ;
 * ---     3 - Metro Area level with OMB 2003 definition        --- ;
 * ---------------------------------------------------------------- ;
%LET MALEVL = 0;                                *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SELECT THE POPULATION DATA FOR THE YEAR THAT BEST MATCHES -- ; 
 * --- THE DISCHARGE DATA. POPYEAR WILL IDENTIFY POPULATION USED -- ;
 * --- BY THE PQI_AREA_OBSERVED AND PQI_AREA_RISKADJ PROGRAM     -- ;
 * ---------------------------------------------------------------- ;
%LET POPYEAR = 2023;   *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF POPULATION FILE                          --- ;
 * ---------------------------------------------------------------- ;
filename POPFILE  "&PATHNAME.\ParmFiles\2000-2023_Population_Files_v2024.txt"; *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF RECORDS SHOULD BE PRINTED AS SAS OUTPUT AT   --- ;
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

 *- --------------------------------------------------------------- ;
 * --- ADD OPTION TO COMPRESS OUTPUT.                           --- ;
 * --- RECOMMENDED WITH LARGE FILES. TO RESTORE, RUN:           --- ;
 * --- options compress = no                                    --- ;
 * ---------------------------------------------------------------- ;
options compress = YES ;                        *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF SAS MACRO LIBRARY                        --- ;
 * ---------------------------------------------------------------- ;
filename MacLib "&PATHNAME.\Macros" ;           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---              PROGRAM : PQI_AREA_MEASURES.SAS             --- ;
 * ---------------------------------------------------------------- ;
 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PQI_AREA_MEASURES.SAS INPUT DATA         --- ;
 * ---------------------------------------------------------------- ;
libname INMSR  "&DISFOLDER.";                    *<==USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PQI_AREA_MEASURES.SAS OUTPUT DATA        --- ;
 * ---------------------------------------------------------------- ;
libname OUTMSR "&PATHNAME.\SASData";             *<==USER may modify;
 
 * ---------------------------------------------------------------- ;
 * --- SET NAME OF OUTPUT FILE FROM PQI_AREA_MEASURES.SAS       --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_MEAS = PQMSR_&SUFX.;               *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE ADDITIONAL INPUT VARIABLES TO KEEP ON OUTPUT    --- ;
 * --- DATA FILE FROM PQI_AREA_MEASURES.SAS.                    --- ;
 * --- INPUT VARIABLES ALWAYS INCLUDED ON THE OUTPUT FILE ARE:  --- ;
 * --- KEY DRG MDC YEAR DQTR AGE SEX                            --- ;
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
 * --- CREATE PERMANENT SAS DATASET TO STORE RECORDS THAT WILL  --- ;
 * --- NOT BE INCLUDED IN CALCULATIONS BECAUSE KEY VARIABLE     --- ;
 * --- VALUES ARE MISSING.  THIS DATASET SHOULD BE REVIEWED     --- ;
 * --- AFTER RUNNING PQI_AREA_MEASURES.                         --- ;
 * ---------------------------------------------------------------- ;
%LET DELFILE  = PQI_DELETED_&SUFX.;             *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---     PROGRAM: PQI_AREA_OBSERVED.SAS - OBSERVED RATES      --- ;
 * ---------------------------------------------------------------- ;
 * ---------------------------------------------------------------- ;
 * ---    SET LOCATION OF PQI_AREA_OBSERVED.SAS OUTPUT DATA     --- ;
 * ---------------------------------------------------------------- ;
libname OUTAOBS "&PATHNAME.\SASData";           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- TYPELVLA indicates the levels (or _TYPE_) of             --- ;
 * --- summarization to be kept in the output.                  --- ;
 * ---                                                          --- ;
 * ---  TYPELVLA      stratification                            --- ;
 * ---  --------  -------------------------                     --- ;
 * ---     0      OVERALL                                       --- ;
 * ---     1                           RACE                     --- ;
 * ---     2                     SEX                            --- ;
 * ---     3                     SEX * RACE                     --- ;
 * ---     4               AGE                                  --- ;
 * ---     5               AGE *       RACE                     --- ;
 * ---     6               AGE * SEX                            --- ;
 * ---     7               AGE * SEX * RACE                     --- ;
 * ---     8       AREA                                         --- ;
 * ---     9       AREA  *             RACE                     --- ;
 * ---    10       AREA  *       SEX                            --- ;
 * ---    11       AREA  *       SEX * RACE                     --- ;
 * ---    12       AREA  * AGE                                  --- ;
 * ---    13       AREA  * AGE *       RACE                     --- ;
 * ---    14       AREA  * AGE * SEX                            --- ;
 * ---    15       AREA  * AGE * SEX * RACE                     --- ;
 * ---                                                          --- ;
 * --- The default TYPELVLA (0,8) will provide an overall       --- :
 * --- total and an area-level total.                           --- ;
 * ---------------------------------------------------------------- ;
%LET TYPELVLA = IN (0,8);                       *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- NAME SAS DATASET OUTPUT FROM PQI_AREA_OBSERVED.SAS       --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED AREA RATES.              --- ;
 * ---------------------------------------------------------------- ;
%LET  OUTFILE_AREAOBS = PQAO_&SUFX.;            *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_AREAOBS-- ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.       --- ;
 * ---    0 = NO, 1 = YES.                                      --- ;
 * ---------------------------------------------------------------- ;
%LET TXTAOBS=0;                                 *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,                -- ;
 * ---  SPECIFY THE LOCATION OF THE FILE.                        -- ;
 * ---------------------------------------------------------------- ;
filename PQTXTAOB "&PATHNAME.\SASData\PQAO_&SUFX..TXT"; *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---    PROGRAM: PQI_AREA_RISKADJ.SAS - RISK-ADJUSTED RATES   --- ;
 * ---------------------------------------------------------------- ;
 
 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PQI_AREA_RISKADJ.SAS OUTPUT DATA         --- ;
 * ---------------------------------------------------------------- ; 
libname OUTARSK "&PATHNAME.\SASData";           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- TO USE SOCIOECONOMIC STATUS IN AREA RISK ADJUSTMENT      --- ;
 * --- SET USE_SES=1 BELOW.                                     --- ;
 * ---------------------------------------------------------------- ;
%LET USE_SES = 0;                               *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET NAME OF RISK ADJUSTMENT PARAMETERS DIRECTORY           --- ;
 * ------------------------------------------------------------------ ;
 %LET RADIR = &PATHNAME.\ParmFiles;                *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- NAME SAS DATASET OUTPUT FROM PQI_AREA_RISKADJ.SAS        --- ;
 * --- AREA LEVEL OUTPUT FILE.                                  --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_AREARISK = PQARSKADJ_&SUFX. ;      *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF YOU WANT TO CREATE A COMMA-DELIMITED         --- ;
 * ---  FILE OF OUTFILE_AREARISK FOR EXPORT INTO A SPREADSHEET. --- ;
 * ---    0 = NO, 1 = YES.                                      --- ;
 * ---------------------------------------------------------------- ;
%LET TXTARSK = 0;                               *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,               --- ;
 * ---  SPECIFY THE LOCATION OF THE FILE.                       --- ;
 * ---------------------------------------------------------------- ;
filename PQTXTARA "&PATHNAME.\SASData\PQARSKADJ_&SUFX..TXT";   *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE WHETHER THE MEASURES SHOULD BE REPORTED PER     --- ;
 * --- 100,000 POPULATION IN OUTPUT TEXT FILES: 0 = NO, 1 = YES --- ;
 * ---------------------------------------------------------------- ;
%LET SCALE_RATES = 0;                           *<===USER may modify;


************************* Programs to execute ********************************* ;
 * ---------------------------------------------------------------------------- ;
 * --- SET FLAGS TO RUN INDIVIDUAL PROGRAMS WHEN CONTROL PROGRAM RUNS.      --- ;
 * --- 0 = NO, 1 = YES                                                      --- ;
 * ---------------------------------------------------------------------------- ;
%LET EXE_FMT =  0;  * Format Library created if not present. Set to 1 if replacing existing library;
%LET EXE_MSR =  1;  * Execute PQI_AREA_MEASURES program; 
%LET EXE_AOBS = 1;  * Execute PQI_AREA_OBSERVED program;
%LET EXE_ARSK = 1;  * Execute PQI_AREA_RISKADJ program;


************************* END USER INPUT ***************************************;
* --- Include standard diagnosis and procedure macros.                      --- ;
%include MacLib(PQI_Dx_Pr_Macros_v2024.SAS);

* --- Execute Macro to run Measure and Observed rate calculations.          --- ;
%PROG_EXE(&PATHNAME.,&EXE_FMT.,&EXE_MSR.,&EXE_AOBS.,&EXE_ARSK.);
