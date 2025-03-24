 * ------------------------------------------------------------------------------------ ;
 *  TITLE: PDI Diagnosis Clinical Classifications Software Redefined (DXCCSR) Code  --- ;
 *                                                                                  --- ;
 *  DESCRIPTION: Creates DXCCSR variables based on diagnoses present on admission   --- ;
 *                                                                                  --- ;
 *  VERSION: SAS QI v2024                                                           --- ;
 *  RELEASE DATE: JULY 2024                                                         --- ;
 * ------------------------------------------------------------------------------------ ;

%MACRO CREATE_CCSR;

%LET d_DXCCSR_list= 
d_DXCCSR_BLD006 d_DXCCSR_BLD008 d_DXCCSR_CIR003 d_DXCCSR_CIR008 d_DXCCSR_CIR014 d_DXCCSR_CIR015
d_DXCCSR_CIR016 d_DXCCSR_CIR017 d_DXCCSR_CIR019 d_DXCCSR_CIR033 d_DXCCSR_DIG004 d_DXCCSR_DIG010
d_DXCCSR_DIG012 d_DXCCSR_DIG017 d_DXCCSR_DIG018 d_DXCCSR_DIG025 d_DXCCSR_END008 d_DXCCSR_END011
d_DXCCSR_END015 d_DXCCSR_END016 d_DXCCSR_FAC006 d_DXCCSR_FAC009 d_DXCCSR_FAC015 d_DXCCSR_GEN002
d_DXCCSR_INF003 d_DXCCSR_INF004 d_DXCCSR_INJ008 d_DXCCSR_INJ010 d_DXCCSR_INJ026 d_DXCCSR_INJ033
d_DXCCSR_INJ037 d_DXCCSR_MAL001 d_DXCCSR_MAL002 d_DXCCSR_MAL004 d_DXCCSR_MAL007 d_DXCCSR_MAL008
d_DXCCSR_MAL009 d_DXCCSR_MAL010 d_DXCCSR_MUS022 d_DXCCSR_NEO023 d_DXCCSR_NEO056 d_DXCCSR_NEO060
d_DXCCSR_NEO070 d_DXCCSR_NVS001 d_DXCCSR_NVS007 d_DXCCSR_NVS016 d_DXCCSR_NVS017 d_DXCCSR_NVS020
d_DXCCSR_PNL001 d_DXCCSR_PNL006 d_DXCCSR_PNL007 d_DXCCSR_PNL010 d_DXCCSR_PNL011 d_DXCCSR_PNL012
d_DXCCSR_PNL013 d_DXCCSR_RSP002 d_DXCCSR_RSP004 d_DXCCSR_RSP007 d_DXCCSR_RSP009 d_DXCCSR_RSP011
d_DXCCSR_RSP012 d_DXCCSR_RSP015 d_DXCCSR_RSP016 d_DXCCSR_SYM003 d_DXCCSR_SYM005 d_DXCCSR_SYM012
d_DXCCSR_SYM016 
;
%LET d_DXCCSR_cnt = 67;

%* Initialize CCSRs ;
%DO J = 1 %TO &d_DXCCSR_cnt.;
  %LET d_var = %SCAN(&d_DXCCSR_list., &J.);
  attrib &d_var. length = 3;
  &d_var. = 0;
%END;

%* Scan each DX ;
%* Count the DXCCSR if the DXCCSR diagnosis is present on admission or POA exempt;
do i = 1 to &NDX;
  if not missing(DX{i}) then do;
    attrib POA_yes length = 3 label = 'DX is POA or POA exempt';
    poa_yes=0;
    select(ICDVER) ;
      %DO ICDVER_ = 41 %TO 33 %BY -1;
         when (&ICDVER_.) do; 
           if (DXPOA{i} IN ('Y','W') AND put(DX{i},$poaxmpt_v&ICDVER_.fmt.)='0') OR (put(DX{i},$poaxmpt_v&ICDVER_.fmt.)='1') then POA_yes = 1;
         end; /* end when */
      %END;  
    end; /* end select */
    %DO J = 1 %TO &d_DXCCSR_cnt.;
      %LET d_var   = %SCAN(&d_DXCCSR_list., &J.);
      %LET CCSRVAL = %SCAN(&d_var.,3,"_");
      if put(DX{i},$&CCSRVAL.FMT.)='1' AND poa_yes then &d_var. = 1;
    %END;
  end; /* end if not missing DX */
end; /* end of do DX */

%MEND CREATE_CCSR;

%CREATE_CCSR;    

