* ========================= PROGRAM: PQE_AREA_CONTROL.SAS ======================== ;
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
* ================================================================================ ;
* The Prevention Quality Indicator in Emergency Department Settings (PQE) module
  of the AHRQ Quality Indicators software includes the following programs:
   
   1. PQE_AREA_CONTROL.SAS    Assigns user inputs required by other programs
                              and optional output options.  
                        
   2. PQE_AREA_FORMATS.SAS    Creates SAS format library used by other programs.

   3. PQE_AREA_MEASURES.SAS   Assigns Prevention Quality Indicators to outpatient 
                              emergency department (ED) records. 
                              Refer to technical specification documents for details.
							  
   4. PQE_AREA_OBSERVED.SAS   Calculates observed rates for area-level indicators.

   5. PQE_AREA_RISKADJ.SAS    Calculates risk adjusted rates for area-level indicators. 

 * The software also requires the following files:
 
   1. discharges.sas7bdat  User supplied discharge level file organized according 
                           to the layout in the software instructions.
                           The file name is up to the user but must be listed below.
                            
   2. PQE_Dx_Macros_v2024.SAS Standard processes used by the other SAS programs.
                              The user does not need to open.
                            
   3. 2000-2023_Population_Files_v2024.txt  Population file with counts by area, age, and sex.
                                            Required for area rate calculation. Available as a 
                                            separate download from the AHRQ website.

   4. PQE_AREA_Sigvar_Array_v2024.SAS  File with noise and signal variance estimates 
                                       and reference rates for smoothing by age and sex.

   5. PQE_AREA_Sigvar_Array_SES_v2024.SAS  File with noise and signal variance estimates 
                                           and reference rates for smoothing by age, sex and
                                           socioeconomic status (SES).

   6. PQE_AREA_OE_Array_v2024.SAS  Array for observed/expected (OE) ratio adjustment from 
                                   reference population based on risk adjustment models. 
                                   The software provides two options to use OE ratio adjustment.

   7. PQE_AREA_OE_Array_SES_v2024.SAS  Array for OE ratio adjustment from reference population 
                                       based on risk adjustment models. The software provides 
                                       two options to use OE ratio adjustment by age, sex and SES. 
  
******************************************************************* ;
****************************PLEASE READ**************************** ;
******************************************************************* ;
 * The USER MUST modify portions of the following code in order to
   run this software.  The only changes necessary to run
   this software are changes in this program (PQE_AREA_CONTROL.SAS). 
   The modifications include such items as specifying the name and location
   of the input data set, the year of population data to be used, and the 
   name and location of output data sets.
 
* NOTE: PQE_AREA_CONTROL.SAS provides the option to read data in and write 
        data out to different locations.  For example, "libname INMSR" points
        to the location of the input data set for the PQE_AREA_MEASURES program
        and "libname OUTMSR" points to the location of the output data set
        created by the PQE_AREA_MEASURES program. The location and file name of 
        each input and output can be assigned separately below. The default 
        values will place output in a SASData folder with standard names for
        each file based on the location of the PQE folder listed in the 
        PATHNAME variable.

 * See the AHRQ_PQE_SAS_v2024_ICD10_Release_Notes.txt file for version change details.

 Generally speaking, a first-time user of this software would proceed 
 as outlined below:

    1.  Modify and save all required user inputs in PQE_AREA_CONTROL.SAS (This program - MUST be done.)

    2.  Select the programs to run by updating the flags (EXE_FMT, EXE_MSR, EXE_AOBS, EXE_ARSK).
        The default option will run all programs. Programs must be run in order and will not execute if 
        the required input is not available. See log for details. 

    3.  Run (submit) the PQE_AREA_CONTROL.SAS (MUST be done). 
	
 * ---------------------------------------------------------------- ;
 * --------------    INPUTS FOR ALL PROGRAMS    ------------------- ;
 * ---------------------------------------------------------------- ;
 
*PATHNAME specifies the location of the PQE folder which includes the
          Programs, Macros, and SASData subfolders;
%LET PATHNAME= C:\Pathname\PQE;                *<===USER MUST modify;      

*DISFOLDER specifies the folder that contains the discharge data;
%LET DISFOLDER=C:\Pathname;                    *<===USER MUST modify;

*DISCHARGE specifies the name of the discharge data file;
%LET DISCHARGE= discharges;                    *<===USER MUST modify;

*SUFX specifies an identifier suffix to be placed on output datasets;
%LET SUFX =  v2024;                             *<===USER may modify;

*LIBRARY is where formats generated by PQE_AREA_FORMATS will be saved.;
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
 * --- BY THE PQE_AREA_OBSERVED AND PQE_ARE_RISKADJ PROGRAMS.    -- ;
 * ---------------------------------------------------------------- ;
%LET POPYEAR = 2023;                            *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF POPULATION FILE                          --- ;
 * ---------------------------------------------------------------- ;
filename POPFILE  "&PATHNAME.\ParmFiles\2000-2023_Population_Files_v2024.txt";  *<===USER may modify; 

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF RECORDS SHOULD BE PRINTED AS SAS OUTPUT AT   --- ;
 * --- END OF EACH PROGRAM.  0 = NO, 1 = YES                    --- ;
 * ---------------------------------------------------------------- ;
 %LET PRINT = 0;                              *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF O_E RATIO ADJUSTMENT IS FROM REFERENCE POPULATION;
 * --- 1 = YES, DEFAULT AND RECOMMENDED                         --- ;
 * --- 0 = NO,  O_E RATIOS BASED ON USER DATA WILL BE CALCULATED--- ; 
 * ---          AND USED. USE WITH CAUTION.                     --- ;
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
filename MacLib "&PATHNAME.\Macros" ;           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IDENTIFY STATES WITH VALID REVISIT VARIABLES IN THE      --- ;
 * --- INPUT DATA YEAR.                                         --- ;
 * --- LEAVE BLANK IF REVISIT VARIABLES ARE NOT AVAILABLE.      --- ;
 * ---------------------------------------------------------------- ;
%LET StatesWithVisitlink_ = AK AR CA CO FL GA HI IA IN MA MD ME MO MS NE NY OR SC SD TN UT VT WI WY; *<===USER MUST MODIFY;

 * ---------------------------------------------------------------- ;
 * ---              PROGRAM : PQE_AREA_MEASURES.SAS             --- ;
 * ---------------------------------------------------------------- ;
 
 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PQE_AREA_MEASURES.SAS INPUT DATA         --- ;
 * ---------------------------------------------------------------- ;
libname INMSR  "&DISFOLDER.";                    *<==USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PQE_AREA_MEASURES.SAS OUTPUT DATA        --- ;
 * ---------------------------------------------------------------- ;
libname OUTMSR "&PATHNAME.\SASData";             *<==USER may modify;
 
 * ---------------------------------------------------------------- ;
 * --- SET NAME OF OUTPUT FILE FROM PQE_AREA_MEASURES.SAS       --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_MEAS = QEMSR_&SUFX.;               *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE ADDITIONAL INPUT VARIABLES TO KEEP ON OUTPUT    --- ;
 * --- DATA FILE FROM PQE_AREA_MEASURES.SAS.                    --- ;
 * --- INPUT VARIABLES ALWAYS INCLUDED ON THE OUTPUT FILE ARE:  --- ;
 * --- KEY PSTCO YEAR DQTR HOSPST VisitLink LOS DX1             --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_KEEP = ;                           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- MODIFY NUMBER OF DIAGNOSIS VARIABLES TO MATCH INPUT      --- ;
 * --- DISCHARGE DATA. VALUE MUST BE GREATER THAN ZERO.         --- ;
 * --- PROGRAM DEFAULT ASSUMES THERE ARE 35 DIAGNOSES (DX1-DX35) -- ;
 * ---------------------------------------------------------------- ;
%LET NDX = 35;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---     PROGRAM: PQE_AREA_OBSERVED.SAS - OBSERVED RATES      --- ;
 * ---------------------------------------------------------------- ;

 * ---------------------------------------------------------------- ;
 * ---    SET LOCATION OF PQE_AREA_OBSERVED.SAS OUTPUT DATA     --- ;
 * ---------------------------------------------------------------- ;
libname OUTAOBS "&PATHNAME.\SASData";           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- TYPELVLA indicates the levels (or _TYPE_) of             --- ;
 * --- summarization to be kept in the output.                  --- ;
 * ---                                                          --- ;
 * ---  TYPELVLA      stratification                            --- ;
 * ---  --------  -------------------------                     --- ;
 * ---     0      OVERALL                                       --- ;
 * ---     1                     SEX                            --- ;
 * ---     2               AGE                                  --- ;
 * ---     3               AGE * SEX                            --- ;
 * ---     4       AREA                                         --- ;
 * ---     5       AREA  *       SEX                            --- ;
 * ---     6       AREA  * AGE                                  --- ;
 * ---     7       AREA  * AGE * SEX                            --- ;
 * ---                                                          --- ;
 * --- The default TYPELVLA (0,4) will provide an overall       --- :
 * --- total and an area-level total.                           --- ;
 * ---------------------------------------------------------------- ;
%LET TYPELVLA = 0,4;                            *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- NAME SAS DATASET OUTPUT FROM PQE_AREA_OBSERVED.SAS       --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED AREA RATES.              --- ;
 * ---------------------------------------------------------------- ;
%LET  OUTFILE_AREAOBS = QEAO_&SUFX.;            *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_AREAOBS-- ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.       --- ;
 * ---    0 = NO, 1 = YES.                                      --- ;
 * ---------------------------------------------------------------- ;
%LET TXTAOBS=0;                                 *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,               --- ;
 * ---  SPECIFY THE LOCATION OF THE FILE.                       --- ;
 * ---------------------------------------------------------------- ;
filename QETXTAOB "&PATHNAME.\SASData\QEAO_&SUFX..TXT"; *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---    PROGRAM: PQE_AREA_RISKADJ.SAS - RISK-ADJUSTED RATES   --- ;
 * ---------------------------------------------------------------- ;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PQE_AREA_RISKADJ.SAS OUTPUT DATA         --- ;
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
 %LET RADIR = &PATHNAME.\ParmFiles;               *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- NAME SAS DATASET OUTPUT FROM PQE_AREA_RISKADJ.SAS        --- ;
 * --- AREA LEVEL OUTPUT FILE.                                  --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_AREARISK = QEARSKADJ_&SUFX. ;      *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF YOU WANT TO CREATE A COMMA-DELIMITED TEXT    --- ;
 * --- FILE OF OUTFILE_AREARISK FOR EXPORT INTO A SPREADSHEET   --- ;
 * ---    0 = NO, 1 = YES.                                      --- ;
 * ---------------------------------------------------------------- ;
%LET TXTARSK = 0;                               *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,               --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                        --- ;
 * ---------------------------------------------------------------- ;
filename QETXTARA "&PATHNAME.\SASData\QEARSKADJ_&SUFX..TXT";   *<===USER may modify;

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
%LET EXE_MSR =  1;  * Execute PQE_AREA_MEASURES program; 
%LET EXE_AOBS = 1;  * Execute PQE_AREA_OBSERVED program;
%LET EXE_ARSK = 1;  * Execute PQE_AREA_RISKADJ program;


************************* END USER INPUT ***************************************;
* --- Include standard diagnosis and procedure macros.                      --- ;
%include MacLib(PQE_Dx_Macros_v2024.SAS);

* --- Execute Macro to run Measure and Observed rate calculations.          --- ;
%PROG_EXE(&PATHNAME.,&EXE_FMT.,&EXE_MSR.,&EXE_AOBS.,&EXE_ARSK.);
