 * ------------------------------------------------------------- ;
 *  TITLE: PSI 15 NUMERATOR AND DENOMINATOR CRITERIA         --- ;
 *         BASED ON PRDAY OF ABDOMI15P                       --- ;
 *                                                           --- ;
 *  DESCRIPTION: Defines the PSI 15 measure based on the     --- ;
 *               days of procedures. The user does not need  --- ;
 *               to open or modify.                          --- ;
 *                                                           --- ;
 *  VERSION: SAS QI v2024                                    --- ;
 *  RELEASE DATE: JULY 2024                                  --- ;
 * ------------------------------------------------------------- ;


%macro PSI15_denom_numer(FMT);

   %DO L = 1 %TO &NPR.;
     if put(PR&L.,&FMT.) = '1' then do;
        if PRDAY&L. = .C then flag_C_PR&L. = 1;
        else if PRDAY&L. = . then flag_M_PR&L. = 1;
       else if .Z < PRDAY&L. then flag_A_PR&L. = 1;
     end;
   %END;
   flag_C = sum(of flag_C_PR1-flag_C_PR&NPR.);
   flag_M = sum(of flag_M_PR1-flag_M_PR&NPR.);
   flag_A = sum(of flag_A_PR1-flag_A_PR&NPR.);
   flag_ABDOMI15P = sum(flag_C,flag_M, flag_A);
   if (flag_ABDOMI15P = 1 and flag_A = 1) or (flag_ABDOMI15P >= 2 and flag_A >= 2) then flag_PSI15_Denom=1;

%mend PSI15_denom_numer;
