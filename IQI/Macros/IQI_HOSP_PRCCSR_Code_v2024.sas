 * ------------------------------------------------------------------------------------ ;
 *  TITLE:  IQI Procedure Clinical Classifications Software Redefined (PRCCSR) Code --- ;
 *                                                                                  --- ;
 *  DESCRIPTION: Creates PRCCSR variables based on the earliest procedures for      --- ;
 *               each measure                                                       --- ;
 *                                                                                  --- ;
 *  VERSION: SAS QI v2024                                                           --- ;
 *  RELEASE DATE: JULY 2024                                                         --- ;
 * ------------------------------------------------------------------------------------ ;

%MACRO CREATE_IQI_PRCCSR;

%LET d_PRCCSR_list = 
d_IQ08_PRCCSR_CAR010 d_IQ08_PRCCSR_CAR012 d_IQ08_PRCCSR_GIS004 d_IQ08_PRCCSR_GIS009 d_IQ08_PRCCSR_GIS027 d_IQ08_PRCCSR_HEP013
d_IQ08_PRCCSR_LYM002 d_IQ08_PRCCSR_RES012 d_IQ09_PRCCSR_CAR010 d_IQ09_PRCCSR_CAR012 d_IQ09_PRCCSR_GIS009 d_IQ09_PRCCSR_GIS010
d_IQ09_PRCCSR_GIS011 d_IQ09_PRCCSR_GIS012 d_IQ09_PRCCSR_GIS024 d_IQ09_PRCCSR_GIS025 d_IQ09_PRCCSR_HEP004 d_IQ09_PRCCSR_HEP006
d_IQ09_PRCCSR_URN008 d_IQ11_PRCCSR_CAR007 d_IQ11_PRCCSR_CAR008 d_IQ11_PRCCSR_CAR010 d_IQ11_PRCCSR_CAR012 d_IQ11_PRCCSR_CAR014
d_IQ11_PRCCSR_CAR029 d_IQ11_PRCCSR_GIS005 d_IQ11_PRCCSR_GIS024 d_IQ11_PRCCSR_MST030 d_IQ12_PRCCSR_CAR002 d_IQ12_PRCCSR_CAR003
d_IQ12_PRCCSR_CAR004 d_IQ12_PRCCSR_CAR005 d_IQ12_PRCCSR_CAR009 d_IQ12_PRCCSR_CAR012 d_IQ12_PRCCSR_CAR017 d_IQ12_PRCCSR_CAR019
d_IQ12_PRCCSR_CAR022 d_IQ12_PRCCSR_CAR027 d_IQ12_PRCCSR_CAR029 d_IQ12_PRCCSR_GNR007 d_IQ30_PRCCSR_CAR003 d_IQ30_PRCCSR_CAR004
d_IQ30_PRCCSR_CAR008 d_IQ30_PRCCSR_CAR012 d_IQ30_PRCCSR_CAR017 d_IQ30_PRCCSR_CAR020 d_IQ30_PRCCSR_CAR023 d_IQ30_PRCCSR_CAR026
d_IQ30_PRCCSR_CAR027 d_IQ30_PRCCSR_GIS007 d_IQ31_PRCCSR_CAR003 d_IQ31_PRCCSR_CAR007 d_IQ31_PRCCSR_CAR008 d_IQ31_PRCCSR_CAR009
d_IQ31_PRCCSR_CAR010 d_IQ31_PRCCSR_CAR012 d_IQ31_PRCCSR_CAR020 d_IQ31_PRCCSR_CAR022 d_IQ31_PRCCSR_CAR029 
;
%LET d_PRCCSR_cnt = 59;

%* Initialize CCSRs ;
%DO J = 1 %TO &d_PRCCSR_cnt.;
  %LET d_var = %SCAN(&d_PRCCSR_list., &J.);
  attrib &d_var. length = 3;
  &d_var. = 0;
%END;

%* Find the first PRDAY for the measure specific procedures ;
attrib MPRDAY_IQ08      length = 3 
       MPRDAY_IQ09      length = 3
       MPRDAY_IQ11      length = 3
       MPRDAY_IQ12      length = 3 
       MPRDAY_IQ30      length = 3 
       MPRDAY_IQ31      length = 3 
; 

%DO I = 1 %TO &NPR.;
  if not missing(PR&I) AND PRDAY&I. GT .Z then do;
    if TPIQ08 in (0,1) AND (put(PR&I.,$PRESOPP.) = '1' OR put(PR&I.,$PRESO2P.) = '1')
    then MPRDAY_IQ08 = min(MPRDAY_IQ08,PRDAY&I);
    
    if TPIQ09 in (0,1) AND (put(PR&I.,$PRPANCP.) = '1' OR put(PR&I.,$PRPAN3P.) = '1')
    then MPRDAY_IQ09 = min(MPRDAY_IQ09,PRDAY&I);

    if TPIQ11 in (0,1) AND (put(PR&I.,$PRAAARP.) = '1' OR put(PR&I.,$PRAAA2P.) = '1')
    then MPRDAY_IQ11 = min(MPRDAY_IQ11,PRDAY&I);
    
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
    %LET CCSRVAL = %SCAN(&d_var.,4,"_");
    %LET m=%substr(&d_var.,3,%EVAL(%SYSFUNC(index(&d_var.,PRCCSR))-4));
    if put(PR{i},$&CCSRVAL.FMT.) = '1' AND PRDAY{i} <= MPRDAY_&m. then &d_var. = 1; 
  %END;
 end; /* end if not missing */
end; /* end of do PR */  

%MEND CREATE_IQI_PRCCSR;

%CREATE_IQI_PRCCSR;


