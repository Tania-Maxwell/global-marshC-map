// Script to export FES2014 M2 tidal amplitude layer
//13.09.22
// edit 01.06.23

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

// site = all of UK
var site = ee.Geometry.Polygon(
    [[[-14.773542314042771,49.80571809296125], 
  [3.3319264359572287,49.80571809296125],
  [3.3319264359572287,59.73119695514474],
  [-14.773542314042771,59.73119695514474],
  [-14.773542314042771,49.80571809296125]]], null, false ); // only UK
  
  //entire world
  var world = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);
  
  
  //data mask
  var dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3')
      .focal_min({radius: 5000, units: 'meters'}); //5km
  
  
  var covariateName = 'M2Tide'; // <<-- CHANGE FOR EACH EXPORT for filenaming
  
  var M2Tide_UK_v0_1 = ee.Image('users/tlgm2/covariate_layers/M2Tide_UK_v0_1')
  
  // entire world
  //var world = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);
  
  
  //// saltmarsh extent
  
  var saltmarsh_v2_6 = ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_6/saltmarsh_v2_6');
  
  Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);
  
  
  /****************************************************
   * Code
   ****************************************************/
  
  var layer_toreduce = ee.Image('users/tomworthington81/M2_Tides')
  
  
  var base_scale = layer_toreduce.projection().nominalScale();
  print('M2Tideoriginal raster scale:', base_scale);
  
  /*********************************
   * Step 1: grow over 2km (2 times reduced by 1 pixel)
   *  Unmask the original map to the reduced by 2 pixels
   * note: this is actually grow over 8km because 1 pixel is 4km
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
  //    .int() 
      .rename(covariateName);
  
  
  /*********************************
   * Step 2: grow the 2km extended map by another 10 km (reduced 10 times total)
   * Then, unmask the 2km by the 10km grow
   * 
   * note: this is actually grow over 4km x 8 times reduced = 24km
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
      // .int() 
      .rename(covariateName);
  
  /*********************************
   * Step 3: grow the 10km extended map by another 10 km (reduced 10 more times)
   * Then, unmask the 10km map by the 20km grow
   * 
   *  
   * note: this is actually grow over 4km x 10 times reduced = 40km
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
      // .int() 
      .rename(covariateName);
  
  
  
  /*********************************
   * Step 4: grow the 20km extended map by another 30 km (reduced 30 more times)
   * Then, unmask the 20km map by the 30km grow
   * 
   *  * note: this is actually grow over 4km x 30 times reduced = 120km
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
  
  
  //// need to extend another 150km to reach edge of Montreal
  // trying with more pixels
  var layer_50km = layer_20km
      .unmask(layer50) //unmask values using the values recalculated above
      .updateMask(dataMask) //masking with the topyBathyEcoMask
      // .int() 
      .rename(covariateName);
  
  
  var layer60 = layer_50km
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
    
  var layer70 = layer60
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
  
  var layer80 = layer70
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
    
  var layer90 = layer80
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
  
  var layer100 = layer90
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
    
  var layer110 = layer100
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
  
  var layer120 = layer110
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
    
  var layer130 = layer120
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
  
  var layer140 = layer130
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
    
  var layer150 = layer140
      .reduceNeighborhood({
        reducer: ee.Reducer.mean(), // mean of values around 
        kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
        skipMasked: false //we want to include the masked values, this is where we want to predict
    });
  
  
  
  /*********************************
   * Layer to export.
  // *********************************/
  
  //  this is the layer to export
  var M2Tide = layer_50km
      .unmask(layer150) //unmask values using the values recalculated above
      .updateMask(dataMask) //masking with the topyBathyEcoMask
  //    .clip(site)
  //    .int() // don't need that much detail
      .rename(covariateName);
  
  
  
  /// note: because we use the bathy mask at the different steps
  // layer is extended maximum to the edge of the bathy mask
  
  
  /*********************************
   * New method.
  // *********************************/
  
  // // Define a kernel. this a i cell square
  // var kernel = ee.Kernel.square({radius: 1});
  
  // // Perform a dilation using the cell medians, display.
  // var opened1 = layer_toreduce.focal_median({kernel: kernel, iterations: 1});
  // //Map.addLayer(opened1, {}, 'opened1');
  // var combined1 = ee.ImageCollection.fromImages([M2Tideoriginal, opened1]).reduce(ee.Reducer.firstNonNull());
  
  
  
  /*********************************
   * Visualize.
  // *********************************/
  
  var M2Tide_exported = ee.Image('users/tlgm2/covariate_layers/M2Tide_v0_2');
  // keep the 1 pixel!!
  var M2Tide_world = ee.Image('users/tlgm2/covariate_global/M2Tide_v0_1');
  var M2Tide_montreal = ee.Image('users/tlgm2/covariate_global_tests/M2Tide_v0_1_montreal');
  
  
  
  var visualization = {
    min: 0,
    max:300,
    palette: ['0c0c0c', '071aff', 'ff0000', 'ffbd03', 'fbff05', 'fffdfd']
  };
  
  
  Map.addLayer(M2Tide_world, visualization, 'World 1 px 50 times Exported M2 Tidal almplitude'); 
  Map.addLayer(layer_toreduce, visualization, 'Original M2 Tidal almplitude'); 
  Map.addLayer(M2Tide_montreal, visualization, 'Montreal M2 Tidal almplitude'); 
  
  //Map.addLayer(combined1, visualization, 'combined1 from Tom script');
  
  //Map.addLayer(M2Tide.clip(site), visualization, 'reduced now');
  
  
  /*********************************
   * Test map covers all of saltmarsh extent.
  // *********************************/
  
  
  
  // step 1: convert layer to 1s and 0s (1 = has a value, 0 = does not)
  // for the present(1s): absolute value: in case of negative values, add 1 in case of 0 values
  // unmask to 0 for values not present
  var layer_for_boolean0 = M2Tide_world.abs().add(1).unmask(0);
  
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
  
  // Export.table.toAsset({
  //   collection: vectors,
  //   description: 'covariate_global_tests/world_vector_nobuffer_M2'
  // }); 
  
  
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
    sourceData: 'FES2014 M2 Tidal amplitude',
    sourceLink:'https://www.aviso.altimetry.fr/en/data/products/auxiliary-products/global-tide-fes.html',
    covariateName: covariateName,
    generationScript: 'https://code.earthengine.google.com/6c14d51a9f8874507048624bd3d661e7',
    // codePath: 'https://code.earthengine.google.com/?scriptPath=users%2Fmurrnick%2Fglobal-intertidal-change%3Aclassifications%2FcovariateReduce_v3',
    project: 'global-marsh-carbon',
    source: 'Tania-Maxwell',
    title: 'Tidal amplitude M2 [Maxwell Global Tidal Marsh Carbon Covariate Layers v0.1]',
    description: 'Bathy extend 5km. Reduced 50 times with updateMask data mask at all layer 2km, layer 10km, layer 20km, layer 50km. Then reduced by 10 pixels 10 times to reach montreal. Covariate layers used for testing in the tidal marsh carbon project',
    citation: 'The code used to compute FES2014, was developed in collaboration between Legos, Noveltis, CLS Space Oceanography Division and CNES is available under GNU General Public License',
  //  doi: '',
    assetName: assetName,
    dateGenerated: ee.Date(Date.now())
  };
  print (vars)
  
  
  
  
  //Export final classified image to asset
  Export.image.toAsset({
    image: M2Tide.set(vars), //include variables set above
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
  
  