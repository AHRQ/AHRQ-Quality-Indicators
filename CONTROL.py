# =======================PROGRAM: CONTROLE.PY ============================
#  VERSION: SPADE Research Tool
#  RELEASE DATE: December 2025
# ========================================================================

# ------------------------------------------------------------------
# --- SET LOCATION OF PYTHON PROGRAMS                            ---
# ------------------------------------------------------------------
prg_loc = "C:/SPADE"          # Replace this with the name of the folder where the SPADE Research Tool is located

# ------------------------------------------------------------------
# --- SET DISEASE LIST AND MEASURE LIST                          ---
# ------------------------------------------------------------------
disease_list = ["AMI", "STROKE"]

spade_msr = {"AMI_LF": "SPADE01_AMI_LF",
             "AMI_LB": "SPADE02_AMI_LB",
             "STROKE_LF": "SPADE03_STROKE_LF",
             "STROKE_LB": "SPADE04_STROKE_LB"}

spade_msr_desc = {
            "AMI_LF": "SPADE 01: AMI Admissions After ED visits with Symptoms (Look-Forward)",
            "AMI_LB": "SPADE 02: AMI Admissions with Prior ED visits with Symptoms (Look-Back)",
            "STROKE_LF": "SPADE 03: Stroke Admissions After ED visits with Symptoms (Look-Forward)",
            "STROKE_LB": "SPADE 04: Stroke Admissions with Prior ED visits with Symptoms (Look-Back)"
    }

# ------------------------------------------------------------------
# --- SET VARIABLES FOR INPUT DATA                               ---
# ------------------------------------------------------------------
patient_ID  = "VisitLink"    # Replace this with the patient ID variable name in user's data
hospst      = "HOSPST"       # Replace this with None or "" if patient_ID is unique across states in user's data
DaysToEvent = "DaysToEvent"  # Replace this with the days to event variable name in user's data if available (required if ADMDT or DISCDT is not available)
LOS         = "LOS"          # Replace this with the length of stay (in days) variable name in user's data (required if ADMDT or DISCDT is not available)
ADMDT       = ""             # Replace this with the inpatient admission date variable name in user's data (required if DaystoEvent or LOS is not available)
DISCDT      = ""             # Replace this with the ED discharge date variable name in user's data (required if DaystoEvent or LOS is not available)
DX1         = "DX1"          # Replace this with the ICD-10-CM principal diagnosis code variable name in user's inpatient data (the same variable name should be used in user's ED data as the first listed diagnosis code)
AGE         = "AGE"          # Replace this with the age variable name in user's data

# ------------------------------------------------------------------
# --- SET LINKAGE VARIABLE LIST                                  ---
# --- This list is used to link inpatient and ED data.           ---
# ------------------------------------------------------------------
linkvar_list = [patient_ID] if hospst is None or hospst == "" else [hospst, patient_ID]    # Replace this with the list of variable(s) used to link inpatient and ED data

# ------------------------------------------------------------------
# --- SET LOCATIONS FOR INPUT DATA                               ---
# ------------------------------------------------------------------
ip_loc  = "C:/DATA/IP"           # Replace this with the folder name of user's inpatient data
ed_loc  = "C:/DATA/ED"           # Replace this with the folder of users ED visits data

ip_file = "IP.sas7bdat"          # Replace this with the file name of inpatient data
ed_file = "ED.sas7bdat"          # Replace this with the file name of ED visits data

sym_loc         = prg_loc                                # Replace this with the folder name of the symptoms mapping file
sym_file        = "SPADE_DISEASE_SYMPTOM_CODES.xlsx"     # Replace this with the file name of the symptoms mapping file
sym_file_sheets = {'AMI': 'AMI-Symptom', 'STROKE': 'Stroke-Symptom'}  # Replace this with the sheet names in the sym_file, the list should match the disease_list

disease_setname_loc  = prg_loc                            # Replace this with the folder name of the disease setname file
disease_setname_file = "SPADE_DISEASE_SYMPTOM_CODES.xlsx" # Replace this with the file name of the disease setnames file
disease_file_sheets  = {'AMI': 'AMI-Disease', 'STROKE': 'Stroke-Disease'}  # Replace this with the sheet names in the disease_setname_file, the list should match the disease_list

# ------------------------------------------------------------------
# --- SET LOCATION FOR OUTPUT DATA                               ---
# ------------------------------------------------------------------
output_loc = "C:/OUTPUT"    # Replace this with the folder name for output data
