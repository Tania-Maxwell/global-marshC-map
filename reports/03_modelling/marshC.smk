from pathlib import Path

gee_data = "data/2023-08-16_data_covariates_global.csv"
soc_data = "data/data_clean_SOCD.csv" # need to copy in from 02_data_process/snakesteps/04_OCD/
marsh_extent = "data/placeholder"
tile_fornames = "tiles/export_the_wash_ENG.tif"
tile_dir = "tiles/"
import_global = "data/global_sample_5k.csv"


TILE_LIST = [p.name for p in Path(tile_dir).glob("tile*.tif")]

# define what you want the snakemake program to find
# for example, if it is an output of rule train_model, it won't run the rules that aren't needed 
rule all:
    input: 
        # "snakesteps/01_trainDat/trainDat.rds",
        # "snakesteps/02_CV/spatial_folds_grid.gpkg",
        # "snakesteps/02_CV/folds.rds",
        # "snakesteps/02_CV/nndm_folds.RDS"
        # "snakesteps/03_models/model_random.rds",
        # "snakesteps/03_models/model_spatial.rds",
        # "snakesteps/03_models/model_nndm.rds"
         expand("snakesteps/04_output/pred_0_30cm_t_ha_{tile}", tile=TILE_LIST),
         expand("snakesteps/04_output/pred_30_100cm_t_ha_{tile}", tile=TILE_LIST),
         expand("snakesteps/04_output/nndm_pred_0_30cm_t_ha_{tile}", tile=TILE_LIST),
         expand("snakesteps/04_output/nndm_pred_30_100cm_t_ha_{tile}", tile=TILE_LIST)
        # "snakesteps/05_DI/model_spatial_trainDI.rds",
        # "snakesteps/05_DI/model_spatial_trainDI_nndm.rds"
        #  expand("snakesteps/06_AOA/AOA_{tile}.rds", tile=TILE_LIST)
        # expand("snakesteps/06_AOA/AOA_nndm_{tile}.rds", tile=TILE_LIST)


rule prep_training_data:
    input: 
        site_layer = tile_fornames,
        gee_data = gee_data,
        soc_data = soc_data
    output: "snakesteps/01_trainDat/trainDat.gpkg"
    shell: "mkdir -p snakesteps/01_trainDat && Rscript scripts/01_training_data.R {input.site_layer} {input.gee_data} {input.soc_data} {output}"


rule cross_validate:
    input: 
        import_data = "snakesteps/01_trainDat/trainDat.gpkg",
        import_global = import_global
    output:
        output_grid = "snakesteps/02_CV/spatial_folds_grid.gpkg",
        output_folds = "snakesteps/02_CV/folds.RDS",
        output_folds_nndm = "snakesteps/02_CV/nndm_folds.RDS",
        output_fig_nndm = "snakesteps/02_CV/nndm_folds_plot.png"
    shell: "mkdir -p snakesteps/02_CV/ && Rscript scripts/02_cross-validation.R {input.import_data} {input.import_global} {output.output_grid} {output.output_folds} {output.output_folds_nndm}  {output.output_fig_nndm}"


rule train_model:
    input: 
        import_data = "snakesteps/01_trainDat/trainDat.gpkg",
        import_folds = "snakesteps/02_CV/folds.RDS",
        import_folds_nndm = "snakesteps/02_CV/nndm_folds.RDS"
    output:
        varImp_random = "snakesteps/03_models/model_random_varImp.png",
        varImp_spatial = "snakesteps/03_models/model_spatial_varImp.png",
        varImp_nndm = "snakesteps/03_models/model_nndm_varImp.png",
        output_random = "snakesteps/03_models/model_random.rds",
        output_spatial = "snakesteps/03_models/model_spatial.rds",
        output_nndm = "snakesteps/03_models/model_nndm.rds"
    shell: "mkdir -p snakesteps/03_models/ && Rscript scripts/03_train_model.R {input.import_data} {input.import_folds}  {input.import_folds_nndm}  {output.varImp_random} {output.varImp_spatial}  {output.varImp_nndm} {output.output_random} {output.output_spatial} {output.output_nndm}"


rule predict:
    input: 
        import_model = "snakesteps/03_models/model_nndm.rds",
        tile_fornames = tile_fornames, 
        import_tile = tile_dir + "{tile}" # all tiles in the tile_list defined at top
    output:
        pred_0_30 = "snakesteps/04_output/nndm_pred_0_30cm_t_ha_{tile}",
        pred_30_100 = "snakesteps/04_output/nndm_pred_30_100cm_t_ha_{tile}"
    shell: "mkdir -p snakesteps/04_output/ && Rscript scripts/04_predictions.R {input.import_model} {input.tile_fornames} {input.import_tile} {output.pred_0_30} {output.pred_30_100}"

rule trainDI_AOA:
    input:
        import_model = "snakesteps/03_models/model_nndm.rds"
    output:
        output_DI = "snakesteps/05_DI/model_nndm_trainDI.rds"
    shell: "mkdir -p snakesteps/05_DI/ && Rscript scripts/05_trainDI_AOA.R {input.import_model} {output.output_DI}"

rule calculate_AOA: 
    input: 
        import_model = "snakesteps/03_models/model_nndm.rds",
        import_DI = "snakesteps/05_DI/model_nndm_trainDI.rds",
        import_tile = tile_dir + "{tile}",
        tile_fornames = tile_fornames
    output:
         output_aoa = "snakesteps/06_AOA/AOA_nndm_{tile}.rds" #output as .rds
    shell: "mkdir -p snakesteps/06_AOA/ && Rscript scripts/06_AOA.R {input.import_model} {input.import_DI} {input.import_tile} {input.tile_fornames} {output.output_aoa} "

rule error_metric: 
    input: 
        import_model = "snakesteps/03_models/model_mmd,.rds",
        inmport_aoa = "snakesteps/06_AOA/AOA_nndm_{tile}.rds"
    output:
        output_error = ""
    shell: "mkdir -p snakesteps/07_error/ && Rscript scripts/07_Errormetric.R {input.import_model} {input.inmport_aoa} {output.output_error} "


rule visualize_AOA_DI: 
    input:
        pred_0_30 = "snakesteps/04_output/nndm_pred_0_30cm_t_ha_{tile}",
        pred_30_100 = "snakesteps/04_output/nndm_pred_30_100cm_t_ha_{tile}", 
        import_aoa = "snakesteps/06_AOA/AOA_nndm_{tile}.rds" ,
        import_DI = "snakesteps/05_DI/model_nndm_trainDI.rds"
    output:
        output_figure_0_30 = "snakesteps/08_figures/aoa_{tile}.png" #output as .png
    shell: "mkdir -p snakesteps/08_figs/ && Rscript scripts/08_visualizeAOA_DI.R {input.import_model} {input.inmport_aoa} {output.output_error} "



########## Spatial CV ###########
# to run, just change rule_all input

rule predict_spatial:
    input: 
        import_model = "snakesteps/03_models/model_spatial.rds",
        tile_fornames = tile_fornames, 
        import_tile = tile_dir + "{tile}" # all tiles in the tile_list defined at top
    output:
        pred_0_30 = "snakesteps/04_output/pred_0_30cm_t_ha_{tile}",
        pred_30_100 = "snakesteps/04_output/pred_30_100cm_t_ha_{tile}"
    shell: "mkdir -p snakesteps/04_output/ && Rscript scripts/04_predictions.R {input.import_model} {input.tile_fornames} {input.import_tile} {output.pred_0_30} {output.pred_30_100}"


## note: need to change here model_nndm or model_spatial depending on CV method
rule trainDI_AOA_spatial:
    input:
        import_model = "snakesteps/03_models/model_spatial.rds"
    output:
        output_DI = "snakesteps/05_DI/model_spatial_trainDI.rds"
    shell: "mkdir -p snakesteps/05_DI/ && Rscript scripts/05_trainDI_AOA.R {input.import_model} {output.output_DI}"

# note: need to change import_model and import_DI if nndm or spatial 
rule calculate_AOA_spatial: 
    input: 
        import_model = "snakesteps/03_models/model_spatial.rds",
        import_DI = "snakesteps/05_DI/model_spatial_trainDI.rds",
        import_tile = tile_dir + "{tile}",
        tile_fornames = tile_fornames
    output:
        output_aoa = "snakesteps/06_AOA/AOA_{tile}.rds" #output as .rds
    shell: "mkdir -p snakesteps/06_AOA/ && Rscript scripts/06_AOA.R {input.import_model} {input.import_DI} {input.import_tile} {input.tile_fornames} {output.output_aoa} "

rule error_metric_spatial: 
    input: 
        import_model = "snakesteps/03_models/model_spatial.rds",
        inmport_aoa = "snakesteps/06_AOA/AOA_{tile}.rds"
    output:
        output_error = ""
    shell: "mkdir -p snakesteps/07_error/ && Rscript scripts/07_Errormetric.R {input.import_model} {input.inmport_aoa} {output.output_error} "

