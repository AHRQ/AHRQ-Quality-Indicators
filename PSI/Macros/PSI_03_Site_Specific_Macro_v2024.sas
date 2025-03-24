 * ------------------------------------------------------------- ;
 *  TITLE: PSI 03 SITE-SPECIFIC NUMERATOR AND                --- ;
 *         DENOMINATOR MACRO                                 --- ;
 *                                                           --- ;
 *  DESCRIPTION: Defines the PSI 03 measure based on the     --- ;
 *               site of the event. The user does not need   --- ;
 *               to open or modify.                          --- ;
 *                                                           --- ;
 *  VERSION: SAS QI v2024                                    --- ;
 *  RELEASE DATE: JULY 2024                                  --- ;
 * ------------------------------------------------------------- ;


 %MACRO PSI03_SiteSpec;

 *** Define site specific categories;
 %let D_list      =
 PIRELBOWD PILELBOWD PIRUPBACKD   PILUPBACKD PIRLOBACKD PILLOBACKD PISACRALD PIRHIPD PILHIPD 
 PIRBUTTD  PILBUTTD  PICONTIGBBHD PIRANKLED  PILANKLED  PIRHEELD   PILHEELD  PIHEADD PIOTHERD;

 %let EXD_list    =
 PIRELBOEXD PILELBOEXD PIRUPBACEXD  PILUPBACEXD PIRLOBACEXD PILLOBACEXD PISACRAEXD PIRHIPEXD PILHIPEXD 
 PIRBUTEXD  PILBUTEXD  PICONTBBHEXD PIRANKLEXD  PILANKLEXD  PIRHEELEXD  PILHEELEXD PIHEADEXD PIOTHEREXD;

 %let DTID_list   =
 DTIRELBOEXD DTILELBOEXD DTIRUPBACEXD  DTILUPBACEXD DTIRLOBACEXD DTILLOBACEXD DTISACRAEXD DTIRHIPEXD DTILHIPEXD
 DTIRBUTEXD  DTILBUTEXD  DTICONTBBHEXD DTIRANKLEXD  DTILANKLEXD  DTIRHEELEXD  DTILHEELEXD DTIHEADEXD DTIOTHEREXD;

 %let NOSite      = PINELBOWD PINBACKD   PINHIPD PINBUTTD PINANKLED PINHEELD PIUNSPECD;
 %let SiteCnt     = 18;
 %let NoSiteCnt   = 7;

length flag_SiteSpec $15;
flag_T1_Q0 = 0;
flag_T0_Q0 = 0;
flag_Tm_Q0 = 0;
flag_T1_Q1 = 0;
flag_T0_Q1 = 0;
flag_Tm_Q1 = 0;
flag_T10m_Q1 = 0;

%do site = 1 %to &SiteCnt.;

   %let D = %scan(&D_list.,&site.);
   %let EXD = %scan(&EXD_list.,&site.);
   %let DTID = %scan(&DTID_list.,&site.);

   TPPS03 = 0; QPPS03 = 0; flag_LoopSite=&site.;

   if %MDX2Q1($&D..) then TPPS03 = 1; /*at least one secondary diagnosis non POA for stage 3 or 4 or unstagable PU of specific site*/
   *** Exclude principal diagnosis or numerator event with at least one secondary diagnosis POA for DTI or unstagable PU at the same site;
   if %MDX1($&EXD..) then TPPS03 = .;
   if %MDX2Q2($&DTID..) then QPPS03 = 1; /* at least one 2nd dx of DTI or unstagable PU at same site POA */


   if TPPS03 = 1 and QPPS03 = 0 then do;
      flag_SiteSpec = "&D.";
    flag_T1_Q0 = flag_T1_Q0+1;
      goto OutLoop ;
   end;
   else if TPPS03 = 0 and QPPS03 = 0 then flag_T0_Q0 = flag_T0_Q0+1;
   else if TPPS03 = . and QPPS03 = 0 then flag_Tm_Q0 = flag_Tm_Q0+1;
   else if TPPS03 = 1 and QPPS03 = 1 then flag_T1_Q1 = flag_T1_Q1+1;
   else if TPPS03 = 0 and QPPS03 = 1 then flag_T0_Q1 = flag_T0_Q1+1;
   else if TPPS03 = . and QPPS03 = 1 then flag_Tm_Q1 = flag_Tm_Q1+1;
%end;
flag_T10m_Q1=sum(flag_T1_Q1,flag_T0_Q1,flag_Tm_Q1);

/* If all sites meet the DTI exclusion, set Q flag as 1 to exclude the case from the denominator */
if flag_T10m_Q1 = &SiteCnt. then QPPS03 = 1; else QPPS03 = 0;
   
%do n = 1 %to &NoSiteCnt.;
   %let NS = %scan(&NoSite.,&n.);

   TPPS03 = 0; flag_LoopN = &n.;

   if %MDX2Q1($&NS..) then TPPS03 = 1; /* at least one secondary diagnosis non POA for stage 3 or 4 or unstagable PU of unspecified site */
   *** No exclusion if site of PU not POA is unspecified ;
   if TPPS03 = 1 then do;
      flag_SiteSpec = "&NS.";
      goto OutLoop ;
   end;
%end;

OutLoop:

%mend;
%PSI03_SiteSpec;