from pathlib import Path

site_layer = "data/export_uk_layers_30m-0000009216-0000036864.tif"
gee_data = "data/2023-07-28_data_covariates_float_uk.csv"
soc_data = "../02_data_process/data/2023-07-17_data_clean_SOMconv_uniqueSiteName.csv"
marsh_extent = "data/placeholder"
tile_dir = "../01_covariate_layers/data/tiles_crop/"


TILE_LIST = [p.name for p in Path(tile_dir).glob("*.tif")]


rule all:
    input: 
        # "snakesteps/01_trainDat/trainDat.rds",
        # "snakesteps/02_CV/random_cv.rds",
        # "snakesteps/02_CV/spatial_cv.rds",
        # "snakesteps/03_models/model_random.rds",
        # "snakesteps/03_models/model_spatial.rds",
        expand("snakesteps/04_output/pred_0_30cm_t_ha_{tile}", tile=TILE_LIST),
        expand("snakesteps/04_output/pred_30_100cm_t_ha_{tile}", tile=TILE_LIST)



rule prep_training_data:
    input: 
        site_layer = site_layer,
        gee_data = gee_data,
        soc_data = soc_data
    output: "snakesteps/01_trainDat/trainDat.gpkg"
    shell: "mkdir -p snakesteps/01_trainDat && Rscript scripts/01_training_data.R {input.site_layer} {input.gee_data} {input.soc_data} {output}"


rule cross_validate:
    input: 
        import_data = "snakesteps/01_trainDat/trainDat.gpkg",
        output:
        output_grid = "snakesteps/02_CV/spatial_folds_grid.gpkg",
        output_folds = "snakesteps/02_CV/folds.RDS",
        output_random = "snakesteps/02_CV/random_cv.rds",
        output_spatial = "snakesteps/02_CV/spatial_cv.rds"
    shell: "mkdir -p snakesteps/02_CV/ && Rscript scripts/02_cross-validation.R {input.import_data} {output.output_grid} {output.output_folds} {output.output_random} {output.output_spatial}"


rule train_model:
    input: 
        import_data = "snakesteps/01_trainDat/trainDat.rds",
        import_random = "snakesteps/02_CV/random_cv.rds",
        import_spatial = "snakesteps/02_CV/spatial_cv.rds",
        import_folds = "snakesteps/02_CV/folds.RDS"
    output:
        output_random = "snakesteps/03_models/model_random.rds",
        output_spatial = "snakesteps/03_models/model_spatial.rds"
    shell: "mkdir -p snakesteps/03_models/ && Rscript scripts/03_train_model.R {input.import_data} {input.import_random} {input.import_spatial} {input.import_folds} {output.output_random} {output.output_spatial}"


rule predict:
    input: 
        import_model = "snakesteps/03_models/model_spatial.rds",
        import_tile = "tiles/{tile}"
    output:
        pred_0_30 = "snakesteps/04_output/pred_0_30cm_t_ha_{tile}",
        pred_30_100 = "snakesteps/04_output/pred_30_100cm_t_ha_{tile}"
    shell: "mkdir -p snakesteps/04_output/ && Rscript scripts/04_predictions.R {input.import_model} {input.import_tile} {output.pred_0_30} {output.pred_30_100}"
