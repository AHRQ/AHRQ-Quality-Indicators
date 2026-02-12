# SPADE Research Tool

**Symptom–Disease Pair Analysis of Diagnostic Error (SPADE)**  
A research and analytic tool for identifying potential diagnostic safety events using administrative healthcare data.

---

## Overview

SPADE is a methodology and analytic toolkit developed to help researchers and quality analysts identify potential diagnostic errors. The tool examines patterns between emergency department (ED) visits and subsequent inpatient hospitalizations, focusing on symptom–disease pairings that may indicate delayed or missed diagnoses.

SPADE is intended for research, quality improvement, and exploratory analysis using administrative or claims-based datasets.

---

## Key Features

- Look-forward analysis: evaluates inpatient admissions following ED visits for specific symptom groups
- Look-back analysis: evaluates prior ED visits among patients admitted with serious diagnoses
- Optional risk-difference estimation comparing observed and baseline rates
- Customizable clinical code groupings using ICD-10-CM
- Designed for large administrative datasets

---

## Repository Structure
```text
/
├── CONTROL.py                         # User configuration file
├── HELPERS.py                         # Utility and helper functions
├── SPADE_MEASURE.py                   # Core SPADE analysis logic
├── SPADE_RD.py                        # Risk difference analysis (optional)
├── SPADE_DISEASE_SYMPTOM_CODES.xlsx   # Clinical code definitions
├── data/                              # Input data (user supplied)
├── outputs/                           # Analysis outputs
├── docs/                              # Documentation and references
└── README.md
```

**Note: data/, outputs/, and docs/ are not required to be created within the repository folder. Users may locate these folders where they prefer, then update the location variables in CONTROL.py accordingly.**

---

## System Requirements

- Python 3.7 or higher
- Required Python packages:
```text
pip install pandas numpy matplotlib
```
---

### Data Requirements

SPADE requires two primary datasets.

**1. Emergency Department (ED) Data**
- Patient identifier
- First-listed diagnosis code
- Either [admission date and discharge date] or [days to event and length of stay]
- Patient age

**2. Inpatient (IP) Data**
- Patient identifier
- Principal diagnosis code
- Either [admission date and discharge date] or [days to event and length of stay]
- Patient age

**Additional requirements**
- Consistent patient identifiers across datasets
- ICD-10-CM diagnosis coding
- Standardized date formats

---

## Configuration

All user-specific settings are controlled through CONTROL.py, including:
- File paths for ED and inpatient data
- Variable and column names
- Date formats
- Analysis options (look-forward vs. look-back)
- Output directories

Example configuration:
```text
ed_loc  = "C:/DATA/ED"
ed_file = "ED.sas7bdat"
ip_loc  = "C:/DATA/IP"
ip_file = "IP.sas7bdat"
patient_id = "patient_id"
DX1 = "DX1"
```
### Customizing Clinical Codes

Clinical definitions are stored in *SPADE_DISEASE_SYMPTOM_CODES.xlsx.*

Users may:
- Review existing symptom–disease pairings
- Add or modify ICD-10-CM codes
- Adapt groupings for specific clinical questions
---

### Running the Analysis
Standard SPADE Measures
```text
python SPADE_MEASURE.py
```
Risk Difference Analysis (Optional)
```text
python SPADE_RD.py
```

---
### Output

SPADE generates multiple output files, including:

- Summary rate tables
- Time-to-event frequency tables
- Analytic datasets for further review
- Graphical figures illustrating admission patterns

All outputs are written to the configured outputs/ directory.

---
### Interpreting Results

Look-forward analyses quantify how often patients with specific ED symptoms are admitted shortly afterward with serious diagnoses.

Look-back analyses examine whether patients admitted with serious conditions had recent ED visits for related symptoms.

Risk difference results estimate excess rates relative to baseline comparisons.

SPADE results are intended for screening and research, not for definitive determination of diagnostic error.

---

## Contributing

Contributions are welcome.

To contribute:
- Fork the repository
- Create a feature branch
- Submit a pull request with a clear description of changes

Please ensure contributions align with the project’s scope and research intent.

---

## Documentation

Additional documentation, references, and supporting materials may be found on the AHRQ Quality Indicators website.

---

## Disclaimer

This software is provided “as is” for research and quality improvement purposes only.
It does not constitute clinical guidance or official policy of the Agency for Healthcare Research and Quality (AHRQ), the U.S. Department of Health and Human Services, or the U.S. Government.

---
## Support

For questions related to SPADE or AHRQ Quality Indicators tools contact the AHRQ Quality Indicators technical support team via email: qisupport@ahrq.hhs.gov.
