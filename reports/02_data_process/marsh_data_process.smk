
import_SaltmarshC = "../../../SaltmarshC/reports/04_data_process/data/data_cleaned_SOMconverted.csv" # this file comes from data paper export. will hard code file when finalized
import_GEE_data = "../03_modelling/data/2023-08-08_data_covariates_global.csv"

rule all:
    input: 
        #"snakesteps/01_uniqueID/data_clean_SOMconv_uniqueSiteName_forGEE.csv"
        # "snakesteps/02_checkLocations/data_clean_locationsEdit.csv"
        #"snakesteps/03_bulk_density/data_clean_BDconv.csv"
        "snakesteps/04_OCD/data_clean_SOCD.csv"


rule uniqueID:
    input:
        import_SaltmarshC = import_SaltmarshC
    output: 
        output_csv = "snakesteps/01_uniqueID/data_clean_SOMconv_uniqueSiteName.csv",
        output_for_GEE = "snakesteps/01_uniqueID/data_clean_SOMconv_uniqueSiteName_forGEE.csv"
    shell: "mkdir -p snakesteps/01_uniqueID && Rscript scripts/01_uniqueID_location.R {input.import_SaltmarshC} {output.output_csv} {output.output_for_GEE}"

rule check_locations:
    input:
        import_data = "snakesteps/01_uniqueID/data_clean_SOMconv_uniqueSiteName.csv",
        import_GEE_data = import_GEE_data
    output:
        export_file = "snakesteps/02_checkLocations/data_clean_locationsEdit.csv"
    shell: "mkdir -p snakesteps/02_checkLocations && Rscript scripts/02_point_locations.R {input.import_data} {input.import_GEE_data} {output.export_file}"

rule bulk_density:
    input:
        import_data = "snakesteps/02_checkLocations/data_clean_locationsEdit.csv"
    output:
        export_fig = "snakesteps/03_bulk_density/SOM_to_BD_graph.png",
        export_file = "snakesteps/03_bulk_density/data_clean_BDconv.csv"
    shell: "mkdir -p snakesteps/03_bulk_density && Rscript scripts/03_bulk_density.R {input.import_data} {output.export_fig} {output.export_file}"

rule calculate_OCD:
    input:
        import_data = "snakesteps/03_bulk_density/data_clean_BDconv.csv"
    output:
        export_file = "snakesteps/04_OCD/data_clean_SOCD.csv"
    shell: "mkdir -p snakesteps/04_OCD && Rscript scripts/04_calculate_OCD.R {input.import_data} {output.export_file}"

