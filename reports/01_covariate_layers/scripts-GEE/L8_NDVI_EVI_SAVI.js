/// testing landsat variable reduction 
// from Nicholas Murray, covariateReduce_v3 script

// updated: 22-11-25
// notes: added EVI and SAVI

/****************************************** 
 * Explanations
 * 
 * USGS:
 * Landsat Enhanced Vegetation Index (EVI) is similar to Normalized Difference Vegetation Index (NDVI) 
 * and can be used to quantify vegetation greenness. However, EVI corrects for some atmospheric conditions 
 * and canopy background noise and is more sensitive in areas with dense vegetation. 

 * Landsat Soil Adjusted Vegetation Index (SAVI) is used to correct Normalized Difference Vegetation Index (NDVI) 
 * for the influence of soil brightness in areas where vegetative cover is low. 
 ******************************************/


/****************************************** 
 * Global Variables
 ******************************************/
 
var simpleCoastLine =  ee.FeatureCollection('projects/UQ_intertidal/dataMasks/simpleNaturalEarthCoastline_v1').first().geometry();
// var site = ee.Geometry.Polygon(
//   [[[-14.773542314042771,49.80571809296125], 
// [3.3319264359572287,49.80571809296125],
// [3.3319264359572287,59.73119695514474],
// [-14.773542314042771,59.73119695514474],
// [-14.773542314042771,49.80571809296125]]], null, false ); // only UK


// NOTE: this ran for the last NDVI asset export, which is why it took so long 
// // section of UK
// var site = ee.Geometry.Polygon(
// [[[0.6621003481445342,51.67979880621543],
// [0.9882569643554717,51.67979880621543], 
// [0.9882569643554717,51.78951129583516], 
// [0.6621003481445342,51.78951129583516], 
// [0.6621003481445342,51.67979880621543]]], null, false);

// entire world
var world = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);


//// saltmarsh extent

var saltmarsh_v2_6 = ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_6/saltmarsh_v2_6');


//var dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3');


// dataMask expansion update 05.05.23
var dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3')
    .focal_min({radius: 100, units: 'meters'});  



// //expand the dataMask 
// var bufferSize = 5000 // in metres
// var basic_dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3');
// Map.addLayer (basic_dataMask, {palette:'black'}, 'topobathy')
// var dataMask = basic_dataMask.fastDistanceTransform(100)
//                               .sqrt()
//                               .multiply(ee.Image.pixelArea().sqrt())
//                               .lte(bufferSize) // threshold distance raster at some number
//                               .selfMask()
                              
// Map.addLayer (dataMask, {palette:'orange'}, 'grown', true, 0.7)

// Execution options.
//using full years from Landsat 8
var startDate = '2014-01-01';
var endDate = '2021-12-31';

// Bands to select during collection creation.
var bandSelect = ['green', 'swir1', 'swir2', 'nir', 'red', 'blue'];
var bands8 = ['SR_B3', 'SR_B6', 'SR_B7', 'SR_B5', 'SR_B4', 'SR_B2'];

/****************************************************
 * Set up mapping functions, reducers, etc.
 ****************************************************/
var mappingFunctions = { 
  
  applyPixelQAcloudMask: function (image) {
    // Mask out SHADOW, SNOW, and CLOUD classes. 
    var qa = image.select('QA_PIXEL');
    var mask = image.updateMask( // NOTE: bitmask is different now (cloud at beginning instead of end)
      qa.bitwiseAnd(1 << 3).eq(0)       // Cloud bit; 
      .and(qa.bitwiseAnd(1 << 4).eq(0))  // Cloud shadow bit
      .and(qa.bitwiseAnd(1 << 5).eq(0))); // Snow bit
    return mask;
  },
  
  applyCoastMask: function (image) {
    // apply the coastal data mask 
    // generation script: https://code.earthengine.google.com/730a5fb19a3cb9d35941ef8b16fa9a0f
    var im = image.updateMask(dataMask);
    return im;
  },
  
  applyNDVI: function(image) {
    // apply NDVI to an image
    var ndvi = image.normalizedDifference(['nir','red']);
    return ndvi.select([0], ['ndvi']);
  },
  
  applyEVI : function(image) {
    var evi = image.expression(
    '2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1))', {
      'NIR': image.select('nir'),
      'RED': image.select('red'),
      'BLUE': image.select('blue')
      });
    return evi.select([0], ['evi']);
  }, 

  applySAVI : function(image) {
    var savi = image.expression(
    '1.5 * ((NIR - RED) / (NIR + RED +0.5))', {
      'NIR': image.select('nir'),
      'RED': image.select('red')
      });
    return savi.select([0], ['savi']);
    }, 

};


// Reduce image collection to per band metrics
var reducer = ee.Reducer.stdDev().setOutputs(['stdev'])
    .combine(ee.Reducer.median().setOutputs(['med']), '', true);
    
    // // NOTE: decided not to include so many bands 
    // .combine(ee.Reducer.min(), '', true)
    // .combine(ee.Reducer.max(), '', true)
    // .combine(ee.Reducer.percentile([10, 25, 50, 75,90]), '', true)
    // .combine(ee.Reducer.intervalMean(0, 10).setOutputs(['0010']), '', true)
    // .combine(ee.Reducer.intervalMean(10, 25).setOutputs(['1025']), '', true)
    // .combine(ee.Reducer.intervalMean(25, 50).setOutputs(['2550']), '', true)
    // .combine(ee.Reducer.intervalMean(50, 75).setOutputs(['5075']), '', true)
    // .combine(ee.Reducer.intervalMean(75, 90).setOutputs(['7590']), '', true)
    // .combine(ee.Reducer.intervalMean(90, 100).setOutputs(['90100']), '', true)
    // .combine(ee.Reducer.intervalMean(10, 90).setOutputs(['1090']), '', true)
    // .combine(ee.Reducer.intervalMean(25, 75).setOutputs(['2575']), '', true);



// note: USGS Landsat 8 Surface Reflectance Tier 1 [deprecated]
// landsat data to use instead 


var L8collection = ee.ImageCollection("LANDSAT/LC08/C02/T1_L2")
      .filterDate(startDate, endDate) 
//      .filterBounds(site)
      .filter(ee.Filter.intersects(".geo", simpleCoastLine, null, null, 1000)) 
      .filterMetadata('WRS_ROW', 'less_than', 120)  // descending (daytime) landsat scenes only
      .map(mappingFunctions.applyPixelQAcloudMask)
      .map(mappingFunctions.applyCoastMask)
      .select(bands8, bandSelect);

//print(L8collection);


//note: now don't need Parallel Scale (used to be needed to tell EE about parallelising method)


/********************************************* 
 * Set up covariate layers to be exported.
 *********************************************/

//combining the covariate layers
var covariates = {
  ndvi: L8collection.map(mappingFunctions.applyNDVI)
      .reduce(reducer),
  savi: L8collection.map(mappingFunctions.applySAVI)
      .reduce(reducer),
  evi: L8collection.map(mappingFunctions.applyEVI)
      .reduce(reducer)
};

print(covariates)



/*********************************
 * test - export for training data
 *********************************/

// // 12-14 first attempt failed with data from 12-05, perhaps due to large size
// // trying dataset with unique latitude (n = 4130)
// var trainingSet = ee.FeatureCollection('users/tlgm2/training_data/2022-12-14_data_cleaned'); // path to training set

var ndvi = L8collection.map(mappingFunctions.applyNDVI)
      .reduce(reducer); 
      
var savi = L8collection.map(mappingFunctions.applySAVI)
      .reduce(reducer);
      
var evi = L8collection.map(mappingFunctions.applyEVI)
      .reduce(reducer);

var covariates_IC = ee.Image(ndvi)
.addBands(ee.Image(savi))
.addBands(ee.Image(evi));


// var bands = covariates_IC.bandNames();

// print(bands);

// print(covariates_IC);



// function sampleCovariates(feature) {
//     // sample covariates at each training point
//     var predictorData = covariates_IC.reduceRegion({
//     reducer: ee.Reducer.first(), 
//     geometry: feature.geometry(),
//     scale: 1}); 
//     return feature.set(predictorData);
// }

// var predictorSet = trainingSet.map(sampleCovariates); 


// // // export

// Export.table.toDrive({
//   collection: predictorSet,
//   description: 'export_data_landsat_v_1_2',
//   folder: 'earth_engine_exports/predictor_data/',
//   fileFormat: 'CSV'
// });


/*********************************
 * Visualize
 *********************************/



var ndvi_exported = ee.Image('users/tlgm2/covariate_global/L8_ndvi_20142021_v0_1') // 100m bathy buffer
//var ndvi_exported = ee.Image('users/tlgm2/covariate_global_tests/L8_ndvi_20142021_v0_1_arctic_1km') //2km bathy buffer
//.clip(arctic)
.select('ndvi_med');

// var ndvi_nobuffer = ee.Image('users/tlgm2/covariate_global_tests/L8_ndvi_20142021_v0_1_nobuffer') //no bathy buffer
// .clip(arctic)
// .select('ndvi_med');


//individually calculating - just for visualization

// var ndvi = L8collection.map(mappingFunctions.applyNDVI)
//       .reduce(reducer);

var savi = L8collection.map(mappingFunctions.applySAVI)
      .reduce(reducer);

// var evi = L8collection.map(mappingFunctions.applyEVI)
//       .reduce(reducer);

var visualization = {
  bands: ['red', 'green', 'blue'],
  min: 0,
  max: 0.5,
  gamma: [0.95, 1.1, 1]
};

//Map.addLayer(L8collection, {},'L8');

//Map.addLayer(covariates_IC, {},'to export');


//Map.addLayer(ndvi.select('ndvi_med'), {},'NDVI');
Map.addLayer(savi.select('savi_med').clip(arctic), {min: -1, max: 1, palette: ['a6611a', 'f5f5f5', '4dac26']}, 'SAVI');
//Map.addLayer(evi.select('evi_med').clip(site), {min: -1, max: 1, palette: ['a6611a', 'f5f5f5', '4dac26']}, 'EVI');
//Map.setCenter(0.803206, 51.728008, 11);

Map.addLayer(ndvi_exported, {} ,'NDVI 100m extended mask');
//Map.addLayer(ndvi_nobuffer, {} ,'NDVI no extemded mask');
Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);


/*********************************
 * Test map covers all of saltmarsh extent.
// *********************************/



// step 1: convert layer to 1s and 0s (1 = has a value, 0 = does not)
// for the present(1s): absolute value: in case of negative values, add 1 in case of 0 values
// unmask to 0 for values not present
var layer_for_boolean0 = ndvi_exported.abs().add(1).unmask(0);

// Step 1.5: layer turning all values greater than or equal to 1 to 1
var layer_for_boolean = layer_for_boolean0.gte(1);

// Step 2 : subtract the cropped extent from the real extent. When the extents don't match, the value will be 1
// where extents do the value with be 0, so you selfMask() the layer which turns 0 in masked values
// the result is an image of ONLY the difference
var marsh_layer_diff = saltmarsh_v2_6.subtract(layer_for_boolean).selfMask();

Map.addLayer(marsh_layer_diff, {palette:'yellow'}, "Saltmarsh without layer values");


//Step 3 : turn this image to a vector so that you can increase the graphing properties and easily see issues 
var vectors = marsh_layer_diff.reduceToVectors({
  geometry: world,
  crs: marsh_layer_diff.projection(),
  //scale: 30,
  geometryType: 'polygon',
  eightConnected: false,
  labelProperty: 'extent not covered by covariate',
  maxPixels: 1e13
});


var vectorsDraw = vectors.draw({color: '800080', strokeWidth: 20});
Map.addLayer(vectorsDraw, {}, 'extent not covered by covariate');

Export.table.toAsset({
  collection: vectors,
  description: 'covariate_global_tests/world_vector_nobuffer'
}); 


/*********************************
 * SINGLE COVARIATE: Export to Asset.
 *********************************/

var covariateName = 'evi'; // <<-- CHANGE FOR EACH EXPORT for filenaming ([ndvi, evi, savi])

// outputs
var assetName = 'L8_'
  .concat(covariateName)
  .concat('_')
  .concat(startDate.slice(0,4))
  .concat(endDate.slice(0,4))
  .concat('_v0_1');
print (assetName, 'assetName');

// image properties
var vars = {
  startDate:startDate,
  endDate:endDate,
  landsatCollection: 'LC08/C02/T1_L2',
  covariateName: covariateName,
  generationScript: 'https://code.earthengine.google.com/4c29c7518575caac0189adae5fe3c24e',
  // codePath: 'https://code.earthengine.google.com/?scriptPath=users%2Fmurrnick%2Fglobal-intertidal-change%3Aclassifications%2FcovariateReduce_v3',
  project: 'global-marsh-carbon',
  source: 'Tania-Maxwell',
  title: 'EVI with extended bathy mask 100m [Maxwell Global Tidal Marsh Carbon Covariate Layers v0.1]', // <<-- CHANGE FOR EACH EXPORT for filenaming ([ndvi, evi, savi])
  description: 'Covariate layers used for testing in the tidal marsh carbon project',
  citation: 'TBD',
  doi: 'TBD',
  assetName: assetName,
  dateGenerated: ee.Date(Date.now())
};
print (vars);

// For single covariate outputs:
var covariateToExport = covariates
    .evi // <<-- <<-- CHANGE FOR EACH EXPORT for filenaming ([ndvi, evi, savi])
    .set(vars)
//    .multiply(saltmarsh_v2_3)
    .float(); // generate smallest export possible
print (covariateToExport);


// Map.addLayer(covariateToExport)
// var nvis = {bands:['red', 'green', 'blue'], 'min': 0, 'max': 10000}
// Map.addLayer(L8collection.median(), nvis, 'ls8 2')
//Map.addLayer(collection.median(), {palette:['darkblue', 'lime'], min:-1, max:1}, 'test')


// //Export final classified image to asset
// Export.image.toAsset({
//   image: covariateToExport, 
  // description: 'export_'
  //   .concat(covariateName)
  //   .concat('_')
  //   .concat(startDate.slice(0,4))
  //   .concat(endDate.slice(0,4)),
//   assetId: assetName,
//   scale: 30,
//   region: world, //world
//   maxPixels: 10000000000000 // this is the max
// });

var NE = ee.Geometry.Polygon(
  [0, 60,
  90, 60,
  180, 60,
  180, 0,
  90,0,
  0, 0,
  0, 60], null, false);
 

var SE = ee.Geometry.Polygon(
  [0, -60,
  90, -60,
  180, -60,
  180, 0,
  90,0,
  0, 0,
  0, -60], null, false);
 

var NW = ee.Geometry.Polygon(
  [-180, 60,
  -90, 60,
  0, 60,
  0, 0,
  -90,0,
  -180, 0,
  -180, 60], null, false);

 
var SW = ee.Geometry.Polygon(
  [-180, 0,
  -90, 0,
  0, 0,
  0, -60,
  -90,-60,
  -180, -60,
  -180, 0], null, false);


Export.image.toCloudStorage({
  image: covariateToExport,  
  description: 'export_'
    .concat(covariateName)
    .concat('_')
    .concat(startDate.slice(0,4))
    .concat(endDate.slice(0,4))
    .concat('_NW'),
  bucket: 'carbon_covariates',
  fileNamePrefix: 'L8_evi_20142021_v0_1_NW',
  region: NW,
  scale: 30,
  maxPixels: 10000000000000,
  skipEmptyTiles: true,
});

