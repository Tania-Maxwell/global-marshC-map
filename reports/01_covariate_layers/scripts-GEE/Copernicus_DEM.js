//processing Copernicus elevation dataset
// NOTE: this does NOT need to be exported to an asset

var covariateName = 'Copernicus_DEM'; // <<-- CHANGE FOR EACH EXPORT for filenaming

// var site = ee.Geometry.Polygon(
// [[[0.6621003481445342,51.67979880621543],
// [0.9882569643554717,51.67979880621543], 
// [0.9882569643554717,51.78951129583516], 
// [0.6621003481445342,51.78951129583516], 
// [0.6621003481445342,51.67979880621543]]], null, false);

//entire world
var world = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);


// saltmarsh extent
var saltmarsh_v2_6 = ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_6/saltmarsh_v2_6');

Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);


// dataMask expansion 
var dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3')
    .focal_min({radius: 100, units: 'meters'});  // 100m

print(dataMask)

// import COPERNICUS DEM 
var elevation = ee.ImageCollection("COPERNICUS/DEM/GLO30")
 .select('DEM')
 .median();

var elevation_reproj = elevation.reproject({crs:'EPSG:4326', scale:30});

var slope = ee.Terrain.slope(elevation_reproj);


//add slope to elevation

var copDEM = ee.Image([elevation, slope])
  .rename('copernicus_elevation', 'copernicus_slope');

print(copDEM);


/*********************************
 * Visualize.
// *********************************/
var copDEM_arctic = ee.Image('users/tlgm2/covariate_global_tests/Copernicus_DEM_v0_1_arctic');


var elevationVis = {
  min: 0.0,
  max: 10,
  palette: ['0000ff','00ffff','ffff00','ff0000','ffffff'],
};

Map.addLayer(copDEM.select('copernicus_elevation'), elevationVis, "Elevation");
Map.addLayer(copDEM.select('copernicus_slope'), {min: 0, max: 10, opacity: 0.5}, "Slope");


//Map.setCenter(0.803206, 51.728008, 11);

/////compare to SRTM/////

// // import SRTM
// var srtm = ee.Image('USGS/SRTMGL1_003')
// .updateMask(dataMask)
// //.clip(site);



/*********************************
 * SINGLE COVARIATE: Export to Asset.
// *********************************/

// outputs
var assetName = 'covariate_global/'
  .concat(covariateName)
  // .concat('_')
  // .concat(startDate.slice(0,4))
  // .concat(endDate.slice(0,4))
  .concat('_v0_1');

// image properties
var vars = {
  sourceData: 'COPERNICUS/DEM/GLO30',
  sourceLink:'https://code.earthengine.google.com/d2e896fbd3d1ce75db9903916650d5b0',
  covariateName: covariateName,
  generationScript: 'https://code.earthengine.google.com/00bc956f902acab767e2798b2a92b25b',
  // codePath: 'https://code.earthengine.google.com/?scriptPath=users%2Fmurrnick%2Fglobal-intertidal-change%3Aclassifications%2FcovariateReduce_v3',
  project: 'global-marsh-carbon',
  source: 'Tania-Maxwell',
  title: 'Copernicus DEM [Maxwell Global Tidal Marsh Carbon Covariate Layers v0.1]',
  description: 'Bathy extend 100m. Covariate layers used for testing in the tidal marsh carbon project.',
  citation: 'License for Copernicus DEM',
  doi: '',
  assetName: assetName,
  dateGenerated: ee.Date(Date.now())
};
print (vars)


// //Export final classified image to asset
// Export.image.toAsset({
//   image: copDEM_export.set(vars), //include variables set above
//   description: 'export_'
//     .concat(covariateName)
//     .concat('_global'),
//     // .concat(startDate.slice(0,4))
//     // .concat(endDate.slice(0,4)),
//   assetId: assetName,
//   scale: 30, //original scale
//   region: world, 
//   maxPixels: 1e13 
// });


// Export.image.toCloudStorage({
//   image: copDEM_export.set(vars),
//   description: 'export_bucket_CopDEM_arctic',
//   bucket: 'carbon_covariates',
//   fileNamePrefix: 'CopernicusDEM_arctic',
//   region: arctic,
//   scale: 30,
//   maxPixels: 10000000000000,
//   skipEmptyTiles: true,
// });



  