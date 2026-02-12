# =======================PROGRAM: SPADE_MEASURE.PY =======================
#  VERSION: SPADE Research Tool
#  RELEASE DATE: December 2025
# ========================================================================

# =============================Symptom-Disease Pair Analysis of Diagnostic Error (SPADE) Research Tool=====================================
#  SPADE 01 : Acute Myocardial Infarction (AMI) Inpatient Admission Rate within 7 or 30 days after an Emergency Department (ED) Visit - Look-forward 
#  SPADE 02 : Percentage of Acute Myocardial Infarction (AMI) Inpatient Admissions Preceded by an Emergency Department (ED) visit within 7 or 30 days - Look-Back 
#  SPADE 03 : Stroke Inpatient Admission Rate within 7 or 30 days after an Emergency Department (ED) Visit - Look-forward 
#  SPADE 04 : Percentage of Stroke Inpatient Admissions Preceded by an Emergency Department (ED) visit within 7 or 30 - Look-Back
# =========================================================================================================================================

# Import libraries and custom modules
import pandas as pd
import os
import matplotlib.pyplot as plt
from CONTROL import *    # Import variables, input/ouput locations from CONTROL.py. Users should update CONTROL.py with their own variables/locations before running this program.
from helpers import *

# LOOK-FORWARD ANALYSIS
def SPADE_LF(ed_data,ip_data):
    """
    Perform Look-Forward analysis for AMI and Stroke.
    This function identifies patients who had an inpatient admission for AMI or stroke
    within 7 or 30 days following an emergency department (ED) visit with symptoms.
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
    
        # Calculate the days_diff and filter rows where days_diff is between 1 and 30
        if date_col == DaysToEvent:
            merged[daysdiff_col] = merged[f"{DaysToEvent}_ip"] - (merged[f"{DaysToEvent}_ed"] + merged[LOS])
        else:
            merged[daysdiff_col] = (merged[f"{ADMDT}_ip"] - merged[f"{DISCDT}_ed"]).dt.days
        merged.loc[(merged[daysdiff_col] < 1) | (merged[daysdiff_col] > 30), daysdiff_col] = pd.NA
        assert merged[daysdiff_col].dropna().between(1, 30).all(), f"Values in {daysdiff_col} are not all in the range 1-30 or missing"    

        # Deduplicate: If an ED merged with multiple IP records (with non-missing daysdiff_col), keep only the one with the smallest daysdiff_col
        merged = merged.sort_values(by=[daysdiff_col], ascending=True, na_position='last')
        merged = merged.drop_duplicates(subset=linkvar_list + [f"{date_col}_ed"], keep='first')
        assert len(ed_df) == len(merged), f"Row count mismatch: ed_df ({len(ed_df)}) vs merged ({len(merged)}) for {cond_col}"

        # Calculate the numerator (within 7-day and within 30-day) for the condition        
        merged[f'{num_col}_7d'] = merged.apply(
            lambda row: 1 if row[sym_col] == 1 and row[cond_col] == 1 and row[daysdiff_col] <= 7 else 0, axis=1
        )
        merged[f'{num_col}_30d'] = merged.apply(
            lambda row: 1 if row[sym_col] == 1 and row[cond_col] == 1 and row[daysdiff_col] <= 30 else 0, axis=1
        )

        merged = merged.rename(columns={f"{date_col}_ip": f'{date_col}_ip_{cond_col}'})
        merged = merged.rename(columns={f"{date_col}_ed": date_col})
        # Merge results back to spade_LF_msr
        vars_to_merge = linkvar_list + [date_col]
        vars_to_keep = vars_to_merge + [cond_col, f'{date_col}_ip_{cond_col}', daysdiff_col, f'{num_col}_7d', f'{num_col}_30d']
        spade_LF_msr = spade_LF_msr.merge(
            merged[vars_to_keep],
            on=vars_to_merge,
            how='left'
        )
    return spade_LF_msr

# LOOK-BACK ANALYSIS
def SPADE_LB(ip_data, ed_data):
    """
    Perform Look-Back analysis for AMI and Stroke.
    This function identifies patients who had an inpatient admission for AMI and Stroke with an ED visit for
    symptoms occurring within 7 or 30 days prior to hospitalization.
    These cases serve as the numerator for the Look-Back SPADE measures.
    """
    spade_LB_msr = ip_data.copy()
    diseases = [(cond, f'SYMPTOM_{cond}', f'days_diff_{cond}', f'{cond}_LB') for cond in disease_list]
    for cond_col, sym_col, daysdiff_col, num_col in diseases:
        # Merge ip_data with ed_data to find ED visits before IP admission
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
        merged = ip_df.merge(ed_df, on=linkvar_list, how='left', suffixes=('_ip', '_ed'))
        assert merged[f"{date_col}_ed"].notnull().any(), f"No matches found for {cond_col} between ED and IP data"
        
        # Calculate the days_diff and filter rows where days_diff is between 1 and 30
        if date_col == DaysToEvent:
            merged[daysdiff_col] = merged[f"{DaysToEvent}_ip"] - (merged[f"{DaysToEvent}_ed"] + merged[LOS])
        else:
            merged[daysdiff_col] = (merged[f"{ADMDT}_ip"] - merged[f"{DISCDT}_ed"]).dt.days
        merged.loc[(merged[daysdiff_col] < 1) | (merged[daysdiff_col] > 30), daysdiff_col] = pd.NA
        assert merged[daysdiff_col].dropna().between(1, 30).all(), f"Values in {daysdiff_col} are not all in the range 1-30 or missing"

        # If multiple ED visits are identified, retain only the ED visit that is closest to the inpatient admission date.
        sort_vars = linkvar_list + [f"{date_col}_ip"] + [daysdiff_col] 
        merged = merged.sort_values(by=sort_vars, ascending=[True] * len(sort_vars))
        merged = merged.drop_duplicates(subset=linkvar_list + [f"{date_col}_ip"], keep='first')
        assert ip_data[cond_col].sum() == merged[cond_col].sum(), f"Sum mismatch for {cond_col}: ip_data={ip_data[cond_col].sum()}, merged={merged[cond_col].sum()}"
        assert not merged.duplicated(subset=linkvar_list + [f"{date_col}_ip"]).any(), f"Duplicates found in merged data for {cond_col} by {linkvar_list + [date_col]}"
        
        # Calculate the numerator (within 7-day and within 30-day) for the condition
        merged[f'{num_col}_7d'] = merged.apply(
            lambda row: 1 if row[sym_col] == 1 and row[cond_col] == 1 and row[daysdiff_col] <= 7 else 0, axis=1
        )
        merged[f'{num_col}_30d'] = merged.apply(
            lambda row: 1 if row[sym_col] == 1 and row[cond_col] == 1 and row[daysdiff_col] <= 30 else 0, axis=1
        )
        merged = merged.rename(columns={f"{date_col}_ed": f'{date_col}_ed_{cond_col}'})
        merged = merged.rename(columns={f"{date_col}_ip": date_col})
        # Merge results back to spade_LB_msr
        vars_to_merge = linkvar_list + [date_col]
        vars_to_keep = vars_to_merge + [sym_col, f'{date_col}_ed_{cond_col}', daysdiff_col, f'{num_col}_7d', f'{num_col}_30d']
        spade_LB_msr = spade_LB_msr.merge(
            merged[vars_to_keep],
            on=vars_to_merge,
            how='left'
        )
        assert len(spade_LB_msr) == len(ip_data), "spade_LB_msr and ip_data must have the same number of rows"
    return spade_LB_msr

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
    # Look-Forward approach for AMI/Stroke within 7 or 30 days
    ################################################################
    # Identify eligible ED visits with symptoms, i.e., denominators for Look-Forward approach
    LF_ed_elig = Create_LF_ed_elig(ed_qualify, disease_list)    
    # Calculate the SPADE measures with Look-Forward approach
    spade_LF_msr = SPADE_LF(LF_ed_elig,ip_w_diseases)
    # Export the SPADE measures to a csv file
    spade_LF_msr_output = rename_msr_columns(spade_LF_msr, disease_list, "LF")
    spade_LF_msr_output.to_csv(f"{output_loc}/SPADE_ANALYTIC_FILE_LF.csv", index=False)

    ################################################################
    # Look-Back approach for AMI/Stroke within 7 or 30 days
    ################################################################
    # Calculate the SPADE measures with Look-Back approach
    spade_LB_msr = SPADE_LB(ip_w_diseases, ed_qualify)
    # Export the SPADE measures to a csv file
    spade_LB_msr_output = rename_msr_columns(spade_LB_msr, disease_list, "LB")
    spade_LB_msr_output.to_csv(f"{output_loc}/SPADE_ANALYTIC_FILE_LB.csv", index=False)

    ################################################################
    # Results for Look-Forward and Look-Back analysis
    ################################################################
    # Calculate the days_diff statistics for Look-Forward approach
    days_diff_stats_LF = calculate_days_diff_stats_LF(spade_LF_msr, disease_list)
    # Calculate the days_diff statistics for Look-Back approach
    days_diff_stats_LB = calculate_days_diff_stats_LB(spade_LB_msr, disease_list)
    # Combine the days_diff statistics for both approaches
    days_diff_stats = rename_days_diff_stats(days_diff_stats_LF | days_diff_stats_LB)
    # Generate bar charts for the days_diff statistics
    generate_bar_charts(days_diff_stats_LF | days_diff_stats_LB, output_loc)

    # Calculate the summary statistics for Look-Forward approach and Look-Back approach
    summary_stats_LF = calculate_summary_stats_LF(spade_LF_msr, disease_list)
    summary_stats_LB = calculate_summary_stats_LB(spade_LB_msr, disease_list)
    summary_stats = rename_summary_stats(summary_stats_LF | summary_stats_LB)
    # Export the statistics to a xlsx file each tab for each condition
    export_stats_to_excel(days_diff_stats, f"{output_loc}/SPADE_FREQUENCY.xlsx")
    export_stats_to_excel(summary_stats, f"{output_loc}/SPADE_RESULT.xlsx")