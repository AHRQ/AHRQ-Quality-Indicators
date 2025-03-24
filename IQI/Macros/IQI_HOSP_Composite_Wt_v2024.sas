*------------------------------------------------------------- *;
*--- IQI Hospital COMPOSITE WEIGHT ARRAY v2024             --- *;
*------------------------------------------------------------- *;

* Called from IQI_HOSP_COMPOSITE.sas;

* USER NOTE: If supplying weights, update array based on map. Each row must sum to one.;

/* Measure weight to Array variable map. */
/*W08 W09 W11 W12 W30 W31 -Weights for Mortality for Selected Procedures (IQI 90) */
/*W15 W16 W17 W18 W19 W20 -Weights for Mortality for Selected Conditions (IQI 91) */

ARRAY ARRY12{12} 
WPIQ08 WPIQ09 WPIQ11 WPIQ12 WPIQ30 WPIQ31 
WPIQ15 WPIQ16 WPIQ17 WPIQ18 WPIQ19 WPIQ20 (
0.007730909437 0.028260019352 0.046958658246 0.242730364542 0.591311018256 0.083009030166
0.123431577750 0.264236534623 0.146095018193 0.121049905469 0.064357044076 0.280829919890
);
