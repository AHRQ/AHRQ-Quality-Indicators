# ==========================PROGRAM: SPADE_RD.PY =========================
#  VERSION: SPADE Research Tool
#  RELEASE DATE: December 2025
# ========================================================================

# =============================Symptom-Disease Pair Analysis of Diagnostic Error (SPADE) Research Tool=====================================
#  SPADE 01 : Acute Myocardial Infarction (AMI) Inpatient Admission Rate within 30 days after an Emergency Department (ED) Visit - Look-forward 
#  SPADE 03 : Stroke Inpatient Admission Rate within 30 days after an Emergency Department (ED) Visit - Look-forward 
# =========================================================================================================================================

# Import libraries and custom modules
import pandas as pd
import os
import matplotlib.pyplot as plt
from CONTROL import *    # Import variables, input/ouput locations from CONTROL.py. Users should update CONTROL.py with their own variables/locations before running this program.
from helpers import *

# LOOK-FORWARD ANALYSIS
def SPADE_LF_RD(ed_data,ip_data):
    """
    Perform Look-Forward analysis for AMI and Stroke.
    This function identifies patients who had an inpatient admission for AMI or stroke
    within 30, 90, 91_360 days following an emergency department (ED) visit with symptoms.
    These admissions serve as the numerator for the corresponding SPADE measures.
    """
    spade_LF_msr = ed_data.copy()
    diseases = [(cond, f'ED_Elig_{cond}', f'days_diff_{cond}', f'{cond}_LF') for cond in disease_list]
    for cond_col, sym_col, daysdiff_col, num_col in diseases:
        # Merge ed_data with ip_data to identify look-Forward inpatients with the condition
        if has_daystoevent_or_admdt(ed_data) == 1:
            date_col = DaysToEvent
            date_comb = [DaysToEvent, LOS]            
            ip_vars = linkvar_list + [date_col] + [cond_col]
        else:
            date_col = ADMDT
            date_comb = [ADMDT, DISCDT]
            ip_vars = linkvar_list + date_comb + [cond_col]        
        ed_vars = linkvar_list + date_comb + [sym_col]
        ed_df = ed_data.loc[ed_data[sym_col] == 1, ed_vars]
        ip_df = ip_data.loc[ip_data[cond_col] == 1, ip_vars]
        merged = ed_df.merge(ip_df, on=linkvar_list, how='left', suffixes=('_ed', '_ip'))
        assert merged[f"{date_col}_ip"].notnull().any(), f"No matches found for {cond_col} between ED and IP data"
    
        # Calculate the days_diff and filter rows where days_diff is between 1 and 360
        if date_col == DaysToEvent:
            merged[daysdiff_col] = merged[f"{DaysToEvent}_ip"] - (merged[f"{DaysToEvent}_ed"] + merged[LOS])
        else:
            merged[daysdiff_col] = (merged[f"{ADMDT}_ip"] - merged[f"{DISCDT}_ed"]).dt.days
        merged.loc[(merged[daysdiff_col] < 1) | (merged[daysdiff_col] > 360), daysdiff_col] = pd.NA
        assert merged[daysdiff_col].dropna().between(1, 360).all(), f"Values in {daysdiff_col} are not all in the range 1-360 or missing"    

        # Deduplicate: If an ED merged with multiple IP records (with non-missing daysdiff_col), keep only the one with the smallest daysdiff_col
        merged = merged.sort_values(by=[daysdiff_col], ascending=True, na_position='last')
        merged = merged.drop_duplicates(subset=linkvar_list + [f"{date_col}_ed"], keep='first')
        assert len(ed_df) == len(merged), f"Row count mismatch: ed_df ({len(ed_df)}) vs merged ({len(merged)}) for {cond_col}"

        # Calculate the numerator (within 30-day, within 90-day, between 91-360 and baseline) for the condition        
        merged[f'{num_col}_30d'] = merged.apply(
            lambda row: 1 if row[sym_col] == 1 and row[cond_col] == 1 and row[daysdiff_col] <= 30 else 0, axis=1
        )
        merged[f'{num_col}_90d'] = merged.apply(
            lambda row: 1 if row[sym_col] == 1 and row[cond_col] == 1 and row[daysdiff_col] <= 90 else 0, axis=1
        )
        merged[f'{num_col}_91_360d'] = merged.apply(
            lambda row: 1 if row[sym_col] == 1 and row[cond_col] == 1 and row[daysdiff_col] <= 360 and row[daysdiff_col] >= 91 else 0, axis=1
        )        

        merged[f'{num_col}_Denominator_base'] = merged.apply(
            lambda row: 1 if row[sym_col] == 1 and row[f'{num_col}_90d'] == 0 else 0, axis=1
        )
        merged[f'{num_col}_Numerator_base'] = (1/9) * merged[f'{num_col}_91_360d']
        
        merged = merged.rename(columns={f"{date_col}_ip": f'{date_col}_ip_{cond_col}'})
        merged = merged.rename(columns={f"{date_col}_ed": date_col})
        # Merge results back to spade_LF_msr
        vars_to_merge = linkvar_list + [date_col]
        vars_to_keep = vars_to_merge + [cond_col, f'{date_col}_ip_{cond_col}', daysdiff_col, f'{num_col}_30d', f'{num_col}_90d', f'{num_col}_91_360d', f'{num_col}_Denominator_base', f'{num_col}_Numerator_base']
        spade_LF_msr = spade_LF_msr.merge(
            merged[vars_to_keep],
            on=vars_to_merge,
            how='left'
        )
    return spade_LF_msr

def calculate_summary_stats_LF_RD(data, disease_list):
    """Calculates summary statistics based on the condition list."""
    summary_rows = {}

    for cond in disease_list:
        # Filter eligible rows
        filtered_data = data[(data[f"ED_Elig_{cond}"] == 1)]

        # Columns to sum
        cols = [
            f"{cond}_LF_30d",
            f"ED_Elig_{cond}",
            f"{cond}_LF_90d",
            f"{cond}_LF_91_360d",
            f"{cond}_LF_Numerator_base",
            f"{cond}_LF_Denominator_base",
        ]

        # Sum numeric values
        sums = (
            filtered_data[cols]
            .apply(pd.to_numeric, errors="coerce")
            .fillna(0)
            .sum()
        )

        # Calculate rates
        obs_rate = (
            (sums[f"{cond}_LF_30d"] + alpha) /
            (sums[f"ED_Elig_{cond}"] + 1.0)
        ) * multipliers["LF"]

        base_rate = (
            (sums[f"{cond}_LF_Numerator_base"] + alpha) /
            (sums[f"{cond}_LF_Denominator_base"] + 1.0 - (3 * alpha))
        ) * multipliers["LF"]

        rd = obs_rate - base_rate

        # Collect row
        row = {
            "Approach" : "Look-Forward" ,
            "Disease": cond,            
            "Number of Eligible ED visits": sums[f"ED_Elig_{cond}"],
            "Number of Inpatient Admissions within 30 days": sums[f"{cond}_LF_30d"],
            "Number of Inpatient Admissions within 90 days": sums[f"{cond}_LF_90d"],
            "Number of Inpatient Admissions within 91-360 days": sums[f"{cond}_LF_91_360d"],
            "Number of Baseline Inpatient Admissions per month": sums[f"{cond}_LF_Numerator_base"],
            "Number of Baseline Eligible ED visits": sums[f"{cond}_LF_Denominator_base"],
            "Inpatient Observed Rate per 10,000 ED visits": obs_rate,
            "Inpatient Baseline Rate per 10,000 ED visits": base_rate,
            "Risk Difference per 10,000 ED visits": rd,
        }

        row_key = spade_msr.get(f"{cond}_LF", f"{cond}_LF")  # fallback to cond_LF if not found
        summary_rows[row_key] = pd.DataFrame([row])        

    # Return as DataFrame (one row per condition)
    return summary_rows
 
if __name__ == "__main__":    
    # Prepare the inpatient data
    ip_data = prepare_data(read_data(ip_loc, ip_file))
    # Get disease setnames and associated ICD-10-CM codes
    disease_setnames = read_disease_setnames(disease_setname_loc, disease_setname_file, disease_file_sheets)
    # Assign disease variables (AMI and STROKE) to the inpatient data
    ip_w_diseases = get_diseases(ip_data, disease_setnames)
    # Remove duplicates based on patient_ID and DaysToEvent(or ADMDT, i.e., use DaysToEvent if available, otherwise use ADMDT for duplicate checking)
    ip_w_diseases = remove_duplicates(ip_w_diseases)

    # Read in the symptom code list
    symptom_data = read_symptom_data(sym_loc, sym_file, sym_file_sheets)
    # Prepare the ED data
    ed_data = prepare_data(read_data(ed_loc, ed_file))
    ed_w_symptoms = get_symptom(ed_data, symptom_data)
    # Remove duplicates based on patient_ID and DaysToEvent(or ADMDT, i.e., use DaysToEvent if available, otherwise use ADMDT for duplicate checking)
    ed_qualify = remove_duplicates(ed_w_symptoms)

    ################################################################
    # Look-Forward approach for AMI/Stroke within 30 days, 90 days, 91-360 days and baseline
    ################################################################
    # Identify eligible ED visits with symptoms, i.e., denominators for Look-Forward approach
    LF_ed_elig = Create_LF_ed_elig(ed_qualify, disease_list)    
    # Calculate the SPADE measures with Look-Forward approach
    spade_LF_msr = SPADE_LF_RD(LF_ed_elig,ip_w_diseases)
    # Export the SPADE measures to a csv file
    spade_LF_msr_output = rename_msr_columns(spade_LF_msr, disease_list, "LF")
    spade_LF_msr_output.to_csv(f"{output_loc}/SPADE_RD_ANALYTIC_FILE_LF.csv", index=False)

    ################################################################
    # Results for Look-Forward  
    ################################################################
    # Calculate the days_diff statistics for Look-Forward approach
    days_diff_stats_LF = calculate_days_diff_stats_LF(spade_LF_msr, disease_list, max_days_diff=360)
    days_diff_stats = rename_days_diff_stats(days_diff_stats_LF)
    # Generate bar charts for the days_diff statistics
    generate_bar_charts(days_diff_stats_LF, output_loc, rd_suffix=True)

    # Calculate the summary statistics for Look-Forward approach
    summary_stats_LF = calculate_summary_stats_LF_RD(spade_LF_msr, disease_list)    
    
    # Export the statistics to a xlsx file each tab for each condition
    export_stats_to_excel(days_diff_stats, f"{output_loc}/SPADE_RD_FREQUENCY.xlsx")
    export_stats_to_excel(summary_stats_LF, f"{output_loc}/SPADE_RD_RESULT.xlsx")