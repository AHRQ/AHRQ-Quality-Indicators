 * ------------------------------------------------------------- ;
 *  TITLE: PQI MODULE DIAGNOSIS AND PROCEDURE MACROS         --- ;
 *                                                           --- ;
 *  DESCRIPTION: Assigns diagnosis and procedure codes       --- ;
 *               using macros called by other SAS programs.  --- ;
 *               The user does not need to open or modify.   --- ;
 *                                                           --- ;
 *  VERSION: SAS QI v2024                                    --- ;
 *  RELEASE DATE: JULY 2024                                  --- ;
 * ------------------------------------------------------------- ;

 /*Macro to run Format, Measure and observed programs from within Control program.*/
 Filename PROGRMS "&PATHNAME.\Programs";
 %MACRO PROG_EXE(PATHNAME,EXE_FMT,EXE_MSR,EXE_AOBS,EXE_ARSK);
    %if %sysfunc(CEXIST(LIBRARY.FORMATS.RESPAN.FORMATC)) = 0 or &EXE_FMT. = 1 %then %do;
        %include PROGRMS(PQI_AREA_FORMATS.SAS);
    %end;
  
   %if %sysfunc(CEXIST(LIBRARY.FORMATS.RESPAN.FORMATC)) = 1 and &EXE_MSR. = 1  %then %do;
    	%include PROGRMS(PQI_AREA_MEASURES.SAS) /source2;
   %end;
   
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.))=1 and &EXE_AOBS. = 1 %then %do;
    	%include PROGRMS(PQI_AREA_OBSERVED.SAS) /source2;
   %end;

   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) = 0 and &EXE_AOBS. = 1 %then %do;
        %PUT PQI Measure output not found. Run Measures prior to Observed.;
    %end;
	
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.))=1  AND %sysfunc(exist(OUTAOBS.&OUTFILE_AREAOBS.)) = 1 and &EXE_ARSK. = 1 %then %do;
    	%include PROGRMS(PQI_AREA_RISKADJ.SAS) /source2;
   %end;
   
   %if (%sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) = 0 OR %sysfunc(exist(OUTAOBS.&OUTFILE_AREAOBS.)) = 0)  and &EXE_ARSK. = 1 %then %do;
        %PUT PQI Measure/Observed output not found. Run Measures and Observed programs prior to Risk Adjusted.;
    %end;

 %MEND;

 /*Macro to compare all discharge diagnosis codes against format.*/
 %MACRO MDX(FMT);

 (%DO I = 1 %TO &NDX.-1;
  (put(DX&I.,&FMT.) = '1') or
  %END;
  (put(DX&NDX.,&FMT.) = '1'))

 %MEND;

 /*Macro to compare discharge primary diagnosis code against format.*/
 %MACRO MDX1(FMT);

 (put(DX1,&FMT.) = '1')

 %MEND;

 /*Macro to compare discharge secondary diagnosis codes against format.*/
 %MACRO MDX2(FMT);

 (%DO I = 2 %TO &NDX.-1;
  (put(DX&I.,&FMT.) = '1') or
  %END;
  (put(DX&NDX.,&FMT.) = '1'))

 %MEND;

 /*Macro to compare all discharge procedure codes against format.*/
 %MACRO MPR(FMT);

 (%DO I = 1 %TO &NPR.-1;
  (put(PR&I.,&FMT.) = '1') or
  %END;
  (put(PR&NPR.,&FMT.) = '1'))

 %MEND;

 /*Macro to add PAY1 onto input statement based on the availability in the input data.*/
 /*Macro to add RACE onto input statement based on the availability in the input data.*/
 %MACRO ADDPAY1_RACE;
    %IF &PAY1_PROVIDED EQ 1 %THEN PAY1 ;
    %IF &RACE_PROVIDED EQ 1 %THEN RACE ;
 %MEND;

 /*Macro to create a fake PAY1 if PAY1 is not in the input data.*/
 /*Macro to create a fake RACE if RACE is not in the input data.*/
 %MACRO CreateFakePAY1_RACE;
    %IF &PAY1_PROVIDED EQ 0 %THEN %DO; PAY1=999; %END;
    %IF &RACE_PROVIDED EQ 0 %THEN %DO; RACE=999; %END;
 %MEND;

 /*Define macro variables for printing text file headers*/ 
 %let Calibration_OE_to_ref_pop1 = %str(O/E ratio adjustment is from the reference population);
 %let Calibration_OE_to_ref_pop0 = %str(O/E ratios based on user data are being calculated and used);
 %let MALEVL0 = %str(County level with U.S. Census FIPS);
 %let MALEVL1 = %str(County level with Modified FIPS);
 %let MALEVL2 = %str(Metro Area level with OMB 1999 definition);
 %let MALEVL3 = %str(Metro Area level with OMB 2003 definition);
 %let USE_SES1 = %str(Socioeconomic status is used in area risk adjustment);
 %let USE_SES0 = %str(Socioeconomic status is not used in area risk adjustment);