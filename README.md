# global-marshC-map
Scripts and data to model and map soil carbon in tidal marshes

# Repository structure

- `reports/01_covariate_layers/`: folder containing scripts with tests for processing covariate layers (i.e. clipping tiles, combining tiles)

- `reports/02_data_process/`: folder containing data processing scripts.
    - `marsh_data_process.smk`: snakemake file to run all scripts in this folder. Note: input data *import_SaltmarshC* is export from another repository. Will be hardcoded in final version (minor changes to be made). Second input data *import_GEE_data* located in /03_modelling.
    - `scripts/`: 
        -  `01_uniqueID_location.R`: ensure unique ID per location (especially for data coming from the Coastal Carbon Network)
        -  `02_point_locations.R`: manual check of data point locations.
        -  `03_bulk_density.R`: generate a transfer equation using samples with both bulk density and soil organic matter measured (both observed and estimated from soil organic carbon). Use this equation to estimate bulk density for samples without measured values. 
        -  `04_calculate_OCD`: Calculate organic carbon density for each sample (OC content x bulk density). This is the response for the model.  
        -  `exploratory/` : subfolder with previous test scripts (to be deleted)
    - `snakesteps/`: folder with output from snakemake file (i.e. output of all the scripts above)

- `reports/03_modelling/`: **folder containing all modelling scripts**
    - `marshC.smk`: snakemake file to run all scripts in this folder. 
    - `data/`: All input data for the marshC.smk file. Note: input data *data_clean_SOCD.csv* is the output from the 02_data_process/ folder (currently copied into folder for ease of use with snakemake and the HPC). 
    - `scripts/`: 
        - scripts run during snakemake: 
          - `01_training_data.R`: 
          - `02_cross-validation.R`: 
          - `03_train_model.R`: 
          - `04_predictions.R`:
          - `05_trainDI_AOA.R`:
          - `06_AOA.R`:
          - `07_Errormetric.R`:
          - `08_visualizeAOA_DI.R`:
        - Other scripts: 
            - `setup_HPC_Renv`.txt : 
            - Scripts directly downloaded from the [CAST](https://github.com/HannaMeyer/CAST/tree/master/R) package: `DItoErrormetric.R`, `knndm.R`, `trainDI.R`
            - `exploratory/` : subfolder with previous test scripts (to be deleted)
    - `snakesteps/`:  folder with output from snakemake file (i.e. output of all the scripts above)

- `reports/04_model_tests/`: folder containing scripts with tests (not yet refined - likely to be deleted/changed, currently used as a backup)

- `reports/05_figures/`: folder containing scripts to generate figures (not yet refined - likely to be deleted/changed, currently used as a backup)

# Processing steps

- Prepare environmental covariates in Google Earth Engine (GEE) - expand to cover entire saltmarsh area
- Export to Google Drive, rclone to HPC tiles folder
- Test code locally and on Ubuntu subsystem using snakemake file
- copy data and scripts file to HPC (to update files on HPC - the only file I edit on the HPC is the marshC_HPC.smk file)
- update marshC_HPC.smk on HPC with new rules (don't want to override because HPC smk has resource rules for slurm job submissions) 
- Run snakemake on HPC with slurm to run all modelling scrips and predict in parallel 

# Current test steps 

## Software tests

- Ensure R code runs on Ubuntu subsystem (same tidal environment as on the HPC)
- Ensure marshC.smk snakemake code runs on Ubuntu and debug
- Test marshC_HPC.smk snakemake file on HPC with small random test tiles
- Test marshC_HPC.smk snakemake on HPC with real key locations (compare to previous maps) 
- Compare predictions at key locations, when training model with data extracted at native resolution vs data extracted at resampled resolution

##  Comparing to previous maps
geometry: LA_delta_USA
1. Holmquist, J. R. et al. Accuracy and Precision of Tidal Wetland Soil Carbon Mapping in the Conterminous United States. Sci Rep 8, 9478 (2018).

geometry: west_port_AUS
2. Lewis, C. J. E. et al. Drivers and modelling of blue carbon stock variability in sediments of southeastern Australia. Biogeosciences 17, 2041–2059 (2020).

geometry: the_wash_ENG
3. Smeaton, C. et al. Using citizen science to estimate surficial soil Blue Carbon stocks in Great British saltmarshes. Frontiers in Marine Science 9, 959459 (2022).
