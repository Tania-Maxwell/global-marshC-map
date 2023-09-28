
exports.the_wash_ENG = the_wash_ENG; // to use in the combine_layers_global
exports.LA_delta_USA = LA_delta_USA; 
exports.west_port_AUS = west_port_AUS; 
exports.LA_low= LA_low; 
exports.arctic_test = arctic_test;
exports.south_africa = south_africa;
/****************************************************
 * Set up saltmarsh extent map
 ****************************************************/

var saltmarsh_v2_6 = ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_6/saltmarsh_v2_6');

Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);

// var saltmarsh_30m = ee.Image('users/tlgm2/covariate_global/saltmarsh_30m');

// Map.addLayer(saltmarsh_30m, {palette:'firebrick'}, '30m Global Tidal Marsh Extent', true);

// print(saltmarsh_30m);

// dataMask expansion 
var dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3')
    .focal_min({radius: 100, units: 'meters'});  // 100m

// Map.addLayer(dataMask, {palette:'yellow'}, 'Bathymask', true);


var world = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);

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
 * Import training data
 ****************************************************/


var dataset= ee.FeatureCollection('users/tlgm2/training_data/2023-08-30_data_clean_SOMconv_uniqueLatLong_forGEE')

var dataDraw = dataset.draw({color: '800080', pointRadius: 5, strokeWidth: 3});
Map.addLayer(dataDraw, {}, 'Training data');

/****************************************************
 * Calculate training data inside extent
 ****************************************************/


var distance = saltmarsh_v2_6.fastDistanceTransform().sqrt().multiply(ee.Image.pixelArea().sqrt()).rename("distance")

var pts = distance.reduceRegions(dataset, ee.Reducer.first().setOutputs(["distance"]))
  .map(function(f) {
    var distance = ee.Number(f.get('distance'))
    f = ee.Algorithms.If(distance, 
        f.buffer(distance.add(30), 1),
        f)
    f = ee.Feature(f)
    return f.set(saltmarsh_v2_6.reduceRegion({
      reducer: ee.Reducer.mean().unweighted(),
      geometry: f.geometry(),
      scale: 30,  // meters
      maxPixels: 1e13}))
  })
  
var pts_reduced = pts.filter(ee.Filter.gt('distance', 0)) 
print(pts_reduced.first())


// // importing pts_reduced which was exported from this section
// var dataset_reduced = ee.FeatureCollection('users/tlgm2/training_data/2023-07-17_data_outside_extent')
// .filter(ee.Filter.gt('distance', 10000)) 

// var dataDraw_reduced = dataset_reduced.draw({color: 'green', pointRadius: 1, strokeWidth: 1});
// Map.addLayer(dataDraw_reduced, {}, 'Training data outside Tom map');

var dataset_NAs = ee.FeatureCollection('users/tlgm2/training_data/2023-08-01_GEE_export_NAs')

var dataDraw_NAs = dataset_NAs.draw({color: 'orange'});
Map.addLayer(dataDraw_NAs, {}, 'Training data with NAs NDVI');


/****************************************************
 * Create global sample (random points through extent)
 ****************************************************/
// var seedID = 1

// var samples = saltmarsh_30m.stratifiedSample({
//                   numPoints: 5000,
//                   classBand: 'saltmarsh',
//                   region: world,
//                   geometries: true,
//                   projection: "EPSG:4326",
//                   scale :30,
//                   dropNulls:true,
//                   seed : seedID
//                 });

// var samples_export = ee.FeatureCollection('users/tlgm2/training_data/global_sample_5k')
// var dataDraw_samples = samples_export.draw({color: 'green'});
// //Map.addLayer(dataDraw_samples, {}, 'Global sample points');


/*********************************
 * Export global sample data
// *********************************/

// Export.table.toDrive({
//   collection: samples,
//   description: 'global_sample_5k',
//   folder: 'GEE_training_data',
//   fileFormat: 'csv'
// });

/*********************************
 * Export training data
// *********************************/


Export.table.toAsset({
  collection: pts_reduced,
  description: 'Training data outside of saltmarsh extent map',
  assetId: 'training_data/2023-07-17_data_outside_extent'
});


// Export.table.toDrive({
//   collection: pts_reduced,
//   description: '2023-07-17_data_outside_extent',
//   folder: 'GEE_training_data',
//   fileFormat: 'geojson' //try instead to export as a geojson
// });


/*********************************
 * Tom's map: Export to Asset at 30m
// *********************************/

// outputs
var assetName = 'covariate_global/'
  .concat('saltmarsh_1km')
print (assetName, 'assetName');

// image properties
var vars = {
  // startDate:startDate,
  // endDate:endDate,
  sourceData: 'WORLDCLIM/V1/BIO',
  sourceLink:'https://www.worldclim.org/data/bioclim.html',
  covariateName: 'saltmarsh_1km',
  generationScript: 'https://code.earthengine.google.com/0d6b0480b17b4567a1c619f9ec7dd318',
  // codePath: 'https://code.earthengine.google.com/?scriptPath=users%2Fmurrnick%2Fglobal-intertidal-change%3Aclassifications%2FcovariateReduce_v3',
  project: 'global-marsh-carbon',
  source: 'Tania-Maxwell',
  title: 'Saltmarsh extent at 1km [Maxwell Global Tidal Marsh Carbon Covariate Layers v0.1]',
  description: 'Saltmarsh extent used for predictions in the tidal marsh carbon project',
  citation: 'Worthington, T. A., M. Spalding, E. Landis, T. L. Maxwell, A. Navarro, L. S. Smart, and N. J. Murray. 2023. The distribution of global tidal marshes from earth observation data.',
  doi: 'doi:10.1101/2023.05.26.542433',
  assetName: assetName,
  dateGenerated: ee.Date(Date.now())
};
print (vars)


//Export final classified image to asset
Export.image.toAsset({
  image: saltmarsh_v2_6.set(vars), //include variables set above
  description: 'export_'
    .concat('saltmarsh_1km'),
    // .concat('_')
    // .concat(startDate.slice(0,4))
    // .concat(endDate.slice(0,4)),
  assetId: assetName,
  scale: 1000,
//  region: site, 
  maxPixels: 1e13,
  pyramidingPolicy: 'mode'
  
});


// //Export final image to drive
// Export.image.toDrive({
//   image: saltmarsh_30m,
//   description: 'export_NW_marsh_30m',
//   folder: 'GEE_extent_30m_NW',
//   scale: 30,
//   region: NW, 
//   maxPixels: 1e13 ,
//   fileFormat: 'GeoTiff'
// });

