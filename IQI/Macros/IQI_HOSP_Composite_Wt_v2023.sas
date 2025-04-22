*------------------------------------------------------------- *;
*--- IQI Hospital COMPOSITE WEIGHT ARRAY v2023             --- *;
*------------------------------------------------------------- *;

* Called from IQI_HOSP_COMPOSITE.sas;

* USER NOTE: If supplying weights, update array based on map. Each row must sum to one.;

/* Measure weight to Array variable map. */
/*W08 W09 W11 W12 W30 W31 -Weights for Mortality for Selected Procedures (IQI 90) */
/*W15 W16 W17 W18 W19 W20 -Weights for Mortality for Selected Conditions (IQI 91) */

ARRAY ARRY12{12} 
WPIQ08 WPIQ09 WPIQ11 WPIQ12 WPIQ30 WPIQ31 
WPIQ15 WPIQ16 WPIQ17 WPIQ18 WPIQ19 WPIQ20 (
0.007789060635 0.028537380901 0.047228641530 0.241732057178 0.591367912247 0.083344947509
0.122964616154 0.263879413023 0.145652913308 0.120989873259 0.063916986093 0.282596198163
);
