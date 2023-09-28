// Script to export maximum temperature of warmest month from WorldClim BIO variables
//02.09.22

/****************************************************
 * Change values below
 ****************************************************/

// site = small area of uk
// var site = ee.Geometry.Polygon(
// [[[0.6621003481445342,51.67979880621543],
// [0.9882569643554717,51.67979880621543], 
// [0.9882569643554717,51.78951129583516], 
// [0.6621003481445342,51.78951129583516], 
// [0.6621003481445342,51.67979880621543]]], null, false);


// var site = ee.Geometry.Polygon(
//   [[[-14.773542314042771,49.80571809296125], 
// [3.3319264359572287,49.80571809296125],
// [3.3319264359572287,59.73119695514474],
// [-14.773542314042771,59.73119695514474],
// [-14.773542314042771,49.80571809296125]]], null, false ); // only UK

//quarter of the world
var site = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);


///saltmarsh extent
// var saltmarsh_v2_3 = ee.ImageCollection([
//                         ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_3/saltmarsh_v2_NE1'),
//                         ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_3/saltmarsh_v2_NE2'),
//                         ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_3/saltmarsh_v2_NW1'),
//                         ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_3/saltmarsh_v2_NW2'),
//                         ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_3/saltmarsh_v2_SE1'),
//                         ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_3/saltmarsh_v2_SE2'),
//                         ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_3/saltmarsh_v2_SW1'),
//                         ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_3/saltmarsh_v2_SW2')]).median().int();


// Map.addLayer(saltmarsh_v2_3, {palette:'hotpink'}, 'saltmarsh_v2 50% Wetlands - GMW mask - 10 ha', true);

var saltmarsh_v2_6 = ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_6/saltmarsh_v2_6');

Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);


var bands = 'bio05'

//data mask
var dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3')
    .focal_min({radius: 50000, units: 'meters'}); 
    // increasing the mask size by buffering it
    // NOTE: 10km still not enough; doing 50km (coasts)


var covariateName = 'maxTemp'; // <<-- CHANGE FOR EACH EXPORT for filenaming


/****************************************************
 * Code
 ****************************************************/

/// ADDING WORLDCLIM VARIABLES
// note: these are at a 0.1 scale, i.e. real values are divided by 10.
// easier for EE to store integers rather than decimals

var dataset = ee.Image("WORLDCLIM/V1/BIO");

var maxTemp_toreduce = dataset.select(bands);

var base_scale = maxTemp_toreduce.projection().nominalScale().format('%.2f');
print('image raster scale:', base_scale);

// First, need to 'extend' the layer over the coastline 
//using kernel number so that it extends over 1km = 1000m
// here, pixel size in 927.67m sp 1000/927.67 = 1 pixels

/*********************************
 * Step 1: grow over 2km (2 times reduced by 1 pixel)
 *  Unmask the original map to the reduced by 2 pixels
// *********************************/

var maxTempreduced1 = maxTemp_toreduce
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
//need to extend a second time, also only by 1 pixel to cover the whole area
var maxTempreduced2 = maxTempreduced1
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

//  Unmask the original map to the reduced by 2 pixels
var maxTemp_2km = maxTemp_toreduce
    .unmask(maxTempreduced2) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
    .int() // don't need decimals really because at 0.1 scale
    .rename(covariateName);


/*********************************
 * Step 2: grow the 2km extended map by another 10 km (reduced 10 times total)
 * Then, unmask the 2km by the 10km grow
// *********************************/

var maxTempreduced3 = maxTemp_2km
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var maxTempreduced4 = maxTempreduced3
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced5 = maxTempreduced4
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced6 = maxTempreduced5
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced7 = maxTempreduced6
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced8 = maxTempreduced7
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


var maxTempreduced9 = maxTempreduced8
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced10 = maxTempreduced9
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


//  Unmask the map (already unmasked by 2km extend) to the reduced by 10 pixels
var maxTemp_10km = maxTemp_2km
    .unmask(maxTempreduced10) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
    .int() // don't need decimals really because at 0.1 scale
    .rename(covariateName);

/*********************************
 * Step 3: grow the 10km extended map by another 10 km (reduced 10 more times)
 * Then, unmask the 10km map by the 20km grow
// *********************************/

var maxTempreduced11 = maxTemp_10km
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced12 = maxTempreduced11
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced13 = maxTempreduced12
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced14 = maxTempreduced13
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced15 = maxTempreduced14
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced16 = maxTempreduced15
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced17 = maxTempreduced16
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced18 = maxTempreduced17
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced19 = maxTempreduced18
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced20 = maxTempreduced19
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

//  Unmask the map (already unmasked by 2km extend) to the reduced by 10 pixels
var maxTemp_20km = maxTemp_10km
    .unmask(maxTempreduced20) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
    .int() // don't need decimals really because at 0.1 scale
    .rename(covariateName);



/*********************************
 * Step 4: grow the 20km extended map by another 30 km (reduced 30 more times)
 * Then, unmask the 20km map by the 30km grow
// *********************************/


var maxTempreduced21 = maxTemp_20km
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced22 = maxTempreduced21
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced23 = maxTempreduced22
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced24 = maxTempreduced23
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced25 = maxTempreduced24
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced26 = maxTempreduced25
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced27 = maxTempreduced26
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced28 = maxTempreduced27
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced29 = maxTempreduced28
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced30 = maxTempreduced29
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced31 = maxTempreduced30
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced32 = maxTempreduced31
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced33 = maxTempreduced32
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced34 = maxTempreduced33
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced35 = maxTempreduced34
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced36 = maxTempreduced35
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced37 = maxTempreduced36
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced38 = maxTempreduced37
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced39 = maxTempreduced38
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced40 = maxTempreduced39
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced41 = maxTempreduced40
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced42 = maxTempreduced41
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced43 = maxTempreduced42
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced44 = maxTempreduced43
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced45 = maxTempreduced44
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced46 = maxTempreduced45
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced47 = maxTempreduced46
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var maxTempreduced48 = maxTempreduced47
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced49 = maxTempreduced48
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var maxTempreduced50 = maxTempreduced49
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });



/*********************************
 * Layer to export.
// *********************************/

//  this is the layer to export
var maxTemp = maxTemp_20km
    .unmask(maxTempreduced50) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
//    .clip(site)
    .int() // don't need decimals really because at 0.1 scale
    .rename(covariateName);


/*********************************
 * Visualize.
// *********************************/


var maxTemp_exported = ee.Image('users/tlgm2/covariate_global/maxTemp_v0_1');

var climParams = {
    min: 200,
  max: 235,
  palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
  opacity: 0.5,
};
  

//Map.setCenter(0.803206, 51.728008, 11);
Map.addLayer(maxTemp_toreduce, climParams, "Original maximum temp of warmest month (0.1 scale)");
//Map.addLayer(maxTemp, climParams, "Reduced maximum temp of warmest month (0.1 scale)");
Map.addLayer(maxTemp_exported, climParams, "Exported maximum temp of warmest month (0.1 scale)");



/*********************************
 * Test map covers all of saltmarsh extent.
// *********************************/

// step 1: convert layer to 1s and 0s (1 = has a value, 0 = does not)
// for the present(1s): absolute value: in case of negative values, add 1 in case of 0 values
// unmask to 0 for values not present
var layer_for_boolean0 = maxTemp_exported.abs().add(1).unmask(0);

//test
//var layer_for_boolean0 = maxTemp_toreduce.abs().add(1).unmask(0);


// Step 1.5: layer turning all values greater than or equal to 1 to 1
var layer_for_boolean = layer_for_boolean0.gte(1);

// Step 2 : subtract the cropped extent from the real extent. When the extents don't match, the value will be 1
// where extents do the value with be 0, so you selfMask() the layer which turns 0 in masked values
// the result is an image of ONLY the difference
var marsh_layer_diff = saltmarsh_v2_6.subtract(layer_for_boolean).selfMask();

Map.addLayer(marsh_layer_diff, {palette:'yellow'}, "Saltmarsh without layer values");


//Step 3 : turn this image to a vector so that you can increase the graphing properties and easily see issues 
var vectors = marsh_layer_diff.reduceToVectors({
  geometry: site,
  crs: marsh_layer_diff.projection(),
  scale: 927.66,
  geometryType: 'polygon',
  eightConnected: false,
  labelProperty: 'extent not covered by covariate',
  maxPixels: 1e13
});


var vectorsDraw = vectors.draw({color: '800080', strokeWidth: 20});
Map.addLayer(vectorsDraw, {}, 'extent not covered by covariate');



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
print (assetName, 'assetName');

// image properties
var vars = {
  // startDate:startDate,
  // endDate:endDate,
  sourceData: 'WORLDCLIM/V1/BIO',
  sourceLink:'https://www.worldclim.org/data/bioclim.html',
  covariateName: covariateName,
  generationScript: 'https://code.earthengine.google.com/6257d2a7e581c0557add04b9b0270490',
  // codePath: 'https://code.earthengine.google.com/?scriptPath=users%2Fmurrnick%2Fglobal-intertidal-change%3Aclassifications%2FcovariateReduce_v3',
  project: 'global-marsh-carbon',
  source: 'Tania-Maxwell',
  title: 'maxTemp world extended to 50km [Maxwell Global Tidal Marsh Carbon Covariate Layers v0.1]',
  description: 'Covariate layers used for testing in the tidal marsh carbon project',
  citation: 'Hijmans, R.J., S.E. Cameron, J.L. Parra, P.G. Jones and A. Jarvis 2005. Very High Resolution Interpolated Climate Surfaces for Global Land Areas. International Journal of Climatology 25: 1965-1978.',
  doi: 'doi:10.1002/joc.1276',
  assetName: assetName,
  dateGenerated: ee.Date(Date.now())
};
print (vars)


//Export final classified image to asset
Export.image.toAsset({
  image: maxTemp.set(vars), //include variables set above
  description: 'export_'
    .concat(covariateName),
    // .concat('_')
    // .concat(startDate.slice(0,4))
    // .concat(endDate.slice(0,4)),
  assetId: assetName,
  scale: base_scale.getInfo(),
//  region: site, 
  maxPixels: 1e13 
});


