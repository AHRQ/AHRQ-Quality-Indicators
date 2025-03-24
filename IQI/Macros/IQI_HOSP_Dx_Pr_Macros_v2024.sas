 * ------------------------------------------------------------- ;
 *  TITLE: IQI MODULE DIAGNOSIS AND PROCEDURE MACROS         --- ;
 *                                                           --- ;
 *  DESCRIPTION: Assigns diagnosis and procedure codes       --- ;
 *               using macros called by other SAS programs.  --- ;
 *               The user does not need to open or modify.   --- ;
 *                                                           --- ;
 *  VERSION: SAS QI v2024                                    --- ;
 *  RELEASE DATE: JULY 2024                                  --- ;
 * ------------------------------------------------------------- ;

  /*Macro to run Formats, Measures and Observed programs from within Control program.*/
  Filename PROGRMS "&PATHNAME.\Programs";
  %MACRO PROG_EXE(PATHNAME,EXE_FMT,EXE_MSR,EXE_HOBS,EXE_HRSK,EXE_HCMP);
    %if %sysfunc(CEXIST(LIBRARY.FORMATS.VAGDELP.FORMATC)) = 0 or &EXE_FMT. = 1 %then %do;
        %include PROGRMS(IQI_HOSP_FORMATS.SAS);
    %end;
  
   %if %sysfunc(CEXIST(LIBRARY.FORMATS.VAGDELP.FORMATC)) = 1 and &EXE_MSR. = 1  %then %do;
    	%include PROGRMS(IQI_HOSP_MEASURES.SAS) /source2;
   %end;

   %if %sysfunc(CEXIST(LIBRARY.FORMATS.VAGDELP.FORMATC)) = 0 and &EXE_MSR. = 1  %then %do;
    	 %PUT IQI Format library not found. Verify Format Library created prior to running Measures.;
		  %goto exit;
   %end;
   
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) = 1 and &EXE_HOBS. = 1 %then %do;
    	%include PROGRMS(IQI_HOSP_OBSERVED.SAS) /source2;
   %end;
   
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) = 0 and &EXE_HOBS. = 1 %then %do;
        %PUT IQI Measure output not found. Verify OUTMSR Library or rerun Control Program with EXE_MSR = 1;
		 %goto exit;
    %end;
	
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) = 1 and %sysfunc(exist(OUTHOBS.&OUTFILE_HOSPOBS.)) = 1 and &EXE_HRSK. = 1 %then %do;
    	%include PROGRMS(IQI_HOSP_RISKADJ.SAS) /source2;
   %end;
   
   %if (%sysfunc(exist(OUTMSR.&OUTFILE_MEAS.)) = 0 OR %sysfunc(exist(OUTHOBS.&OUTFILE_HOSPOBS.)) = 0) and &EXE_HRSK. = 1 %then %do;
        %PUT IQI output not found. Verify OUTMSR and OUTHOBS Library or rerun Control Program with EXE_MSR = 1 and EXE_HOBS=1;
		 %goto exit;
    %end;
	
   %if %sysfunc(exist(OUTMSR.&OUTFILE_MEAS.))= 1 and &EXE_HCMP. = 1 %then %do;
    	%include PROGRMS(IQI_HOSP_COMPOSITE.SAS) /source2;
   %end;
   
   %if %sysfunc(exist(OUTHRISK.&OUTFILE_HOSPRISK.)) = 0 and &EXE_HCMP. = 1 %then %do;
        %PUT IQI Risk output not found. Verify OUTHRISK Library or rerun Control Program with EXE_MSR = 1;
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

 /*Macro to compare discharge primary diagnosis code against format.*/
 %MACRO MDX1(FMT);

 ((put(DX1,&FMT.) = '1'))

 %MEND;

 /*Macro to compare discharge secondary diagnosis codes against format.*/
 %MACRO MDX2(FMT);

 (%DO I = 2 %TO &NDX.-1;
  (put(DX&I.,&FMT.) = '1') or
  %END;
  (put(DX&NDX.,&FMT.) = '1'))

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

 /*Macro to determine if measure format diagnosis is included in any discharge diagnosis code as present on admission.*/
 %MACRO MDXAQ2(FMT);

 1 = 1 then do;
   result = 0;
   do i = 1 to &NDX.;
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

 /*Macro to compare discharge DRG code against format.*/
 %MACRO MDR(FMT);

 (put(put(DRG,Z3.),&FMT.) = '1')

 %MEND;

 /*Macro to compare all discharge procedure codes against format.*/
 %MACRO MPR(FMT);

 (%DO I = 1 %TO &NPR.-1;
  (put(PR&I.,&FMT.) = '1' ) or
  %END;
  (put(PR&NPR.,&FMT.) = '1' ))

 %MEND;

 /*Macro to return the first day a measure format procedure was conducted based on PRDAY.*/
 %MACRO MPRDAY(FMT);

    MPRDAY = .;
    %DO I = 1 %TO &NPR.;
       IF PUT(PR&I.,&FMT.) = '1' AND PRDAY&I. GT .Z THEN DO;
          IF MPRDAY LE .Z THEN MPRDAY = PRDAY&I;
          ELSE IF MPRDAY > PRDAY&I. THEN MPRDAY = PRDAY&I;
       END;
    %END;

 %MEND;
 
 /*Macro to add PRDAY fields onto input statement based on Control file setting.*/
 /*Macro to add PAY1 onto input statement based on the availability in the input data.*/
 /*Macro to add RACE onto input statement based on the availability in the input data.*/
 %MACRO ADDPRDAY_PAY1_RACE;
    %IF &PRDAY EQ 1 %THEN PRDAY1-PRDAY&NPR. ;
    %IF &PAY1_PROVIDED EQ 1 %THEN PAY1 ;
    %IF &RACE_PROVIDED EQ 1 %THEN RACE ;
 %MEND;

 /*Macro to create a fake PAY1 if PAY1 is not in the input data.*/
 /*Macro to create a fake RACE if RACE is not in the input data.*/
 %MACRO CreateFakePAY1_RACE;
    %IF &PAY1_PROVIDED EQ 0 %THEN %DO; PAY1=999; %END;
    %IF &RACE_PROVIDED EQ 0 %THEN %DO; RACE=999; %END;
 %MEND;
 
 /*Macro to check if the user-provided values of the macro variables are out of range.*/
 %MACRO check_macroval;
   %if &MDC_PROVIDED. ^= 0 and &MDC_PROVIDED. ^= 1 %THEN %DO;
      %PUT "ERROR: The value of MDC_PROVIDED macro variable in CONTROL program is out of range. Set the value to 0 or 1.";
      %ABORT CANCEL;
   %END;
   %IF &PRDAY. ^= 0 and &PRDAY. ^= 1 %THEN %DO;
      %PUT "ERROR: The value of PRDAY macro variable in CONTROL program is out of range. Set the value to 0 or 1.";
      %abort cancel;
   %END;
 %MEND check_macroval;

 /*Define macro variables for printing text file headers*/ 
 %let Calibration_OE_to_ref_pop1 = %str(O/E ratio adjustment is from the reference population);
 %let Calibration_OE_to_ref_pop0 = %str(O/E ratios based on user data are being calculated and used);
 %let MDC_PROVIDED0 = %str(Data has MDC with all missing values);
 %let MDC_PROVIDED1 = %str(Data has MDC from CMS MS-DRG Grouper);
 %let PRDAY0 = %str(Variable PRDAY is not included);
 %let PRDAY1 = %str(Variable PRDAY is included);
