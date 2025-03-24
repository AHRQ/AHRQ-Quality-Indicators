*==================== PROGRAM: PSI17_HOSP_CONTROL.SAS ======================= ;
*  VERSION: SAS QI v2024
*  RELEASE DATE: JULY 2024
* =========================================================================== ;
* The Patient Safety Indicator PSI 17, BIRTH TRAUMA RATE - INJURY TO NEONATE,
  STAND ALONE module of the AHRQ Indicators software includes the following programs:

   1. PSI17_HOSP_CONTROL.SAS   Assigns user inputs required by other programs
                              and optional output options.

   2. PSI17_HOSP_FORMATS.SAS   Creates SAS format library used by other programs.

   3. PSI17_HOSP_MEASURES.SAS  Assigns numerator and denominator flags for PSI 17. 
							   Refer to technical specification documents for details. 

   4. PSI17_HOSP_OBSERVED.SAS Calculates population and observed rates for
                              hospital level indicator.

 * The software also requires the following files:

    1. discharges.sas7bdat    User supplied discharge level file organized according
                              to the layout in the software instructions.
                              The file name is up to the user but must be listed below.

    2. PSI17_HOSP_Dx_Px_Macros_v2024.sas Standard processes used by the other SAS programs.
                              The user does not need to open.

 * NOTE THAT THIS INDICATOR (PSI 17) IS ALSO INCLUDED IN THE PEDIATRIC QUALITY INDICATORS (PDI) MODULE.

***************************************************************************** ;
******************************* PLEASE READ ********************************* ;
***************************************************************************** ;
 * The AHRQ Quality Indicator software is intended for use with discharges
   coded according to the standards in place at the date of the discharge.
   Discharges should be classified under the ICD-10-CM/PCS specifications
   effective after 10/1/2015. All diagnosis codes require a corresponding Present
   on Admission (POA) value coded according to UB04 standards.
   Although results can be generated with inputs coded under ICD9 and
   converted to ICD10 with General Equivalence Mappings, the mapping process
   may produce unrepresentative results. ICD10 observed rate calculations
   should not be used to produce ICD9 risk adjusted outputs.

 * The USER MUST modify portions of the following code in order to
   run this software.  The only changes necessary to run
   this software are changes in this program (PSI17_HOSP_CONTROL.SAS).
   The modifications include such items as specifying the name and location
   of the input data set, the year of population data to be used, and the
   name and location of output data sets.

 * NOTE: PSI17_HOSP_CONTROL.SAS provides the option to read data in and write
         data out to different locations.  For example, "libname INMSR" points
         to the location of the input data set for the PSI17_HOSP_MEASURES program
         and "libname OUTMSR" points to the location of the output data set
         created by the PSI17_HOSP_MEASURES program.  The location and file name of
         each input and output can be assigned separately below. The default
         values will place output in a SASData folder with standard names for
         each file based on the location of the PSI17 folder listed in the
         PATHNAME variable.

  * NOTE: PSI 17 is calculated within the PDI module because it is based on 
          the number of births. This software package calculates PSI 17
          without the need to run the entire PDI software package. 
  
  * NOTE: PSI 17 is not risk adjusted.
  
  * See the AHRQ_PSI17_SAS_v2024_ICD10_Release_Notes.txt file for version change details.

 Generally speaking, a first-time user of this software would proceed 
 as outlined below:

    1.  Modify and save all required user inputs in PSI17_HOSP_CONTROL.SAS. (This program - MUST be done.)

    2.  Select the programs to run by updating the flags (EXE_FMT,EXE_MSR,EXE_HOBS,EXE_HSTR).
        The default option will run all programs. Programs must be run in order and will not execute if 
        the required input is not available. See log for details. 

    3.  Run (submit) the PSI17_HOSP_CONTROL.SAS. (MUST be done.) 

 * ---------------------------------------------------------------- ;
 * ---                 INPUTS FOR ALL PROGRAMS                  --- ;
 * ---------------------------------------------------------------- ;

*PATHNAME specifies the location of the PSI17 folder which includes the
          Programs, Macros, and SASData subfolders;
%LET PATHNAME=C:\Pathname\PSI17;               *<===USER MUST modify;

*DISFOLDER specifies the folder that contains the discharge data;
%LET DISFOLDER=C:\Pathname;                     *<===USER MUST modify;

*DISCHARGE specifies the name of the discharge data file;
%LET DISCHARGE=discharges;                     *<===USER MUST modify;

*SUFX specifies an identifier suffix to be placed on output datasets;
%LET SUFX = v2024;                              *<===USER may modify;

*LIBRARY is where formats generated by PSI17_HOSP_FORMATS will be saved.;
libname LIBRARY "&PATHNAME.\SASData";           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF RECORDS SHOULD BE PRINTED IN SAS OUTPUT AT   --- ;
 * --- END OF EACH PROGRAM.  0 = NO, 1 = YES                    --- ;
 * ---------------------------------------------------------------- ;
%LET PRINT = 0;                                 *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- ADD OPTIONS TO COMPRESS OUTPUT IN LOG.                   --- ;
 * --- RECOMMENDED WITH LARGE FILES. TO RESTORE, RUN:           --- ;
 * --- options compress = no                                    --- ;
 * ---------------------------------------------------------------- ;
options compress = YES ;                        *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF SAS MACRO LIBRARY                        --- ;
 * ---------------------------------------------------------------- ;
 filename MacLib "&PATHNAME.\Macros";           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---            PROGRAM: PSI17_HOSP_MEASURES.SAS              --- ;
 * ---------------------------------------------------------------- ;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PSI17_HOSP_MEASURES.SAS INPUT DATA       --- ;
 * ---------------------------------------------------------------- ;
libname INMSR  "&DISFOLDER.";                    *<==USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET LOCATION OF PSI17_HOSP_MEASURES.SAS OUTPUT DATA      --- ;
 * ---------------------------------------------------------------- ;
libname OUTMSR "&PATHNAME.\SASData";             *<==USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF OUTPUT FILE FROM PSI17_HOSP_MEASURES.SAS     --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_MEAS = PS17MSR_&SUFX.;              *<==USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE ADDITIONAL INPUT VARIABLES TO KEEP ON OUTPUT    --- ;
 * --- DATA FILE FROM PSI17_HOSP_MEASURES.SAS.                  --- ;
 * --- INPUT VARIABLES ALWAYS INCLUDED ON THE OUTPUT FILE ARE:  --- ;
 * --- KEY HOSPID DRG MDC YEAR DQTR AGE AGEDAY                  --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILE_KEEP = ;                           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- MODIFY INPUT AND OUTPUT FILE                             --- ;
 * ---------------------------------------------------------------- ;
 * --- PROGRAM DEFAULT ASSUMES THERE ARE                        --- ;
 * ---     35 DIAGNOSES (DX1-DX35)                              --- ;
 * ---------------------------------------------------------------- ;
 * --- MODIFY NUMBER OF DIAGNOSIS VARIABLES TO                  --- ;
 * --- MATCH USER DISCHARGE INPUT DATA.                         --- ;
 * --- VALUE MUST BE GREATER THAN ZERO.                         --- ;
 * ---------------------------------------------------------------- ; 
%LET NDX = 35;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE WHETHER DISCHARGES INCLUDE MDC DATA             --- ;
 * ---     1 = DATA HAS MDC FROM CMS MS-DRG GROUPER (DEFAULT)   --- ;
 * ---         MDC SHOULD NOT BE IMPUTED OR MAPPED FROM MS-DRGS --- ;
 * ---         RECORDS SHOULD HAVE AN MDC BETWEEN 01 AND 25     --- ;
 * ---     0 = DATA HAS MDC WITH ALL MISSING VALUES             --- ;
 * ---------------------------------------------------------------- ;
%LET MDC_PROVIDED = 1;                          *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * - CREATE PERMANENT SAS DATASET TO STORE RECORDS THAT WILL    --- ;
 * - NOT BE INCLUDED IN CALCULATIONS BECAUSE KEY VARIABLE       --- ;
 * - VALUES ARE MISSING.  THIS DATASET SHOULD BE REVIEWED AFTER --- ;
 * - RUNNING PSI17_HOSP_MEASURES.                               --- ;
 * ---------------------------------------------------------------- ; 
%LET DELFILE  = PSI17_DELETED_&SUFX.;           *<===USER may modify;


 * =================================================================;
 * ============HOSPTIAL-LEVEL PEDIATRIC QUALITY INDICATORS==========;
 * =================================================================;
 
 * ---------------------------------------------------------------- ;
 * ---             PROGRAM: PSI17_HOSP_OBSERVED.SAS             --- ;
 * ---------------------------------------------------------------- ;

libname OUTHOBS "&PATHNAME.\SASData";          *<===USER MUST modify;

 * ----------------------------------------------------------------------- ;
 * --- TYPELVLH indicates the levels (or _TYPE_) of                    --- ;
 * --- summarization to be kept in the output.                         --- ;
 * ---                                                                 --- ;
 * ---  TYPELVLH      Stratification                                   --- ;
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
 * --- The default TYPELVLH (0,64) will provide an overall             --- :
 * --- and hospital-level totals.                                      --- ;
 * ---                                                                 --- ;
 * ----------------------------------------------------------------------- ;
%LET TYPELVLH = IN (0,64);                             *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- NAME OF SAS DATASET OUTPUT FROM PSI17_HOSP_OBSERVED.SAS  --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED HOSPITAL RATES.          --- ;
 * ---------------------------------------------------------------- ; 
%LET  OUTFILE_HOSPOBS = PS17HO_&SUFX.;          *<===USER may modify;

 * ----------------------------------------------------------------- ;
 * --- INDICATE IF A COMMA-DELIMITED TEXT FILE OF OUTFILE_HOSPOBS -- ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.        --- ;
 * ---     0 = NO, 1 = YES.                                      --- ;
 * ----------------------------------------------------------------- ; 
%LET TXTHOBS=0;                                  *<===USER may modify;

 * ----------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED TEXT FILE,                --- ;
 * --- SPECIFY THE LOCATION OF THE FILE.                         --- ;
 * ----------------------------------------------------------------- ;
filename P17TXTHO "&PATHNAME.\SASData\PS17HO_&SUFX..TXT"; *<===USER may modify;

 * ----------------------------------------------------------------- ;
 * --- INDICATE WHETHER THE MEASURES SHOULD BE REPORTED PER      --- ;
 * --- 1,000 DISCHARGES IN OUTPUT TEXT FILES : 0 = NO, 1 = YES.  --- ;
 * ----------------------------------------------------------------- ;
%LET SCALE_RATES = 0;                            *<===USER may modify;


************************* Programs to execute ********************************* ;
 * ---------------------------------------------------------------------------- ;
 * --- SET FLAGS TO RUN INDIVIDUAL PROGRAMS WHEN CONTROL PROGRAM RUNS.      --- ;
 * --- 0 = NO, 1 = YES                                                      --- ;
 * ---------------------------------------------------------------------------- ; 
%LET EXE_FMT  = 0;  * Format Library created if not present. Set to 1 if replacing existing library;
%LET EXE_MSR  = 1;  * Execute PSI_HOSP_MEASURES program; 
%LET EXE_HOBS = 1;  * Execute PSI_HOSP_OBSERVED program; 


************************* END USER INPUT ***************************************;
* --- Include standard diagnosis and procedure macros.                      --- ;
%include MacLib(PSI17_HOSP_Dx_Pr_Macros_v2024.sas);

* --- Check the values of the macro variables                               --- ;
* --- If the user-provided values are out of range, the software will abort --- ;
* --- MDC_PROVIDED: 0, 1                                                    --- ;
 %check_macroval;

* --- Execute Control Program to run flagged programs.                      --- ;
%PROG_EXE(&PATHNAME.,&EXE_FMT.,&EXE_MSR.,&EXE_HOBS.);
