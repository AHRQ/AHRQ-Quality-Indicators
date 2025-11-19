
     label
     SEX = 'Sex of the patient'
     key = 'Unique record identifier'
     ;

     ARRAY DX(&NDX.)    $ DX1-DX&NDX.;
     ARRAY PR(&NPR.)    $ PR1-PR&NPR.;

     * ---------------------------------------------------------------- ;
     * --- DEFINE FIPS STATE COUNTY CODES AND FIPS POVERTY CATEGORY --- ;
     * ---------------------------------------------------------------- ;

     attrib FIPSTCO length=$5
     label='FIPS State County Code';
     FIPSTCO = put(PSTCO,Z5.);

     attrib POVCAT length=3
     label='FIPS Poverty Categories';
     POVCAT = put(FIPSTCO,$POVCAT.);

     * --------------------------------------------------------------- ;
     * -- DELETE NON-ADULT RECORDS WITH AGE <12 or AGE >55         --- ;
     * -- DELETE RECORDS WITH MALE PATIENT                         --- ;
     * -- DELETE RECORDS WITH MISSING AGE, SEX, DX1, DQTR, YEAR    --- ;
     * -- DELETE RECORDS THAT TRANSFER TO ANOTHER ACUTE CARE HOSPITAL  ;
     * --------------------------------------------------------------- ;
     
     if missing(SEX) then delete;
     if SEX = 1 then delete;
     if AGE lt 12 then delete;
     if AGE gt 55 then delete;
     if missing(DX1) then delete;
     if missing(DQTR) then delete;
     if missing(YEAR) then delete;
     if disp = 2 then delete;

    
     * -------------------------------------------------------------- ;
     * --- CREATE FAKE PAY1 AND RACE IF THEY ARE NOT IN INPUT DATA -- ;
     * -------------------------------------------------------------- ;

     %CreateFakePAY1_RACE;


     * -------------------------------------------------------------- ;
     * --- DEFINE STRATIFIER: PAYER CATEGORY ------------------------ ;
     * -------------------------------------------------------------- ;

     attrib PAYCAT length=3
     label='Patient Primary Payer';

     select (PAY1);
       when (1)  PAYCAT = 1;
       when (2)  PAYCAT = 2;
       when (3)  PAYCAT = 3;
       when (4)  PAYCAT = 4;
       when (5)  PAYCAT = 5;
       otherwise PAYCAT = 6;
     end;


     * -------------------------------------------------------------- ;
     * --- DEFINE STRATIFIER: RACE CATEGORY ------------------------- ;
     * -------------------------------------------------------------- ;

     attrib RACECAT length=3
     label = 'Race Categories';

     select (RACE);
       when (1)  RACECAT = 1;
       when (2)  RACECAT = 2;
       when (3)  RACECAT = 3;
       when (4)  RACECAT = 4;
       when (5)  RACECAT = 5;
       otherwise RACECAT = 6;
     end;


     * -------------------------------------------------------------- ;
     * --- DEFINE STRATIFIER: AGE CATEGORY  ------------------------- ;
     * -------------------------------------------------------------- ;
     
     attrib AGECAT length=3
     label='Age Categories';

     select;
       when (      AGE < 18)  AGECAT = 0;
       when (18 <= AGE < 40)  AGECAT = 1;
       when (40 <= AGE < 65)  AGECAT = 2;
       when (65 <= AGE < 75)  AGECAT = 3;
       when (75 <= AGE     )  AGECAT = 4;
       otherwise AGECAT = 0;
     end;


     * -------------------------------------------------------------- ;
     * --- DEFINE STRATIFIER: SEX CATEGORY  ------------------------- ;
     * -------------------------------------------------------------- ;
     
     attrib SEXCAT length=3
     label  = 'Sex Categories';

     select (SEX);
       when (1)  SEXCAT = 1;
       when (2)  SEXCAT = 2;
       otherwise SEXCAT = 0;
     end;

    * --------------------------------------------------------------------------------- ;
    * ------------------------- MHI Delivery flags ------------------------------------ ;
    * --------------------------------------------------------------------------------- ;

     *if the patient had a delivery;
      if  %MDX($DX_Delivery.) then deliv_dx = 1;
      if  %MPR($PR_Delivery.) then deliv_pr = 1;