# Agency for Healthcare Research & Quality (AHRQ) <br> Quality Indicators (QI), SAS QI Software

Harnessing the power of SAS/STAT Software for advanced users of the AHRQ QI modules.

## Installation

AHRQ's SAS QI Software is a set of programs that run using SAS (Statistical Analysis System).

To learn more about computer and data requirements of SAS QI Software, visit our Wiki page to [get started](https://github.com/AHRQ/qi-sas/wiki/Getting-Started).

Latest Release: SAS QI v2024.0.1 Full Software Package

The AHRQ QI software now includes the Maternal Health Indicators (MHI) BETA module - New!

Download the latest software version from the [AHRQ QI Website](https://qualityindicators.ahrq.gov/software/sas_qi) or [Releases](https://github.com/AHRQ/qi-sas/releases).

## Contributing

If you're interested in contributing code and/or documentation, please see [our guide to contributing](https://github.com/AHRQ/qi-sas/wiki/Contributing-to-AHRQ-SAS-QI-Software).

## Discussions

To share ideas for new features, ask the community for help, or share something you've made, use the [Discussions](https://github.com/AHRQ/qi-sas/discussions) collaborative communication forum.

_Disclaimer: The statements and opinions expressed are solely of the authors and do not represent any official position of the Agency for Healthcare Research & Quality, the Department of Health and Human Services, or the U.S. Government._

## Documentation

Visit our [repository Wiki](https://github.com/AHRQ/qi-sas/wiki) for software documentation and additional resources.


## Installing pyspark with jupyter notebooks

Note: Apache Spark is more compatiable with JDK 11

1. Navigate to the directory where the archive was downloaded and extract the file
```bash
tar -xzvf [FileName.tar.gz]
```
2. Install the JDK (MAC) 
```bash
sudo mv jdk-11.0.1.jdk /Library/Java/JavaVirtualMachines/
```
3. Check java version:
```bash
java --version
```

4. Install Python
```bash
brew install python
```
5. Check python version:
```bash
python3 --version
```

6. Install Apache Spark
```bash
brew install apache-spark
```
7. Install Jypter Notebook
```bash
pip install notebook
```

8. Run Jupiter Notebook
```bash
jupyter notebook
```

### Execute Notebook in Shell

```bash
jupyter nbconvert --execute QI.ipynb --to notebook --stdout --inFile "/Users/mshaque/Workarea/Projects/qi-pyspark-poc/DATA/sid_2021_8M.csv" 
```

### Execute the comparison between different reports

```bash
jupyter nbconvert --execute QI-QC.ipynb --to notebook --stdout --pyFile "/Users/mshaque/Workarea/Projects/qi-pyspark-poc/DATA/MHI-report-10K.csv/part-00000-07102378-1961-4f92-abb6-c655a4b93104-c000.csv" --refFile "/Users/mshaque/Workarea/Projects/qi-pyspark-poc/DATA/MHAO_v2024_21_10K.TXT" --qiFile "/Users/mshaque/Workarea/Projects/qi-pyspark-poc/DATA/QI_v2024_10K.csv"
```
