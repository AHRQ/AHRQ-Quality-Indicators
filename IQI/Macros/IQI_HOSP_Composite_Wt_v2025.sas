*------------------------------------------------------------- *;
*--- IQI Hospital COMPOSITE WEIGHT ARRAY v2025        --- *;
*------------------------------------------------------------- *;

* Called from IQI_HOSP_COMPOSITE.sas;

* USER NOTE: If supplying weights, update array based on map. Each row must sum to one.;

/* Measure weight to Array variable map. */
/*W08 W09 W11 W12 W30 W31 -Weights for Mortality for Selected Procedures (IQI 90) */
/*W15 W16 W17 W18 W19 W20 -Weights for Mortality for Selected Conditions (IQI 91) */

ARRAY ARRY12{12}
WPIQ08 WPIQ09 WPIQ11 WPIQ12 WPIQ30 WPIQ31
WPIQ15 WPIQ16 WPIQ17 WPIQ18 WPIQ19 WPIQ20 (
0.007761603041 0.029589846787 0.047043458560 0.244531216452 0.591595553601 0.079478321559
0.122454056277 0.265299063184 0.149380104257 0.121060387770 0.066941736433 0.274864652079
);
