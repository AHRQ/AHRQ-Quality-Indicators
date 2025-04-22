 * ------------------------------------------------------------------------------------ ;
 *  TITLE:  IQI Procedure Clinical Classifications Software Redefined (PRCCSR) Code --- ;
 *                                                                                  --- ;
 *  DESCRIPTION: Creates PRCCSR variables based on the earliest procedures for      --- ;
 *               each measure                                                       --- ;
 *                                                                                  --- ;
 *  VERSION: SAS QI v2023                                                           --- ;
 *  RELEASE DATE: AUGUST 2023                                                       --- ;
 * ------------------------------------------------------------------------------------ ;

%MACRO CREATE_IQI_PRCCSR;

%LET d_PRCCSR_list = 
d_IQ08_PRCCSR_GIS004_123 d_IQ08_PRCCSR_GIS009_123 d_IQ08_PRCCSR_MST028_123 d_IQ08_PRCCSR_RES012_123 d_IQ09_PRCCSR_CAR007_123 d_IQ09_PRCCSR_CAR010_123
d_IQ09_PRCCSR_CAR012_123 d_IQ09_PRCCSR_CAR016_123 d_IQ09_PRCCSR_CAR017_123 d_IQ09_PRCCSR_CAR021_123 d_IQ09_PRCCSR_GIS001_123 d_IQ09_PRCCSR_GIS009_123
d_IQ09_PRCCSR_GIS010_123 d_IQ09_PRCCSR_GIS012_123 d_IQ09_PRCCSR_GIS022_123 d_IQ09_PRCCSR_GIS024_123 d_IQ09_PRCCSR_GIS025_123 d_IQ09_PRCCSR_GNR008_123
d_IQ09_PRCCSR_HEP004_123 d_IQ09_PRCCSR_HEP009_123 d_IQ09_PRCCSR_MST030_123 d_IQ09_PRCCSR_PLC002_123 d_IQ09_PRCCSR_RES011_123 d_IQ09_PRCCSR_URN008_123
d_IQ11_ENDO_PRCCSR_CAR007_123 d_IQ11_ENDO_PRCCSR_CAR008_123 d_IQ11_ENDO_PRCCSR_CAR010_123 d_IQ11_ENDO_PRCCSR_CAR011_123 d_IQ11_ENDO_PRCCSR_CAR012_123 d_IQ11_ENDO_PRCCSR_CAR014_123
d_IQ11_ENDO_PRCCSR_GIS005_123 d_IQ11_ENDO_PRCCSR_GIS024_123 d_IQ11_ENDO_PRCCSR_GNR009_123 d_IQ11_ENDO_PRCCSR_MST030_123 d_IQ11_OPEN_PRCCSR_CAR007_123 d_IQ11_OPEN_PRCCSR_CAR008_123
d_IQ11_OPEN_PRCCSR_CAR010_123 d_IQ11_OPEN_PRCCSR_CAR012_123 d_IQ11_OPEN_PRCCSR_CAR014_123 d_IQ11_OPEN_PRCCSR_CAR020_123 d_IQ11_OPEN_PRCCSR_CAR021_123 d_IQ11_OPEN_PRCCSR_CAR029_123
d_IQ11_OPEN_PRCCSR_GIS005_123 d_IQ11_OPEN_PRCCSR_GIS009_123 d_IQ11_OPEN_PRCCSR_GIS022_123 d_IQ11_OPEN_PRCCSR_GNR002_123 d_IQ11_OPEN_PRCCSR_MST030_123 d_IQ12_PRCCSR_CAR002_123
d_IQ12_PRCCSR_CAR003_123 d_IQ12_PRCCSR_CAR004_123 d_IQ12_PRCCSR_CAR005_123 d_IQ12_PRCCSR_CAR012_123 d_IQ12_PRCCSR_CAR017_123 d_IQ12_PRCCSR_CAR019_123
d_IQ12_PRCCSR_CAR022_123 d_IQ12_PRCCSR_CAR027_123 d_IQ30_PRCCSR_CAR003_123 d_IQ30_PRCCSR_CAR004_123 d_IQ30_PRCCSR_CAR008_123 d_IQ30_PRCCSR_CAR012_123
d_IQ30_PRCCSR_CAR017_123 d_IQ30_PRCCSR_CAR020_123 d_IQ30_PRCCSR_CAR023_123 d_IQ30_PRCCSR_CAR026_123 d_IQ30_PRCCSR_CAR027_123 d_IQ31_PRCCSR_CAR007_123
d_IQ31_PRCCSR_CAR008_123 d_IQ31_PRCCSR_CAR009_123 d_IQ31_PRCCSR_CAR010_123 d_IQ31_PRCCSR_CAR012_123 d_IQ31_PRCCSR_CAR020_123 d_IQ31_PRCCSR_CAR022_123
d_IQ31_PRCCSR_CAR029_123 
;
%LET d_PRCCSR_cnt = 73;

%* Initialize CCSRs ;
%DO J = 1 %TO &d_PRCCSR_cnt.;
  %LET d_var = %SCAN(&d_PRCCSR_list., &J.);
  attrib &d_var. length = 3;
  &d_var. = 0;
%END;

%* Find the first PRDAY for the measure specific procedures ;
attrib MPRDAY_IQ08      length = 3 
       MPRDAY_IQ09      length = 3
       MPRDAY_IQ11_OPEN length = 3
       MPRDAY_IQ11_ENDO length = 3 
       MPRDAY_IQ12      length = 3 
       MPRDAY_IQ30      length = 3 
       MPRDAY_IQ31      length = 3 
; 

%DO I = 1 %TO &NPR.;
  if not missing(PR&I) AND PRDAY&I. GT .Z then do;
    if TPIQ08 in (0,1) AND (put(PR&I.,$PRESOPP.) = '1' OR put(PR&I.,$PRESO2P.) = '1')
    then MPRDAY_IQ08 = min(MPRDAY_IQ08,PRDAY&I);
    
    if (TPIQ09_WITH_CANCER in (0,1) OR TPIQ09_WITHOUT_CANCER in (0,1))
      AND (put(PR&I.,$PRPANCP.) = '1' OR put(PR&I.,$PRPAN3P.) = '1') 
    then MPRDAY_IQ09 = min(MPRDAY_IQ09,PRDAY&I);
    
    if (TPIQ11_OPEN_RUPTURED in (0,1) OR TPIQ11_OPEN_UNRUPTURED in (0,1))
      AND put(PR&I.,$PRAAARP.) = '1'
    then MPRDAY_IQ11_OPEN = min(MPRDAY_IQ11_OPEN,PRDAY&I);
    
    if (TPIQ11_ENDO_RUPTURED in (0,1) OR TPIQ11_ENDO_UNRUPTURED in (0,1))
      AND put(PR&I.,$PRAAA2P.) = '1'
    then MPRDAY_IQ11_ENDO = min(MPRDAY_IQ11_ENDO,PRDAY&I);
    
    if TPIQ12 in (0,1) AND put(PR&I.,$PRCABGP.) = '1'
    then MPRDAY_IQ12 = min(MPRDAY_IQ12,PRDAY&I);
    
    if TPIQ30 in (0,1) AND put(PR&I.,$PRPTCAP.) = '1'
    then MPRDAY_IQ30 = min(MPRDAY_IQ30,PRDAY&I);
    
    if TPIQ31 in (0,1) AND put(PR&I.,$PRCEATP.) = '1'
    then MPRDAY_IQ31 = min(MPRDAY_IQ31,PRDAY&I);
  end;
%END;

%* Scan each PR ;
%* Count the PRCCSR if the PRCCSR procedure occurs before the first measure specific procedure (based on values of PRDAY) ;
do i = 1 to &NPR.; 
 if not missing(PR{i}) AND PRDAY{i} >.Z then do;
  %DO J = 1 %TO &d_PRCCSR_cnt.;
    %LET d_var = %SCAN(&d_PRCCSR_list., &J.);
    %LET CCSRVAL = %SCAN(&d_var.,-2,"_");
    %LET m=%substr(&d_var.,3,%EVAL(%SYSFUNC(index(&d_var.,PRCCSR))-4));
    if put(PR{i},$&CCSRVAL.FMT.) = '1' AND PRDAY{i} <= MPRDAY_&m. then &d_var. = 1; 
  %END;
 end; /* end if not missing */
end; /* end of do PR */  

%MEND CREATE_IQI_PRCCSR;

%CREATE_IQI_PRCCSR;


