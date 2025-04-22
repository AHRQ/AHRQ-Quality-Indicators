 * ------------------------------------------------------------------------------------ ;
 *  TITLE: PDI Diagnosis Clinical Classifications Software Redefined (DXCCSR) Code  --- ;
 *                                                                                  --- ;
 *  DESCRIPTION: Creates DXCCSR variables based on diagnoses present on admission   --- ;
 *                                                                                  --- ;
 *  VERSION: SAS QI v2023                                                           --- ;
 *  RELEASE DATE: AUGUST 2023                                                       --- ;
 * ------------------------------------------------------------------------------------ ;

%MACRO CREATE_CCSR;

%LET d_DXCCSR_list= 
d_DXCCSR_BLD003_123 d_DXCCSR_BLD006_123 d_DXCCSR_BLD008_123 d_DXCCSR_CIR003_123 d_DXCCSR_CIR008_123 d_DXCCSR_CIR014_123
d_DXCCSR_CIR015_123 d_DXCCSR_CIR016_123 d_DXCCSR_CIR017_123 d_DXCCSR_CIR019_123 d_DXCCSR_DIG004_123 d_DXCCSR_DIG010_123
d_DXCCSR_DIG012_123 d_DXCCSR_DIG017_123 d_DXCCSR_DIG025_123 d_DXCCSR_EAR001_123 d_DXCCSR_EAR004_123 d_DXCCSR_END001_123
d_DXCCSR_END008_123 d_DXCCSR_END011_123 d_DXCCSR_END015_123 d_DXCCSR_END016_123 d_DXCCSR_FAC006_123 d_DXCCSR_FAC009_123
d_DXCCSR_FAC015_123 d_DXCCSR_GEN002_123 d_DXCCSR_INF003_123 d_DXCCSR_INF008_123 d_DXCCSR_INJ001_123 d_DXCCSR_INJ008_123
d_DXCCSR_INJ010_123 d_DXCCSR_INJ028_123 d_DXCCSR_INJ033_123 d_DXCCSR_INJ037_123 d_DXCCSR_MAL001_123 d_DXCCSR_MAL002_123
d_DXCCSR_MAL003_123 d_DXCCSR_MAL004_123 d_DXCCSR_MAL007_123 d_DXCCSR_MAL008_123 d_DXCCSR_MAL009_123 d_DXCCSR_MAL010_123
d_DXCCSR_MUS022_123 d_DXCCSR_NEO023_123 d_DXCCSR_NEO056_123 d_DXCCSR_NEO060_123 d_DXCCSR_NEO070_123 d_DXCCSR_NEO074_123
d_DXCCSR_NVS001_123 d_DXCCSR_NVS009_123 d_DXCCSR_NVS016_123 d_DXCCSR_NVS017_123 d_DXCCSR_NVS020_123 d_DXCCSR_PNL001_123
d_DXCCSR_PNL002_123 d_DXCCSR_PNL005_123 d_DXCCSR_PNL006_123 d_DXCCSR_PNL007_123 d_DXCCSR_PNL010_123 d_DXCCSR_PNL011_123
d_DXCCSR_PNL012_123 d_DXCCSR_PNL013_123 d_DXCCSR_RSP002_123 d_DXCCSR_RSP004_123 d_DXCCSR_RSP007_123 d_DXCCSR_RSP009_123
d_DXCCSR_RSP011_123 d_DXCCSR_RSP012_123 d_DXCCSR_RSP015_123 d_DXCCSR_RSP016_123 d_DXCCSR_SYM003_123 d_DXCCSR_SYM005_123
d_DXCCSR_SYM012_123 d_DXCCSR_SYM016_123 
;
%LET d_DXCCSR_cnt = 74;

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
      %DO ICDVER_ = 40 %TO 33 %BY -1;
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

