from pathlib import Path

gee_data = "data/2023-08-16_data_covariates_global.csv"
soc_data = "data/data_clean_SOCD.csv" # need to copy in from 02_data_process/snakesteps/04_OCD/
marsh_extent = "data/placeholder"
tile_fornames = "tiles/export_the_wash_ENG.tif"
import_global = "data/global_sample_5k.csv"

# tile_dir = "tiles_locations/" # run for key locations 
#TILE_LIST = [p.name for p in Path(tile_dir).glob("export*.tif")]

tile_dir = "tiles/" # for small tile test (quicker to run)
TILE_LIST = [p.name for p in Path(tile_dir).glob("tile*.tif")] # for small test


def get_mem_mb(wildcards, attempt):
    return attempt * 4000



rule all:
    input: 
        # "snakesteps/01_trainDat/trainDat.rds",
        # "snakesteps/02_CV/spatial_folds_grid.gpkg",
        # "snakesteps/02_CV/folds.rds",
        # "snakesteps/02_CV/nndm_folds.RDS"
        # "snakesteps/03_models/model_random.rds",
        # "snakesteps/03_models/model_spatial.rds",
        # "snakesteps/03_models/model_nndm.rds"
        #  expand("snakesteps/04_output/pred_0_30cm_t_ha_{tile}", tile=TILE_LIST),
        #  expand("snakesteps/04_output/pred_30_100cm_t_ha_{tile}", tile=TILE_LIST),
        #  expand("snakesteps/04_output/nndm_pred_0_30cm_t_ha_{tile}", tile=TILE_LIST),
        #  expand("snakesteps/04_output/nndm_pred_30_100cm_t_ha_{tile}", tile=TILE_LIST),
        # "snakesteps/05_DI/model_spatial_trainDI.rds",
        # "snakesteps/05_DI/model_nndm_trainDI.rds"
        # expand("snakesteps/06_AOA/AOA_{tile}.rds", tile=TILE_LIST)
        # expand("snakesteps/06_AOA/AOA_nndm_0_30_{tile}.rds", tile=TILE_LIST)
        expand("snakesteps/07_error/error_0_30_nndm_{tile}.png", tile=TILE_LIST)


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
    resources:
        mem_mb = 3000
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
    resources:
        mem_mb = 3000
    shell: "mkdir -p snakesteps/03_models/ && Rscript scripts/03_train_model.R {input.import_data} {input.import_folds}  {input.import_folds_nndm}  {output.varImp_random} {output.varImp_spatial}  {output.varImp_nndm} {output.output_random} {output.output_spatial} {output.output_nndm}"


#### input and change whether running spatial or nndm model

### spatial
# import_model = "snakesteps/03_models/model_spatial.rds"
# pred_0_30 = "snakesteps/04_output/pred_0_30cm_t_ha_{tile}"
# pred_30_100 = "snakesteps/04_output/pred_30_100cm_t_ha_{tile}"
# output_DI = "snakesteps/05_DI/model_spatial_trainDI.rds"
# output_aoa_0_30 = "snakesteps/06_AOA/AOA_0_30_{tile}.rds"
# output_aoa_30_100 = "snakesteps/06_AOA/AOA_30_100_{tile}.rds"
# output_figDI_0_30 =  "snakesteps/08_figures/DI_0_30_{tile}.png"
# output_figDI_30_100 = "snakesteps/08_figures/DI_30_100_{tile}.png"
# output_figure_0_30 = "snakesteps/08_figures/pred_AOA_0_30_{tile}.png" #output as .png
# output_figure_30_100 = "snakesteps/08_figures/pred_AOA_30_100_{tile}.png" #output as .png
# output_error_0_30 = "snakesteps/07_error/error_0_30_{tile}.png"
# output_error_30_100 = "snakesteps/07_error/error_30_100_{tile}.png"

# ##### nndm 
import_model = "snakesteps/03_models/model_nndm.rds"
pred_0_30 = "snakesteps/04_output/nndm_pred_0_30cm_t_ha_{tile}",
pred_30_100 = "snakesteps/04_output/nndm_pred_30_100cm_t_ha_{tile}"
output_DI = "snakesteps/05_DI/model_nndm_trainDI.rds"
output_aoa_0_30 = "snakesteps/06_AOA/AOA_nndm_0_30_{tile}.rds"
output_aoa_30_100 = "snakesteps/06_AOA/AOA_nndm_30_100_{tile}.rds"
output_figDI_0_30 =  "snakesteps/08_figures/DI_0_30_nndm_{tile}.png"
output_figDI_30_100 = "snakesteps/08_figures/DI_30_100_nndm_{tile}.png"
output_figure_0_30 = "snakesteps/08_figures/pred_AOA_0_30_nndm_{tile}.png" #output as .png
output_figure_30_100 = "snakesteps/08_figures/pred_AOA_30_100_nndm_{tile}.png" #output as .png
output_error_0_30 = "snakesteps/07_error/error_0_30_nndm_{tile}.png"
output_error_30_100 = "snakesteps/07_error/error_30_100_nndm_{tile}.png"

rule predict:
    input: 
        import_model = import_model,
        tile_fornames = tile_fornames, 
        import_tile = tile_dir + "{tile}" # all tiles in the tile_list defined at top
    output:
        pred_0_30 = pred_0_30,
        pred_30_100 = pred_30_100
    resources:
        mem_mb = 6000,
        runtime = 3
    shell: "mkdir -p snakesteps/04_output/ && Rscript scripts/04_predictions.R {input.import_model} {input.tile_fornames} {input.import_tile} {output.pred_0_30} {output.pred_30_100}"


rule trainDI_AOA:
    input:
        import_model = import_model
    output:
        output_DI = output_DI
    resources:
        mem_mb = 4000,
        runtime = 480
    shell: "mkdir -p snakesteps/05_DI/ && Rscript scripts/05_trainDI_AOA.R {input.import_model} {output.output_DI}"

rule calculate_AOA: 
    input: 
        import_model = import_model,
        import_DI = output_DI,
        import_tile = tile_dir + "{tile}",
        tile_fornames = tile_fornames,
        pred_0_30 = pred_0_30,
        pred_30_100 = pred_30_100
    output:
        output_aoa_0_30 = output_aoa_0_30,
        output_aoa_30_100 = output_aoa_30_100,
        output_figDI_0_30 = output_figDI_0_30, 
        output_figDI_30_100 = output_figDI_30_100,
        output_figure_0_30 = output_figure_0_30, #output as .png
        output_figure_30_100 = output_figure_30_100
    resources:
        mem_mb = 6000, # Resources are always meant to be specified as total per job, not by thread 
        runtime = 3
    shell: "mkdir -p snakesteps/06_AOA/ && Rscript scripts/06_AOA.R {input.import_model} {input.import_DI} {input.import_tile} {input.tile_fornames} {input.pred_0_30} {input.pred_30_100} {output.output_aoa_0_30} {output.output_aoa_30_100} {output.output_figDI_0_30} {output.output_figDI_30_100} {output.output_figure_0_30} {output.output_figure_30_100} "

rule error_metric: 
    input: 
        import_model = import_model,
        import_aoa_0_30 = output_aoa_0_30,
        import_aoa_30_100 = output_aoa_30_100
    output:
        output_error_0_30 = output_error_0_30,
        output_error_30_100 = output_error_30_100
    shell: "mkdir -p snakesteps/07_error/ && Rscript scripts/07_Errormetric.R {input.import_model} {input.import_aoa_0_30} {input.import_aoa_30_100} {output.output_error_0_30} {output.output_error_30_100} "

