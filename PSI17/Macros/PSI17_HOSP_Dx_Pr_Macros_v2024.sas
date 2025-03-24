 * ------------------------------------------------------------- ;
 *  TITLE: PSI17 MODULE DIAGNOSIS AND PROCEDURE MACROS       --- ;
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
 %MACRO PROG_EXE(PATHNAME,EXE_FMT,EXE_MSR,EXE_HOBS,EXE_HRSK,EXE_HCMP);
    %if %sysfunc(CEXIST(LIBRARY.FORMATS.PRETEID.FORMATC)) = 0 or &EXE_FMT. = 1 %then %do;
        %include PROGRMS(PSI17_HOSP_FORMATS.SAS);
    %end;
  
   %if %sysfunc(CEXIST(LIBRARY.FORMATS.PRETEID.FORMATC)) = 1 and &EXE_MSR. = 1  %then %do;
    	%include PROGRMS(PSI17_HOSP_MEASURES.SAS) /source2;
   %end;

   %if %sysfunc(CEXIST(LIBRARY.FORMATS.PRETEID.FORMATC)) = 0 and &EXE_MSR. = 1  %then %do;
    	 %PUT PSI17 Format library not found. Verify Format Library created prior to running Measures.;
		  %goto exit;
   %end;
   
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) and &EXE_HOBS. = 1 %then %do;
    	%include PROGRMS(PSI17_HOSP_OBSERVED.SAS) /source2;
   %end;
   
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) = 0 and &EXE_HOBS. = 1 %then %do;
        %PUT PSI17 Measure output not found. Verify OUTMSR Library or rerun Control Program with EXE_MSR = 1;
		 %goto exit;
    %end;
	
  %exit:
 %MEND;

 /*Macro to compare all discharge diagnosis codes against format.*/
 %MACRO MDX(FMT);

 (%DO I = 1 %TO &NDX.-1;
  (PUT(DX&I.,&FMT.) = '1') OR
  %END;
  (PUT(DX&NDX.,&FMT.) = '1'))

 %MEND;

 /*Macro to compare discharge primary diagnosis code against format.*/
 %MACRO MDX1(FMT);

 (PUT(DX1,&FMT.) = '1')

 %MEND;

 
 /*Macro to determine if measure format diagnosis is included in any secondary discharge diagnosis code as present on admission.*/
 %MACRO MDX2Q2(FMT);
 
 1 = 1 then do;
   result = 0;
   do i = 2 to &NDX.;
     if put(DX{i},&FMT.) = '1' then do;
       if DXPOA{i} IN ('Y','W') then
         if (ICDVER = 41 AND put(DX{i},$poaxmpt_v41fmt.)='0') OR
            (ICDVER = 40 AND put(DX{i},$poaxmpt_v40fmt.)='0') OR
            (ICDVER = 39 AND put(DX{i},$poaxmpt_v39fmt.)='0') OR
            (ICDVER = 38 AND put(DX{i},$poaxmpt_v38fmt.)='0') OR
            (ICDVER = 37 AND put(DX{i},$poaxmpt_v37fmt.)='0') OR
            (ICDVER = 36 AND put(DX{i},$poaxmpt_v36fmt.)='0') OR
            (ICDVER = 35 AND put(DX{i},$poaxmpt_v35fmt.)='0') OR
            (ICDVER = 34 AND put(DX{i},$poaxmpt_v34fmt.)='0') OR
            (ICDVER = 33 AND put(DX{i},$poaxmpt_v33fmt.)='0')
         then result = 1;
       if (ICDVER = 41 AND put(DX{i},$poaxmpt_v41fmt.)='1') OR
          (ICDVER = 40 AND put(DX{i},$poaxmpt_v40fmt.)='1') OR
          (ICDVER = 39 AND put(DX{i},$poaxmpt_v39fmt.)='1') OR
          (ICDVER = 38 AND put(DX{i},$poaxmpt_v38fmt.)='1') OR
          (ICDVER = 37 AND put(DX{i},$poaxmpt_v37fmt.)='1') OR
          (ICDVER = 36 AND put(DX{i},$poaxmpt_v36fmt.)='1') OR
          (ICDVER = 35 AND put(DX{i},$poaxmpt_v35fmt.)='1') OR
          (ICDVER = 34 AND put(DX{i},$poaxmpt_v34fmt.)='1') OR
          (ICDVER = 33 AND put(DX{i},$poaxmpt_v33fmt.)='1')
       then result = 1;
     end;
   if result = 1 then leave;
   end;
 end;
 if result = 1

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
 
 /* Macro to check if the user-provided values of the macro variables are out of range.*/
 %MACRO check_macroval;
     %IF &MDC_PROVIDED. ^= 0 and &MDC_PROVIDED. ^= 1 %THEN %DO;
        %put "ERROR: The value of MDC_PROVIDED macro variable in CONTROL program is out of range. Set the value to 0 or 1.";
        %ABORT CANCEL;
     %END;
 %MEND check_macroval;
 
 /*Define macro variables for printing text file headers*/
 %let MDC_PROVIDED0 = %str(Data has MDC with all missing values);
 %let MDC_PROVIDED1 = %str(Data has MDC from CMS MS-DRG Grouper);