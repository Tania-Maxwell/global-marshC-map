/// testing and adapting extract covariate info per data point
// from Nicholas Murray, covariate_sample script

// updated: 22-09-05
// notes: 

// var imports = require('users/tlgm2/TidalmarshC:combine_layers_global');
// var europe = imports.europe;

var uk = ee.Geometry.Polygon(
    [[[-14.773542314042771,49.80571809296125], 
  [3.3319264359572287,49.80571809296125],
  [3.3319264359572287,59.73119695514474],
  [-14.773542314042771,59.73119695514474],
  [-14.773542314042771,49.80571809296125]]], null, false ); // only UK
  
  
  
  /****************************************** 
   * Global Variables
   ******************************************/
  var site = ee.Geometry.Polygon(
    [[[0.6621003481445342,51.67979880621543],
    [0.9882569643554717,51.67979880621543], 
    [0.9882569643554717,51.78951129583516], 
    [0.6621003481445342,51.78951129583516], 
    [0.6621003481445342,51.67979880621543]]], null, false);
  
  
  var trainingSet = ee.FeatureCollection('users/tlgm2/training_data/2023-08-30_data_clean_SOMconv_uniqueLatLong_forGEE');// path to training set
   // .filterBounds(uk); // reduce to site
  var startDate = '2014-01-01'; // reference period for landsat sampling
  var endDate = '2021-12-31';// reference period for landsat sampling
  var covariatePath = 'users/tlgm2/covariate_global/'; // path to covariate folder
  var yearString = startDate.slice(0,4)
    .concat(endDate.slice(0,4));
  var version = 'v0_1'
  var landsatCollection = 'L8'
  
  /****************************************************
   * Import saltmarsh extent map
   ****************************************************/
  //exported at 30m using the trainingdata_marshextent script
  var saltmarsh_v2_6 = ee.Image('users/tlgm2/covariate_global/saltmarsh_30m');
  
  Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);
  
  /****************************************** 
   * Sample covariates
   ******************************************/
   
  
  //create a function to load the covariate layers according to their covariateName
  // this comes from the properiues which we created when exporting to an asset
  var covariateLoader = function(covariateName){
    // load covariates
    var assetPath = covariatePath
      .concat(covariateName)
      .concat('_')
      .concat(version);
    var im_raw = ee.Image(assetPath);
    //var im = im_raw.resample('bilinear').reproject({crs:'EPSG:4326', scale:30});
    return im_raw;
  };
  
  //create a function to load the landsat-derived covariate layers according to their covariateName
  // this is a bit more complicated since the naming is 
  var landsatLoader = function(covariateName){
    // load covariates
    var assetPath = covariatePath
      .concat(landsatCollection)
      .concat('_')
      .concat(covariateName)
      .concat('_')
      .concat(yearString)
      .concat('_')
      .concat('v0_1'); 
    var im = ee.Image(assetPath);
    return im;
  };
  
  
  //CHANGE HERE - need to add more layer as it goes
  var covariateComposite0 = covariateLoader('maxTemp')
          .addBands(landsatLoader('ndvi'))
          // .addBands (covariateLoader('Human_modification'))
          .addBands (covariateLoader('M2Tide'))
          .addBands (covariateLoader('PETdry'))    
          .addBands (covariateLoader('PETwarm'))
          .addBands (covariateLoader('TSM'))
          .addBands (covariateLoader('ECU_mode').select('CLUSTER').rename('ECU'))
          .addBands (covariateLoader('minTemp'))
          .addBands (covariateLoader('minPrecip'))
          .addBands (covariateLoader('maxPrecip'));
          // .addBands (covariateLoader('popDens'));
  
  /****************************************************
   * Import Clark et al millenial SLR map 
   ****************************************************/ 
  
  var clarkFC = ee.FeatureCollection("users/tlgm2/covariate_global/SLR");
  
  // var clark0 = ee.ImageCollection(clarkFC.map(function (feature) {
  //   return ee.Image.constant(feature.get('Zone_ID')).rename('Zone_ID');
  // }))
  
  var clark0 = clarkFC.reduceToImage({
    properties: ['Zone_ID'],
    reducer: ee.Reducer.median()
  }).rename('SLR_zone');
  
  
  var clark = clark0.toInt16();
  
  
  /****************************************************
   * Import DEMs
   ****************************************************/
  ////////////// Copernicus DEM ///////////////////
  
  // raw elevation
  var elevation0 = ee.ImageCollection("COPERNICUS/DEM/GLO30")
   .select('DEM')
   .median();
  
  //reducing image size elevation
  var elevation = elevation0.multiply(100).int16();
  // var elevation = elevation0
  
  // raw slope
  var elevation_reproj = elevation0.reproject({crs:'EPSG:4326', scale:30});
  
  var slope0 = ee.Terrain.slope(elevation_reproj);
  
  //reducing image size slope
  var slope = slope0.multiply(10).int16();
  //var slope = slope0;
  
  var copDEM = ee.Image([elevation0, slope0])
    .rename('copernicus_elevation', 'copernicus_slope')
    .reproject({crs:'EPSG:4326', scale:30}); /// do NOT need to multiply by saltmarsh area - want values also out of extent
  
  
  ////////////// MERIT DEM ///////////////////
  
  // raw elevation
  var elevation_meritDEM_raw = ee.Image("MERIT/DEM/v1_0_3")
  . select('dem');
  
  //reducing image size elevation
  var elevation_meritDEM = elevation_meritDEM_raw.multiply(100).int16();
  
  // raw slope
  var slope_meritDEM_raw = ee.Terrain.slope(elevation_meritDEM_raw);
  
  //reducing image size slope
  var slope_meritDEM = slope0.multiply(10).int16();
  
  
  ///// combine
  
  var meritDEM = ee.Image([elevation_meritDEM_raw, slope_meritDEM_raw])
    .rename('merit_elevation', 'merit_slope')
    .resample('bilinear')
    .reproject({crs:'EPSG:4326', scale:30}); /// do NOT need to multiply by saltmarsh area - want values also out of extent
  
  ////////////// SRTM DEM ///////////////////
  
  // import SRTM elevation
  var elevation_SRTM_raw = ee.Image('USGS/SRTMGL1_003')
  .select('elevation');
  
  //reducing image size elevation
  var elevation_SRTM = elevation_SRTM_raw.multiply(100).int16();
  
  // slope
  var slope_SRTM_raw = ee.Terrain.slope(elevation_SRTM_raw);
  
  //reducing image size slope
  var slope_SRTM = slope_SRTM_raw.multiply(10).int16();
  
  
  ///// combine
  
  var SRTM = ee.Image([elevation_SRTM_raw, slope_SRTM_raw])
    .rename('srtm_elevation', 'srtm_slope')
    .resample('bilinear')
    .reproject({crs:'EPSG:4326', scale:30}); /// do NOT need to multiply by saltmarsh area - want values also out of extent
  
  
  ////////////// CoastalDEM ///////////////////
  
  // raw elevation
  var elevation_CoastalDEM_raw = ee.Image('users/tlgm2/covariate_global/CoastalDEM_v0_1');
  
  //reducing image size elevation
  var elevation_CoastalDEM = elevation_CoastalDEM_raw.multiply(100).int16();
  
  // raw slope
  var slope_CoastalDEM_raw = ee.Terrain.slope(elevation_CoastalDEM_raw);
  
  print(slope_CoastalDEM_raw);
  
  //reducing image size slope
  var slope_CoastalDEM = slope0.multiply(10).int16();
  
  
  ///// combine
  
  var coastalDEM = ee.Image([elevation_CoastalDEM_raw, slope_CoastalDEM_raw])
    .rename('coastalDEM_elevation', 'coastalDEM_slope')
    .resample('bilinear')
    .reproject({crs:'EPSG:4326', scale:30}); /// do NOT need to multiply by saltmarsh area - want values also out of extent
  
  
  /****************************************************
   * Import EVI and SAVI (saved to Cloud Bucket)
   ****************************************************/
  
  var evi_import = require('users/tlgm2/TidalmarshC:covariate_layers/Mosaic_EVI');
  var evi_raw = evi_import.EVI.median();
  
  var evi = evi_raw;
  //.multiply(100).int16()
  
  
  var savi_import = require('users/tlgm2/TidalmarshC:covariate_layers/Mosaic_SAVI');
  var savi_raw = savi_import.SAVI.median();
  var savi = savi_raw;
  //.multiply(100).int16()
  
  
  /****************************************************
   * Load all together
   ****************************************************/
  
  
  var covariateComposite1 = covariateComposite0
    .addBands(copDEM) //only including one for now to simplify
    // .addBands(meritDEM)
    // .addBands(SRTM)
    // .addBands(coastalDEM)
    // .addBands(evi_raw)
    // .addBands(savi_raw)
    .addBands(clark);
  
  //var covariateComposite = covariateComposite1.toInt16();
  var covariateComposite = covariateComposite1.toFloat();
  
  print(covariateComposite);
  
  var bands = covariateComposite.bandNames();
  
  print(bands); // 
  
  //var covariate_extentonly = covariateComposite.multiply(saltmarsh_v2_6);
  
  Map.addLayer(covariateComposite.clip(north_Brazil))
  
  
  /****************************************************
   * Extract data at training points
   ****************************************************/
  
  
  function sampleCovariates(feature) {
      // sample covariates at each training point
      var predictorData = covariateComposite.reduceRegion({ 
      reducer: ee.Reducer.first(), 
      geometry: feature.geometry(),
      scale: 1}); 
      return feature.set(predictorData);
  }
  
  var predictorSet = trainingSet.map(sampleCovariates); 
  
  // print (predictorSet)
  
  
  // // test to see the number of points located in Tom's saltmarsh
  // var test_covariate = saltmarsh_v2_6.sampleRegions(trainingSet);
  
  // print(test_covariate); //number of points located in the saltmarsh
  
  // print(trainingSet);
  
  // var dataDraw = trainingSet.draw({color: '800080', pointRadius: 5, strokeWidth: 3});
  // Map.addLayer(dataDraw, {}, 'Training data');
  
  
  
  
  // // export
  
  // AS AN ASSET
  
  //var assetName = 'users/tlgm2/predictor_export/22-09-05_site_predictor'; // path and asset name of predictorSet
  
  // var vars = {
  //   startDate:startDate,
  //   endDate:endDate,
  //   landsatCollection: 'LC08/C02/T1_L2',
  //   covariateName: 'site test [ndvi, SRTM, maxTemp, minTemp]',
  //   assetName: assetName,
  //   dateGenerated: ee.Date(Date.now())
  // };
  
  // Export.table.toAsset({
  //   collection: predictorSet.set(vars),
  //   description: 'export_site_v_1_0',
  //   assetName: assetName,
  // });
  
  //to Google Drive
  
  Export.table.toDrive({
    collection: predictorSet,
    description: '2023-08-30_data_covariates_global_native',
    folder: 'GEE_training_data',
    fileFormat: 'csv' //try instead to export as a geojson
  });