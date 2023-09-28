
/****************************************************
 * Import saltmarsh extent map
 ****************************************************/
// saltmarsh extent
var saltmarsh_v2_6 = ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_6/saltmarsh_v2_6');

Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);


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


var clarkParams = {
    min: 0,
  max: 6,
  palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
  opacity: 0.5,
};

var clark = clark0.updateMask(saltmarsh_v2_6).toInt16();
//print(clark); 

Map.addLayer(clark0,clarkParams, "clark"); 
