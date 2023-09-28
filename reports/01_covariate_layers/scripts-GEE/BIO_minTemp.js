// Script to export minimum temperature of coldest month from WorldClim BIO variables
//01.09.22

/****************************************************
 * Change values below
 ****************************************************/

// // site = small area of uk
// var site = ee.Geometry.Polygon(
// [[[0.6621003481445342,51.67979880621543],
// [0.9882569643554717,51.67979880621543], 
// [0.9882569643554717,51.78951129583516], 
// [0.6621003481445342,51.78951129583516], 
// [0.6621003481445342,51.67979880621543]]], null, false);

//entire world
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


var bands = 'bio06'

//data mask
var dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3')
    .focal_min({radius: 50000, units: 'meters'}); 
    // increasing the mask size by buffering it
    // NOTE: 10km still not enough; doing 50km (coasts)



var covariateName = 'minTemp'; // <<-- CHANGE FOR EACH EXPORT for filenaming


/****************************************************
 * Code
 ****************************************************/

/// ADDING WORLDCLIM VARIABLES
// note: these are at a 0.1 scale, i.e. real values are divided by 10.
// easier for EE to store integers rather than decimals


var dataset = ee.Image("WORLDCLIM/V1/BIO");

var layer_toreduce = dataset.select(bands);

var base_scale = layer_toreduce.projection().nominalScale().format('%.2f');
print('image raster scale:', base_scale);


// First, need to 'extend' the layer over the coastline 
//using kernel number so that it extends over 1km = 1000m
// here, pixel size in 927.67m sp 1000/927.67 = 1 pixels


/*********************************
 * Step 1: grow over 2km (2 times reduced by 1 pixel)
 *  Unmask the original map to the reduced by 2 pixels
// *********************************/

var layer1 = layer_toreduce
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
//need to extend a second time, also only by 1 pixel to cover the whole area
var layer2 = layer1
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

//  Unmask the original map to the reduced by 2 pixels
var layer_2km = layer_toreduce
    .unmask(layer2) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
    .int() // don't need decimals really because at 0.1 scale
    .rename(covariateName);


/*********************************
 * Step 2: grow the 2km extended map by another 10 km (reduced 10 times total)
 * Then, unmask the 2km by the 10km grow
// *********************************/

var layer3 = layer_2km
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer4 = layer3
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer5 = layer4
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer6 = layer5
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer7 = layer6
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer8 = layer7
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


var layer9 = layer8
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer10 = layer9
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


//  Unmask the map (already unmasked by 2km extend) to the reduced by 10 pixels
var layer_10km = layer_2km
    .unmask(layer10) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
    .int() // don't need decimals really because at 0.1 scale
    .rename(covariateName);

/*********************************
 * Step 3: grow the 10km extended map by another 10 km (reduced 10 more times)
 * Then, unmask the 10km map by the 20km grow
// *********************************/

var layer11 = layer_10km
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer12 = layer11
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer13 = layer12
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer14 = layer13
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer15 = layer14
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer16 = layer15
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer17 = layer16
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer18 = layer17
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer19 = layer18
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer20 = layer19
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


//  Unmask the map (already unmasked by 2km extend) to the reduced by 10 pixels
var layer_20km = layer_10km
    .unmask(layer20) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
    .int() // don't need decimals really because at 0.1 scale
    .rename(covariateName);



/*********************************
 * Step 4: grow the 20km extended map by another 30 km (reduced 30 more times)
 * Then, unmask the 20km map by the 30km grow
// *********************************/


var layer21 = layer_20km
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer22 = layer21
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer23 = layer22
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer24 = layer23
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer25 = layer24
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer26 = layer25
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer27 = layer26
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer28 = layer27
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer29 = layer28
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer30 = layer29
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer31 = layer30
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer32 = layer31
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer33 = layer32
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer34 = layer33
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer35 = layer34
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer36 = layer35
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer37 = layer36
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer38 = layer37
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer39 = layer38
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer40 = layer39
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


var layer41 = layer40
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer42 = layer41
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer43 = layer42
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer44 = layer43
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer45 = layer44
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer46 = layer45
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer47 = layer46
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer48 = layer47
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer49 = layer48
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer50 = layer49
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


/*********************************
 * Layer to export.
// *********************************/

//  this is the layer to export
var minTemp = layer_20km
    .unmask(layer50) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
//    .clip(site)
    .int() // don't need decimals really because at 0.1 scale
    .rename(covariateName);



/*********************************
 * Visualize.
// *********************************/


var minTemp_exported = ee.Image('users/tlgm2/covariate_global/minTemp_v0_1');

var climParams = {
    min: -10,
  max: 30,
  palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
  opacity: 0.5,
};
  

//Map.setCenter(0.803206, 51.728008, 11);
//Map.addLayer(layer_toreduce.clip(site), climParams, "Original minimum temp of coldest month (0.1 scale)");
Map.addLayer(minTemp_exported, climParams, "Exported minimum temp of coldest month (0.1 scale)");


/*********************************
 * Test map covers all of saltmarsh extent.
// *********************************/

// step 1: convert layer to 1s and 0s (1 = has a value, 0 = does not)
// for the present(1s): absolute value: in case of negative values, add 1 in case of 0 values
// unmask to 0 for values not present
var layer_for_boolean0 = minTemp_exported.abs().add(1).unmask(0);

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
 *********************************/

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
  generationScript: 'https://code.earthengine.google.com/a89ff05f48f65ab4c3afcea0f19b69d8',
  // codePath: 'https://code.earthengine.google.com/?scriptPath=users%2Fmurrnick%2Fglobal-intertidal-change%3Aclassifications%2FcovariateReduce_v3',
  project: 'global-marsh-carbon',
  source: 'Tania-Maxwell',
  title: 'minTemp extended to 50km [Maxwell Global Tidal Marsh Carbon Covariate Layers v0.1]',
  description: 'Covariate layers used for testing in the tidal marsh carbon project',
  citation: 'Hijmans, R.J., S.E. Cameron, J.L. Parra, P.G. Jones and A. Jarvis 2005. Very High Resolution Interpolated Climate Surfaces for Global Land Areas. International Journal of Climatology 25: 1965-1978.',
  doi: 'doi:10.1002/joc.1276',
  assetName: assetName,
  dateGenerated: ee.Date(Date.now())
};
print (vars)




//Export final classified image to asset
Export.image.toAsset({
  image: minTemp.set(vars), //include variables set above
  description: 'export_'
    .concat(covariateName),
    // .concat('_')
    // .concat(startDate.slice(0,4))
    // .concat(endDate.slice(0,4)),
  assetId: assetName,
  scale: base_scale.getInfo(),
  region: site, 
  maxPixels: 1e13 
});


