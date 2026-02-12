# =======================PROGRAM: helper.PY ==============================
#  VERSION: SPADE Research Tool
#  RELEASE DATE: December 2025
# ========================================================================

# Import libraries and custom modules
import pandas as pd
import os
import re
import matplotlib.pyplot as plt
from CONTROL import *    # Import variables, input/ouput locations from CONTROL.py. Users should update CONTROL.py with their own variables/locations before running SPADE_MEASURE.py which calls HELPERS.py program.

# Specify the multiplier for rates of look-forward and look-backward measures
multipliers = {'LF': 10000, 'LB': 10000}

# this adds the noise to both the numerator and denominator based on Johns Hopkins specifications.
alpha=1/1000

# HELPER FUNCTIONS
def read_data(loc, file, file_type='sas7bdat'):
    """
    Reads a dataset and returns a pandas DataFrame.
    Supports 'sas7bdat', 'csv', and 'txt' file types.
    """
    # If file has an extension, use it as file_type
    if '.' in file:
        ext = file.split('.')[-1].lower()
        if ext in ['csv', 'txt', 'sas7bdat']:
            file_type = ext
    path = os.path.join(loc, f"{file}.{file_type}" if not file.endswith(f".{file_type}") else file)
    if file_type == 'sas7bdat':
        return pd.read_sas(path, format='sas7bdat', encoding='utf-8')
    elif file_type == 'csv':
        return pd.read_csv(path)
    elif file_type == 'txt':
        return pd.read_csv(path, delimiter='\t')
    else:
        raise ValueError("Unsupported file type. Use 'sas7bdat', 'csv', or 'txt'.")

def assert_data(data, required_columns):
    """Asserts that the required columns are present in the DataFrame."""
    missing_columns = required_columns - set(data.columns)
    assert not missing_columns, f"Missing required columns in data: {missing_columns}"

def has_daystoevent_or_admdt(data):
    """Checks if the DataFrame includes either DaysToEvent and LOS or ADMDT and DISCDT variables."""
    if DaysToEvent != "" and LOS != "" and DaysToEvent in data.columns and LOS in data.columns:
        return 1
    elif ADMDT != "" and DISCDT != "" and ADMDT in data.columns and DISCDT in data.columns:
        return 2
    else:
        return 0
    
def prepare_data(data, filter_age=18):
    """Prepares the data by filtering and checking for required columns."""
    base_required = set(linkvar_list) | {AGE, DX1}
    # Accept if either DaysToEvent & LOS or ADMDT & DISCDT is present
    if has_daystoevent_or_admdt(data) == 1:
        required_columns = base_required | {DaysToEvent, LOS}
    elif has_daystoevent_or_admdt(data) == 2:
        required_columns = base_required | {ADMDT, DISCDT}
    else:
        raise AssertionError("Missing required column in data: either DaysToEvent or ADMDT must be present in data.")
    assert_data(data, required_columns)
    # Keep only required columns    
    cols_to_keep = list(required_columns)
    data = data[cols_to_keep]
    # Filter out patients under filter_age   
    if filter_age is not None:          
        data = data[data[AGE] >= filter_age]    
    # Drop rows with missing values in required columns
    data = data.dropna(subset=required_columns)
    # convert ADMDT to datetime if ADMDT is available
    if has_daystoevent_or_admdt(data) == 2:
        data[ADMDT] = pd.to_datetime(data[ADMDT], errors='coerce')
        data[DISCDT] = pd.to_datetime(data[DISCDT], errors='coerce')
    return data

def read_disease_setnames(setname_loc, setname_file, file_sheets):
    """Reads the disease set names from the specified Excel file."""
    # Read all sheets from to define diseases
    diseases = pd.read_excel(f"{setname_loc}/{setname_file}", sheet_name=list(file_sheets.values()))
    # Ensure all columns in each disease DataFrame are upper case
    for sheet_name in diseases:
        diseases[sheet_name].columns = [col.upper() for col in diseases[sheet_name].columns]
    # Create a dictionary to hold disease setname tuples and their corresponding codes
    disease_setnames = {}
    for disease, sheet_name in file_sheets.items():
        df = diseases[sheet_name]
        if 'SETNAME' in df.columns and 'CODE' in df.columns:
            for setname in df['SETNAME'].dropna().unique():
                codes = df[df['SETNAME'] == setname]['CODE'].dropna().tolist()
                disease_setnames[(disease, setname)] = codes
    print("Disease setname tuples found in Excel file:")
    for key, codes in disease_setnames.items():
        print(f"{key}: {len(codes)} codes")
    return disease_setnames

def get_diseases(ip_data, setnames):
    """Identifies AMI and STROKE diseases in inpatient data."""
    # Assign disease flags based on setnames keys (which are tuples of (disease, setname))
    for (disease, setname), codes in setnames.items():
        flag_col = f"{disease.upper()}"
        if flag_col not in ip_data.columns:
            ip_data[flag_col] = 0
        ip_data[flag_col] = ip_data[flag_col] | ip_data[DX1].isin(codes).astype(int)
        print(f"Flag counts for {disease}, setname {setname}: {ip_data[flag_col].sum()}")
    # Keep only cases with at least one disease flag present (dynamic for any disease/setname)
    disease_flags = list({f"{disease.upper()}" for disease, _ in setnames.keys()})
    ip_data = ip_data[ip_data[disease_flags].any(axis=1)]    
    return ip_data

def remove_duplicates(data):
    """Removes duplicated inpatient stays or duplicated ED visits by patient ID and DaysToEvent (or ADMDT)."""
    # Remove duplicates based on patient_ID and DaysToEvent(or ADMDT, i.e., use DaysToEvent if available, otherwise use ADMDT for duplicate checking)
    dup_subset = linkvar_list.copy()
    if DaysToEvent in data.columns:
        dup_subset.append(DaysToEvent)
    else:
        dup_subset.append(ADMDT)
    # Check for duplicates and remove duplicate rows if any
    if data.duplicated(subset=dup_subset).any():
        num_duplicates = data.duplicated(subset=dup_subset).sum()
        print(f"Duplicates found based on {dup_subset}. Removing {num_duplicates} duplicate rows...")
        data = data.drop_duplicates(subset=dup_subset)
    else:
        data = data
    return data

def read_symptom_data(sym_loc, sym_file, file_sheets):
    """Reads the symptom data from the specified Excel file and tabs."""
    # Read the symptom data from the specified Excel file
    symptom_data = {}
    for disease, sheet_name in file_sheets.items():
        df = pd.read_excel(f"{sym_loc}/{sym_file}", sheet_name=sheet_name)
        # Ensure all columns are upper case for consistency
        df.columns = [col.upper() for col in df.columns]
        df.rename(columns={
                'ICD-10-CM CODE': 'ICD10_CODE',
                'ICD-10-CM CODE DESCRIPTION': 'ICD_10_CODE_DESCRIPTION'
            }, inplace=True)
        symptom_data[disease] = df
    return symptom_data

def get_symptom(ed_data, symptom_data):
    """Merges ed data with symptom data to identify symptoms."""
    # Get symptom variables
    merged_data = ed_data.copy()
    for symptom_name, sym_df in symptom_data.items():
        sym_df = sym_df[['ICD10_CODE']]
        merged_data = merged_data.merge(sym_df, left_on=DX1, right_on='ICD10_CODE', how='left', indicator=True)
        merged_data[f'SYMPTOM_{symptom_name}'] = (merged_data["_merge"]=='both').astype(int)
        merged_data = merged_data.drop('_merge', axis=1) 
        merged_data = merged_data.loc[:, ~merged_data.columns.str.startswith("ICD10_CODE")]
    # Keep only cases with at least one symptom for any disease
    symptom_cols = [f"SYMPTOM_{disease}" for disease in symptom_data.keys()]
    merged_data = merged_data[merged_data[symptom_cols].any(axis=1)]
    return merged_data

def first_in_360(df, date_col=DaysToEvent):
    """Identify eligible ED visits - the first qualifying ED visit and subsequent qualifying ED visits occuring >= 360 days."""
    # df should be already sorted by DaysToEvent or ADMDT ascendingly
    mask = [True]
    last_date = df.iloc[0][date_col]
    for curr_date in df[date_col].iloc[1:]:
        if date_col == DaysToEvent:
            diff = curr_date - last_date
        else:
            diff = (curr_date - last_date).days
        if diff >= 360:
            mask.append(True)
            last_date = curr_date
        else:
            mask.append(False)
    df["ED_Elig"] = [1 if m else 0 for m in mask]
    return df

def Create_LF_ed_elig(ed_qualify, disease_list):
    """
    Create the eligible ED visits for Look-Forward approach.
    This function identifies eligible ED visits (i.e., the first qualifying ED visit and subsequent ED visits occuring >= 360 days), 
    which serves as the denominator for the SPADE measures.
    """
    LF_ed_elig = ed_qualify.copy()
    if has_daystoevent_or_admdt(LF_ed_elig) == 1:
        sortvar_list = linkvar_list + [DaysToEvent]
        date_col = DaysToEvent
    elif has_daystoevent_or_admdt(LF_ed_elig) == 2:
        sortvar_list = linkvar_list + [ADMDT]
        date_col = ADMDT
    # Get symptoms for each disease
    for cond in disease_list:
        temp = ed_qualify.loc[ed_qualify[f"SYMPTOM_{cond}"] == 1].copy()
        count_ED_qualify = temp.shape[0]
        temp = temp.sort_values(sortvar_list, ascending=True)
        temp = temp.loc[:, sortvar_list]
        #Identify eligible ED visits - the first qualifying ED visit and subsequent ED visits occuring >= 360 days
        temp = temp.groupby(linkvar_list, group_keys=False, sort=False).apply(first_in_360, date_col).reset_index(drop=True)
        temp = temp[temp['ED_Elig'] == 1]
        count_ED_Elig = temp.shape[0]
        temp = temp.rename(columns={'ED_Elig': f'ED_Elig_{cond}'})
        # Add eligible ED visits flag to the ED data
        LF_ed_elig = LF_ed_elig.merge(
            temp,
            on=sortvar_list,
            how='left')
        LF_ed_elig[f'ED_Elig_{cond}'] = LF_ed_elig[f'ED_Elig_{cond}'].fillna(0).astype(int)
        assert len(LF_ed_elig) == len(ed_qualify), "LF_ed_elig and ed_qualify must have the same number of rows!"
        # Calculate and print the counts of ED_qualify for this disease
        count_ED_Elig_chk = LF_ed_elig[f'ED_Elig_{cond}'].sum()
        assert count_ED_Elig == count_ED_Elig_chk, f"Mismatch: count_ED_Elig ({count_ED_Elig}) != count_ED_Elig_chk ({count_ED_Elig_chk}) for {cond}"
        print(f"{cond} - count of eligible EDs = {count_ED_Elig} over total qualifying EDs ({count_ED_qualify})\n")
    return LF_ed_elig
           
def calculate_days_diff_stats_LF(data, disease_list, max_days_diff=30):
    """Calculates statistics for days_diff based on the condition list."""
    stats = {}
    disease_list = [(cond, f'ED_Elig_{cond}', f'days_diff_{cond}') for cond in disease_list]
    for cond_col, sym_col, daysdiff_col in disease_list:
        # Filter data for the given disease and days_diff in 1-30
        filtered_data = data[(data[sym_col] == 1) & (data[daysdiff_col] >= 1) & (data[daysdiff_col] <= max_days_diff)]
        # Group by days_diff and calculate counts and percentages
        days_diff_stats = (
            filtered_data.groupby(daysdiff_col)
            .agg(
                count=(cond_col, 'sum')
            )
            .reset_index()
        )
        days_diff_stats['percent'] = days_diff_stats['count'] / len(filtered_data) * 100
        days_diff_stats = days_diff_stats.rename(columns={daysdiff_col: "daysdiff"})
        ## Create a summary dictionary
        stats[f"{cond_col}_LF"] = days_diff_stats
    return stats

def calculate_days_diff_stats_LB(data, disease_list, max_days_diff=30):
    """Calculates statistics for days_diff based on the condition list."""
    stats = {}
    disease_list = [(cond, f'SYMPTOM_{cond}', f'days_diff_{cond}') for cond in disease_list]
    for cond_col, sym_col, daysdiff_col in disease_list:
        # Filter data for the given disease and days_diff in 1-30
        filtered_data = data[(data[cond_col] == 1) & (data[daysdiff_col] >= 1) & (data[daysdiff_col] <= max_days_diff)] 
        # Group by days_diff and calculate counts and percentages
        days_diff_stats = (
            filtered_data.groupby(daysdiff_col)
            .agg(
                count=(sym_col, 'sum')
            )
            .reset_index()
        )
        days_diff_stats['percent'] = days_diff_stats['count'] / len(filtered_data) * 100
        days_diff_stats = days_diff_stats.rename(columns={daysdiff_col: "daysdiff"})
        ## Create a summary dictionary
        stats[f"{cond_col}_LB"] = days_diff_stats
    return stats

def rename_days_diff_stats(days_diff_stats):
    """
    Renames the days_diff statistics DataFrame columns.
    """
    days_diff_stats_renamed = {spade_msr[key]: value for key, value in days_diff_stats.items()}
    # Rename the columns in each DataFrame
    for key, df in days_diff_stats_renamed.items():
        if "LF" in key:
            days_diff_stats_renamed[key] = df.rename(columns={
                "daysdiff": "Days from ED visit to Inpatient Admission",
                "count": "Number of Inpatient Admissions",
                "percent": "Percentage of Total (%)"
            })
        elif "LB" in key:
            days_diff_stats_renamed[key] = df.rename(columns={
                "daysdiff": "Days Before Inpatient Admission",
                "count": "Number of Inpatient Admissions with Prior ED Visit",
                "percent": "Percentage of Total (%)"
            })    
    return days_diff_stats_renamed

def generate_bar_charts(spade_dict, output_dir, rd_suffix=False):
    """
    Generate bar charts for days_diff statistics for each SPADE measure.
    """
    for name, df in spade_dict.items():
        plt.figure(figsize=(8, 5))
        plt.bar(df['daysdiff'], df['count'])
        if 'LF' in name:
            plt.xlabel('Days from ED visit to Inpatient Admission')
            plt.ylabel('Number of Inpatient Admissions')
        elif 'LB' in name:
            plt.xlabel('Days Before Inpatient Admission')
            plt.ylabel('Number of Inpatient Admissions with Prior ED Visit')
        else:
            plt.xlabel('Days Difference')
            plt.ylabel('Counts')
        plt.title(spade_msr_desc.get(name, f'Days Difference by {name}'))
        plt.xticks(rotation=45)
        plt.tight_layout()
        save_path = os.path.join(output_dir, f"{spade_msr.get(name, name)}{'_RD' if rd_suffix else ''}.png")
        plt.savefig(save_path)
        plt.close()

def calculate_summary_stats_LF(data, disease_list):
    """Calculates summary statistics for days_diff based on the condition list."""
    disease_list = [(cond, f'ED_Elig_{cond}', f'days_diff_{cond}', f'{cond}_LF') for cond in disease_list]
    summary_rows = {}
    for cond_col, sym_col, daysdiff_col, num_col in disease_list:
        # Filter data for the given condition and days_diff in 1-30
        filtered_data = data[(data[sym_col] == 1) & (data[daysdiff_col] >= 1) & (data[daysdiff_col] <= 30)]
        # total number of qualifying ED visits, i.e., denominator
        temp = data[data[sym_col] == 1]
        total_visits = len(temp)    
        # Calculate sum of admissions within 7 and 30 days
        cond_7day = filtered_data[f'{num_col}_7d'].sum()
        cond_30day = filtered_data[f'{num_col}_30d'].sum()      
        # Create a summary dictionary
        summary_long = []
        for days, num in [(7, cond_7day), (30, cond_30day)]:
            rate = (num / total_visits) * multipliers['LF'] if total_visits else 0
            summary_long.append({
            "Approach": "Look-Forward",
            "Disease": cond_col,
            "Days": days,
            "Denom": total_visits,
            "Num": num,
            "Rate": rate
            })
        summary_rows[f"{cond_col}_LF"] = pd.DataFrame(summary_long)
    return summary_rows

def calculate_summary_stats_LB(data, disease_list):
    """Calculates summary statistics for days_diff based on the condition list."""
    disease_list = [(cond, f'SYMPTOM_{cond}', f'days_diff_{cond}', f'{cond}_LB') for cond in disease_list]
    summary_rows = {}
    for cond_col, sym_col, daysdiff_col, num_col in disease_list:
        # Filter data for the given condition and days_diff in 1-30
        filtered_data = data[(data[cond_col] == 1) & (data[daysdiff_col] >= 1) & (data[daysdiff_col] <= 30)]
        # total number of IP stays with condition, i.e., denominator
        total_stays = len(data[(data[cond_col] == 1)])    
        # Calculate sum of admissions within 7 and 30 days
        cond_7day = filtered_data[f'{num_col}_7d'].sum()
        cond_30day = filtered_data[f'{num_col}_30d'].sum()      
        # Create a summary dictionary
        summary_long = []
        for days, num in [(7, cond_7day), (30, cond_30day)]:
            rate = (num / total_stays) * multipliers['LB'] if total_stays else 0
            summary_long.append({
            "Approach": "Look-Back",
            "Disease": cond_col,
            "Days": days,
            "Denom": total_stays,
            "Num": num,
            "Rate": rate
            })
        summary_rows[f"{cond_col}_LB"] = pd.DataFrame(summary_long)
    return summary_rows

def rename_summary_stats(stats_df):
    """
    Renames summary statistics DataFrame columns.
    """
    stats_df_renamed = {spade_msr[key]: value for key, value in stats_df.items()}
    # Rename the columns in each DataFrame
    for key, df in stats_df_renamed.items():
        if "LF" in key:
            stats_df_renamed[key] = df.rename(columns={
            "Denom": "Number of Eligible ED visits",
            "Num": "Number of Inpatient Admissions",
            "Rate": "Inpatient Admissions with Prior ED Visits per 10,000 ED Visits (Look-Forward)"
            })
        elif "LB" in key:
            stats_df_renamed[key] = df.rename(columns={
            "Denom": "Number of Inpatient Admissions",
            "Num": "Number of Inpatient Admissios with Prior ED visit",
            "Rate": "Inpatient Admissions with Prior ED Visits per 10,000 Inpatient Admissions (Look-Back)"
            })    
    return stats_df_renamed

def rename_msr_columns(data, disease_list, approach='LF'):
    """
    Renames numerator columns in the DataFrame based on the condition list and SPADE mapping.
    Also adds suffixes to certain columns based on the approach.
    """
    df = data.copy()
    rename_map = {}
    cols_to_suffix = [DaysToEvent, LOS, ADMDT, DISCDT, DX1, AGE]
    for col in df.columns:
        new_col = col
        if col in disease_list:
            new_col = f"FLAG_{col}"
        elif "SYMPTOM_" in new_col:
            new_col = new_col.replace("SYMPTOM_", "FLAG_SYM_")
        if 'ip' in new_col:
            new_col = new_col.replace('ip', 'IP')
        if 'ed' in new_col:
            new_col = new_col.replace('ed', 'ED')
        if 'days_diff' in new_col:
            new_col = new_col.replace('days_diff', 'DAYS_DIFF')
        if col in cols_to_suffix:
            if approach == 'LF':
                new_col = f"{col}_ED"
            elif approach == 'LB':
                new_col = f"{col}_IP"
        rename_map[col] = new_col
    df.rename(columns=rename_map, inplace=True)
   
    pattern = r'daystoevent_(ip|ed)_(stroke|ami)'
    cols_to_drop = [col for col in df.columns if re.search(pattern, col, re.IGNORECASE)]
    df.drop(columns=cols_to_drop, inplace=True)

    return df

def export_stats_to_excel(stats_dict, output_path):
    """
    Exports the dictionary to an Excel file with separate sheets for each disease.
    """
    # Define the desired order of sheets
    sheet_order = list(spade_msr.values())
    with pd.ExcelWriter(output_path) as writer:
        for sheet in sheet_order:
            if sheet in stats_dict:
                stats_dict[sheet].to_excel(writer, sheet_name=sheet, index=False)
        # Write any remaining sheets not in the specified order
        for disease, df in stats_dict.items():
            if disease not in sheet_order:
                df.to_excel(writer, sheet_name=disease, index=False)