// script to multiply layers my saltmarsh extent - reduce size
// then, combine as bands in a single image to export 
// goal: export images in smallest size possible 

exports.europe = europe; // to use in the training data script

var location_import = require('users/tlgm2/TidalmarshC:trainingdata_marshextent');
var the_wash_ENG = location_import.the_wash_ENG;
var west_port_AUS = location_import.west_port_AUS;
var LA_delta_USA = location_import.LA_delta_USA;
var LA_low = location_import.LA_low;
var arctic_test = location_import.arctic_test;
var south_africa = location_import.south_africa;

//site = small area of uk
var site = ee.Geometry.Polygon(
[[[0.6621003481445342,51.67979880621543],
[0.9882569643554717,51.67979880621543], 
[0.9882569643554717,51.78951129583516], 
[0.6621003481445342,51.78951129583516], 
[0.6621003481445342,51.67979880621543]]], null, false);


var uk = ee.Geometry.Polygon(
  [[[-14.773542314042771,49.80571809296125], 
[3.3319264359572287,49.80571809296125],
[3.3319264359572287,59.73119695514474],
[-14.773542314042771,59.73119695514474],
[-14.773542314042771,49.80571809296125]]], null, false ); // only UK


var world = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);

var covariateName = 'covariateGlobal';

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


/****************************************************
 * Import saltmarsh extent map
 ****************************************************/
// saltmarsh extent
// var saltmarsh_v2_6 = ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_6/saltmarsh_v2_6');

//exported at 30m using the trainingdata_marshextent script
var saltmarsh_v2_6 = ee.Image('users/tlgm2/covariate_global/saltmarsh_30m');

Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);


/****************************************************
 * Import image bands
 ****************************************************/
 
var startDate = '2014-01-01'; // reference period for landsat sampling
var endDate = '2021-12-31';// reference period for landsat sampling
var covariatePath = 'users/tlgm2/covariate_global/'; // path to covariate folder
var yearString = startDate.slice(0,4)
  .concat(endDate.slice(0,4));
var version = 'v0_1'
var landsatCollection = 'L8'


//create a function to load the covariate layers according to their covariateName
// this comes from the properiues which we created when exporting to an asset
var covariateLoader = function(covariateName){
  // load covariates
  var assetPath = covariatePath
    .concat(covariateName)
    .concat('_')
    .concat(version);
  var im_raw = ee.Image(assetPath);
  var im = im_raw.resample('bilinear').reproject({crs:'EPSG:4326', scale:30});
  return im;
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
    .concat('v0_1'); // these haven't been rerun
  var im = ee.Image(assetPath);
//  var im_extent = im.updateMask(saltmarsh_v2_6);
  return im;
};

// // for integers
// //CHANGE HERE - need to add more layer as it goes
// var covariateComposite0 = covariateLoader('maxTemp')
//         .addBands(landsatLoader('ndvi').multiply(100).int16())
//         .addBands (covariateLoader('Human_modification').multiply(100).int16())
//         .addBands (covariateLoader('M2Tide').multiply(10).int16())
// // NOTE: PETdry and PETwarm issue with cooordinatereference
//         .addBands (covariateLoader('PETdry').reproject({crs:'EPSG:4326', scale:927.66}).int16())    
//         .addBands (covariateLoader('PETwarm').reproject({crs:'EPSG:4326', scale:927.66}).int16())
//         .addBands (covariateLoader('TSM').multiply(10).int16())
//         // .addBands (covariateLoader('ECU'))
//         .addBands (covariateLoader('minTemp').int16())
//         .addBands (covariateLoader('minPrecip').int16())
//         .addBands (covariateLoader('popDens').int16());


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
        .addBands (covariateLoader('maxPrecip'))
        // .addBands (covariateLoader('popDens'))
        .updateMask(saltmarsh_v2_6); // adding at the end to do AFTER the resample and reprojection
        // .addBands (covariateLoader('waterOcc'));

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


var clark = clark0.updateMask(saltmarsh_v2_6).toInt16();
//print(clark); 

//Map.addLayer(clark0,{}, "clark"); 


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
  .reproject({crs:'EPSG:4326', scale:30})
  .updateMask(saltmarsh_v2_6); /// need to multiply by saltmarsh area to only keep values for extent


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
  .reproject({crs:'EPSG:4326', scale:30})
  .updateMask(saltmarsh_v2_6); /// need to multiply by saltmarsh area to only keep values for extent 


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
  .reproject({crs:'EPSG:4326', scale:30})
  .updateMask(saltmarsh_v2_6); /// need to multiply by saltmarsh area to only keep values for extent 



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
  .reproject({crs:'EPSG:4326', scale:30})
  .updateMask(saltmarsh_v2_6); /// need to multiply by saltmarsh area to only keep values for extent 



/****************************************************
 * Import EVI and SAVI (saved to Cloud Bucket)
 ****************************************************/

var evi_import = require('users/tlgm2/TidalmarshC:covariate_layers/Mosaic_EVI');
var evi_raw = evi_import.EVI.median();

var evi = evi_raw
//.multiply(100).int16()
.updateMask(saltmarsh_v2_6); 


var savi_import = require('users/tlgm2/TidalmarshC:covariate_layers/Mosaic_SAVI');
var savi_raw = savi_import.SAVI.median();
var savi = savi_raw
//.multiply(100).int16()
.updateMask(saltmarsh_v2_6); 

/****************************************************
 * Load all together
 ****************************************************/


var covariateComposite1 = covariateComposite0
  .addBands(copDEM)
  // .addBands(meritDEM)
  // .addBands(coastalDEM)
  // .addBands(SRTM)
  // .addBands(evi)
  // .addBands(savi)
  .addBands(clark);

//var covariateComposite = covariateComposite1.toInt16();
var covariateComposite = covariateComposite1
  .toFloat();

print(covariateComposite);

/****************************************************
 * Visualize exported bands
 ****************************************************/

 Map.addLayer(covariateComposite.clip(uk),{}, "Covariate layers"); 

// var visualization = {
//   min: 0,
//   max: 30,
//   palette: ['000000', '478FCD', '86C58E', 'AFC35E', '8F7131',
//           'B78D4F', 'E2B8A6', 'FFFFFF']
// };


// Map.addLayer(covariateComposite.clip(uk).select('TSM'),visualization, "TSM"); 




// var exported_site_ind = ee.Image('users/tlgm2/covariate_global/site_30m_float_resample_ind'); 

// Map.addLayer(exported_site_ind,{}, "Resampled individually covariate layers"); 

// var exported_site_ind_repr = ee.Image('users/tlgm2/covariate_global/site_30m_float_resample_ind_repr'); 

// Map.addLayer(exported_site_ind_repr.select('ndvi_med'),{}, "Resampled and reprojected covariate layers"); 

// var exported_site_all_repr = ee.Image('users/tlgm2/covariate_global/site_30m_float_resample_all_repr'); 

// Map.addLayer(exported_site_all_repr.select('ndvi_med'),{}, "Resampled and all reprojected covariate layers"); 



// // //////////  add minTemp Layer ////////// 
// var climParams = {
//     min: -10,
//   max: 30,
//   palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
//   opacity: 0.5,
// };
 
// Map.addLayer(covariateComposite.select('minTemp'), climParams, "Minimum temp of coldest month (0.1 scale)");


// /////// elevation //////

// var elevationVis = {
//   min: 10,
//   max: 100,
//   palette: ['0000ff','00ffff','ffff00','ff0000','ffffff'],
// };

// Map.addLayer(covariateComposite.select('copernicus_elevation'), elevationVis, "Elevation");
// Map.addLayer(covariateComposite.select('copernicus_slope'), {min: 0, max: 10, opacity: 0.5}, "Slope");

// ///// human modification /////


// var Humvisualization = {
// //  bands: ['gHM_2016'],
//   min: 10,
//   max: 100,
//   palette: ['0c0c0c', '071aff', 'ff0000', 'ffbd03', 'fbff05', 'fffdfd']
// };

// Map.addLayer(covariateComposite.select('Human_modification'), Humvisualization, 'Original');

/*********************************
 * ALL covariates: Export to Asset.
// *********************************/


// // outputs
// var assetName = 'covariate_global_tests/'
//   .concat('site_30m_float_resample_all_repr')
// print (assetName, 'assetName');

// // image properties
// var vars = {
//   // startDate:startDate,
//   // endDate:endDate,
//   sourceData: 'see individual assets',
//   covariateName: 'site_30m_float_resample_all_repr',
//   generationScript: 'https://code.earthengine.google.com/1abedb021b21b157a01660990bc5a101',
//   // codePath: 'https://code.earthengine.google.com/?scriptPath=users%2Fmurrnick%2Fglobal-intertidal-change%3Aclassifications%2FcovariateReduce_v3',
//   project: 'global-marsh-carbon',
//   source: 'Tania-Maxwell',
//   title: 'Covariate layers at 30m with .float and .resample and .reproj individually [Maxwell Global Tidal Marsh Carbon Covariate Layers v0.1]',
//   description: 'Site only for tests. Now multiply tom extent is at the end of all scripts (mask after resample)',
//   assetName: assetName,
//   dateGenerated: ee.Date(Date.now())
// };
// print (vars)


// //Export final classified image to asset
// Export.image.toAsset({
//   image: covariateComposite.set(vars), //include variables set above
//   description: 'export_'
//     .concat('site_30m_float_resample_all_repr'),
//   assetId: assetName,
//   scale: 30,
//   region: site, 
//   maxPixels: 1e13
// });


//Export final image to drive
Export.image.toDrive({
  image: covariateComposite,
  description: 'export_NW_30m',
  folder: 'GEE_predictor_NW_30m',
  scale: 30,
  region: NW, 
  maxPixels: 1e13 ,
  fileFormat: 'GeoTiff'
});


