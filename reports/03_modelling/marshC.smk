from pathlib import Path

site_layer = "data/export_uk_layers_30m-0000009216-0000036864.tif"
gee_data = "data/2023-07-31_data_covariates_global.csv"
soc_data = "data/data_clean_SOCD.csv" # need to copy in from 02_data_process/snakesteps/04_OCD/
marsh_extent = "data/placeholder"
tile_fornames = "tiles/export_uk_layers_30m-0000000000-0000046080.tif"
tile_dir = "tiles/"


TILE_LIST = [p.name for p in Path(tile_dir).glob("tile*.tif")]


rule all:
    input: 
        # "snakesteps/01_trainDat/trainDat.rds",
        # "snakesteps/02_CV/random_cv.rds",
        # "snakesteps/02_CV/spatial_cv.rds",
        "snakesteps/03_models/model_random.rds",
        "snakesteps/03_models/model_spatial.rds",
        # expand("snakesteps/04_output/pred_0_30cm_t_ha_{tile}", tile=TILE_LIST),
        # expand("snakesteps/04_output/pred_30_100cm_t_ha_{tile}", tile=TILE_LIST),
        # expand("snakesteps/05_AOA/AOA_{tile}", tile=TILE_LIST)



rule prep_training_data:
    input: 
        site_layer = site_layer,
        gee_data = gee_data,
        soc_data = soc_data
    output: "snakesteps/01_trainDat/trainDat.gpkg"
    shell: "mkdir -p snakesteps/01_trainDat && Rscript scripts/01_training_data.R {input.site_layer} {input.gee_data} {input.soc_data} {output}"


rule cross_validate:
    input: 
        import_data = "snakesteps/01_trainDat/trainDat.gpkg"
    output:
        output_grid = "snakesteps/02_CV/spatial_folds_grid.gpkg",
        output_folds = "snakesteps/02_CV/folds.RDS"
    shell: "mkdir -p snakesteps/02_CV/ && Rscript scripts/02_cross-validation.R {input.import_data} {output.output_grid} {output.output_folds}"


rule train_model:
    input: 
        import_data = "snakesteps/01_trainDat/trainDat.gpkg",
        import_folds = "snakesteps/02_CV/folds.RDS"
    output:
        varImp_random = "snakesteps/03_models/model_random_varImp.png",
        varImp_spatial = "snakesteps/03_models/model_spatial_varImp.png",
        output_random = "snakesteps/03_models/model_random.rds",
        output_spatial = "snakesteps/03_models/model_spatial.rds"
    shell: "mkdir -p snakesteps/03_models/ && Rscript scripts/03_train_model.R {input.import_data} {input.import_folds} {output.varImp_random} {output.varImp_spatial} {output.output_random} {output.output_spatial}"


rule predict:
    input: 
        import_model = "snakesteps/03_models/model_spatial.rds",
        tile_fornames = tile_fornames, 
        import_tile = tile_dir + "{tile}"
    output:
        pred_0_30 = "snakesteps/04_output/pred_0_30cm_t_ha_{tile}",
        pred_30_100 = "snakesteps/04_output/pred_30_100cm_t_ha_{tile}"
    shell: "mkdir -p snakesteps/04_output/ && Rscript scripts/04_predictions.R {input.import_model} {input.tile_fornames} {input.import_tile} {output.pred_0_30} {output.pred_30_100}"


rule trainDI_AOA:
    input:
        import_model = "snakesteps/03_models/model_spatial.rds"
    output:
        output_DI = "snakesteps/05_AOA/model_spatial_trainDI.rds"
    shell: "mkdir -p snakesteps/05_AOA/ && Rscript scripts/05_trainDI_AOA.R {input.import_model} {output.output_DI}"

rule calculate_AOA: 
    input: 
        inmport_DI = "snakesteps/05_AOA/model_spatial_trainDI.rds",
        import_tile = tile_dir + "{tile}"
    output:
        AOA = "snakesteps/05_AOA/AOA_{tile}"
    shell: "mkdir -p snakesteps/05_AOA/ && Rscript scripts/06_AOA.R {input.import_DI} {input.import_tile} {output.AOA} "

