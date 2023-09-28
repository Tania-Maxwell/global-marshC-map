//processing GlobColour dataset
// edited 12.09.2022 01.06.23

var covariateName = 'TSM'; // <<-- CHANGE FOR EACH EXPORT for filenaming


//data mask
var dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3')
    .focal_min({radius: 5000, units: 'meters'});  

// var site = ee.Geometry.Polygon(
// [[[0.6621003481445342,51.67979880621543],
// [0.9882569643554717,51.67979880621543], 
// [0.9882569643554717,51.78951129583516], 
// [0.6621003481445342,51.78951129583516], 
// [0.6621003481445342,51.67979880621543]]], null, false);

var world = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);

//var site = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);



// import TSM
var layer_toreduce = ee.Image("users/tlgm2/layer_imports/GlobColoursMeanTSM_2003_2011");

print(layer_toreduce);

var saltmarsh_v2_6 = ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_6/saltmarsh_v2_6');

Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);


/****************************************************
 * Code
 **************************************************/

// First, need to 'extend' the layer over the coastline 
//using kernel number so that it extends over 1km = 1000m
// here, pixel size in 4km sp 1000/927.67 = 1 pixels


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

// //  this is the layer to export
var TSM = layer_20km
    .unmask(layer30) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
//    .clip(site)
    .rename(covariateName);

/*********************************
 * Visualize.
// *********************************/

var TSM_global = ee.Image("users/tlgm2/covariate_global/TSM_v0_1");
//var TSM_global = ee.Image("users/tlgm2/covariate_global_tests/TSM_v0_1_30red_bathyextend");
var TSM_site = ee.Image("users/tlgm2/covariate_layers/TSM_v0_2");

// var TSM_site_mode = ee.Image("users/tlgm2/covariate_layers/TSM_v0_1mode");


var visualization = {
  min: 0,
  max: 30,
  palette: ['000000', '478FCD', '86C58E', 'AFC35E', '8F7131',
          'B78D4F', 'E2B8A6', 'FFFFFF']
};


//Map.setCenter(0.803206, 51.728008, 10);
//Map.setCenter(-8.657649, 52.657962, 9); // limerick, ireland
//Map.addLayer(TSM, visualization, "TSM (mean exported at 4km)");
Map.addLayer(TSM_global, visualization, "TSM global");

// Map.addLayer(TSM_site, visualization, "TSM (mean exported at 4km)");
// Map.addLayer(TSM_site3, visualization, "TSM 3red (mean exported at 4km)");

Map.addLayer(layer_toreduce, visualization, "TSM original");
//Map.addLayer(TSM.clip(philadelphia), visualization, "Total Suspended Matter reduced");

// /*********************************
// * Test map covers all of saltmarsh extent.
// // *********************************/

// //step 1: mask the saltmarsh extent to the TSM layer - this will crop the extent where there are no TSM values
// // you then set the masked values to 0, so that you can subtract them from the saltmarsh extent
// var marsh_tsm = saltmarsh_v2_6.updateMask(TSM_global).unmask(0);


// // step 2 : subtract the cropped extent from the real extent. When the extents don't match, the value will be 1
// // where extents do the value with be 0, so you selfMask() the layer which turns 0 in masked values
// // the result is an image of ONLY the difference
// var marsh_tsm_diff = saltmarsh_v2_6.subtract(marsh_tsm).selfMask();


// Map.addLayer(marsh_tsm_diff, {palette:'yellow'}, "TSM diff (mean exported at 4km)");


// // Step 3 : turn this image to a vector so that you can increase the graphing properties and easily see issues 
// var vectors = marsh_tsm_diff.reduceToVectors({
//   geometry: site,
//   crs: marsh_tsm.projection(),
//   scale: 4000,
//   geometryType: 'polygon',
//   eightConnected: false,
//   labelProperty: 'extent not covered by covariate',
//   maxPixels: 1e13
// });

// print(vectors);

// // Make a display image for the vectors, add it to the map.
// // var display = ee.Image(0).updateMask(0).paint(vectors, '000000', 3, );
// // Map.addLayer(display, {palette: 'red'}, 'vectors');

// var vectorsDraw = vectors.draw({color: '800080', strokeWidth: 10});
// Map.addLayer(vectorsDraw, {}, 'extent not covered by covariate');



/*********************************
 * Test map covers all of saltmarsh extent.
// *********************************/



// step 1: convert layer to 1s and 0s (1 = has a value, 0 = does not)
// for the present(1s): absolute value: in case of negative values, add 1 in case of 0 values
// unmask to 0 for values not present
var layer_for_boolean0 = TSM_global.abs().add(1).unmask(0);

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
  scale: 4000,
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
  sourceData: 'users/tlgm2/layer_imports/GlobColoursMeanTSM_2003_2011',
  sourceLink:'https://hermes.acri.fr/index.php?class=archive',
  covariateName: covariateName,
  generationScript: 'https://code.earthengine.google.com/56b8e4716442bad75b63ed6e3c295138',
  // codePath: 'https://code.earthengine.google.com/?scriptPath=users%2Fmurrnick%2Fglobal-intertidal-change%3Aclassifications%2FcovariateReduce_v3',
  project: 'global-marsh-carbon',
  source: 'Tania-Maxwell',
  title: 'GlobColour total suspended matter [Maxwell Global Tidal Marsh Carbon Covariate Layers v0.1]',
  description: 'Bathy extend 5km. Reduced 50 times with updateMask data mask at all layer 2km, layer 10km, layer 20km, layer 50km. Covariate layers used for testing in the tidal marsh carbon project',
  citation: 'R. Doerffer, H. Schiller, The MERIS Case 2 water algorithm, International Journal of Remote Sensing, Vol. 28, Iss. 3-4, 2007',
  doi: 'doi:10.1080/01431160600821127',
  assetName: assetName,
  dateGenerated: ee.Date(Date.now())
};
print (vars)


//Export final classified image to asset
Export.image.toAsset({
  image: TSM.set(vars), //include variables set above
  description: 'export_'
    .concat(covariateName)
    .concat('_world'),
    // .concat(startDate.slice(0,4))
    // .concat(endDate.slice(0,4)),
  assetId: assetName,
  scale: 4000,
  region: world, 
  maxPixels: 1e13 
});
