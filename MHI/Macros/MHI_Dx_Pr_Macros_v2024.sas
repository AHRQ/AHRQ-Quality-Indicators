 * ------------------------------------------------------------- ;
 *  TITLE: MHI MODULE DIAGNOSIS AND PROCEDURE MACROS         --- ;
 *                                                           --- ;
 *  DESCRIPTION: Assigns diagnosis and procedure codes       --- ;
 *               using macros called by other SAS programs.  --- ;
 *               The user does not need to open or modify.   --- ;
 *                                                           --- ;
 *  VERSION: SAS QI v2024                                    --- ;
 *  RELEASE DATE: SEPTEMBER 2024                             --- ;
 * ------------------------------------------------------------- ;

  /*Macro to run Formats, Measures and Observed programs from within Control program.*/
  Filename PROGRMS "&PATHNAME.\Programs";
  %MACRO PROG_EXE(PATHNAME,EXE_FMT,EXE_MSR,EXE_AOBS);
    %if %sysfunc(CEXIST(LIBRARY.FORMATS.POVCAT.FORMATC)) = 0 or &EXE_FMT. = 1 %then %do;
        %include PROGRMS(MHI_FORMATS.sas);
    %end;
  
   %if %sysfunc(CEXIST(LIBRARY.FORMATS.POVCAT.FORMATC)) = 1 and &EXE_MSR. = 1  %then %do;
        %include PROGRMS(MHI_MEASURES.sas) /source2;
   %end;

   %if %sysfunc(CEXIST(LIBRARY.FORMATS.POVCAT.FORMATC)) = 0 and &EXE_MSR. = 1  %then %do;
         %PUT MHI Format library not found. Verify Format Library created prior to running Measures.;
         %goto exit;
   %end;
   
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) = 1 and &EXE_AOBS. = 1 %then %do;
        %include PROGRMS(MHI_OBSERVED.sas) /source2;
   %end;
   
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) = 0 and &EXE_AOBS. = 1 %then %do;
        %PUT MHI Measure output not found. Verify OUTMSR Library or rerun Control Program with EXE_MSR = 1;
        %goto exit;
    %end;
  %exit:
  %MEND;

 /*Macro to compare all discharge diagnosis codes against format.*/
 %MACRO MDX(FMT);

 (%DO I = 1 %TO &NDX.-1;
  (put(DX&I.,&FMT.) = '1') or
  %END;
  (put(DX&NDX.,&FMT.) = '1'))

 %MEND;


 /*Macro to compare all discharge procedure codes against format.*/
 %MACRO MPR(FMT);

 (%DO I = 1 %TO &NPR.-1;
  (put(PR&I.,&FMT.) = '1' ) or
  %END;
  (put(PR&NPR.,&FMT.) = '1' ))

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
