 * ------------------------------------------------------------- ;
 *  TITLE: PSI 15 NUMERATOR CRITERIA                         --- ;
 *         BASED ON SITES                                    --- ;
 *                                                           --- ;
 *  DESCRIPTION: Defines the PSI 15 measure based on the     --- ;
 *               organ or structure. The user does not need  --- ;
 *               to open or modify.                          --- ;
 *                                                           --- ;
 *  VERSION: SAS QI v2024                                    --- ;
 *  RELEASE DATE: JULY 2024                                  --- ;
 * ------------------------------------------------------------- ;

%MACRO PSI15_SiteSpec_Numer;
%let PSI15_site = SPLEEN ADRENAL VESSEL DIAPHR GI GU;
%let PSI15_cnt  = 6;

%do n = 1 %to &psi15_cnt.;
   %let site = %scan(&PSI15_Site.,&n.);

   TPPS15_&site.=0;
   QPPS15_&site.=0;

   %PS15($ABDOMI15P.,$&site.15P.);
   
   if %MDX2($&site.15D.) then do;
      if MPRDAYCD = 1 then TPPS15_&site. = 1;
   end;

   *** Exclude principal diagnosis;

   if %MDX1($&site.15D.) then TPPS15_&site. = .;
   if %MDX2Q2($&site.15D.) then QPPS15_&site. = 1;

   if QPPS15_&site. = 1 then TPPS15_&site. = .;
%end;

sum_TPPS15_allsite = sum(of TPPS15_:);

if sum_TPPS15_allsite >=1 then TPPS15=1;
else if sum_TPPS15_allsite=. then TPPS15=.;

%MEND;
%PSI15_SiteSpec_Numer;

   

