// Script to convert Ecological Coastal Units to 
// pre-processed by T. Worthington
// represented by segments along the world's coastline
// we have only include 7 variables of the ones in the original dataset

/****************************************************
 * General Info
 ****************************************************/

var covariateName = 'ECU' ;
// smaller site
var uk = ee.Geometry.Polygon(
  [[[-14.773542314042771,49.80571809296125], 
[3.3319264359572287,49.80571809296125],
[3.3319264359572287,59.73119695514474],
[-14.773542314042771,59.73119695514474],
[-14.773542314042771,49.80571809296125]]], null, false ); // only UK

//entire world
var world = ee.Geometry.Polygon([-180, 60, 0, 60, 180, 60, 180, -60, 10, -60, -180, -60], null, false);



var ECU_FC = ee.FeatureCollection('users/tomworthington81/ECU_Grid') 


print(ECU_FC.first());
// from: https://gis.stackexchange.com/questions/413231/converting-featurecollection-properties-to-image-bands-in-earth-engine 
  // make list of properties by hand
var properties = ['CHLORO','FLOW', 'TURB', 'WAVE', 'CLUSTER', 'ERODE_Code', 'EMU_Code'] 
print('properties', properties)

// iterate over the list of properties to create an image. bands are now in a sinlge img
var img_list = ee.Image(properties.map(function(property) {
  return ECU_FC.select([property])
    .reduceToImage([property], ee.Reducer.first())
    .rename([property])
}))
  //NOTE: this doesn't work for factors (i.e.  'EMU', 'ERODE') - will run but can't add to map
print(img_list)
//Map.addLayer(img_list, {}, 'ECU image');

var layer_toreduce_mean = img_list.select('CHLORO', 'FLOW', 'TURB', 'WAVE');

var layer_toreduce_mode = img_list.select('CLUSTER', 'ERODE_Code', 'EMU_Code');

var saltmarsh_v2_6 = ee.Image('users/tomworthington81/SM_Global_2020/global_export_v2_6/saltmarsh_v2_6');

Map.addLayer(saltmarsh_v2_6, {palette:'firebrick'}, 'Global Tidal Marsh Extent', true);



/****************************************************
 * How to extend values to entire bathy mask?
 ****************************************************/
 
 // dataMask expansion 
var dataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3')
    .focal_min({radius: 5000, units: 'meters'});  // 5km

var originalDataMask = ee.Image('projects/UQ_intertidal/dataMasks/topyBathyEcoMask_300m_v2_0_3');


Map.addLayer(originalDataMask, {palette:'yellow'}, "Data Mask");

// /// potential reducing option to be repeated as many times as needed to cover the bathy mask

// var reduced1 =  img_list
//     .reduceNeighborhood({
//       reducer: ee.Reducer.mean(), 
//       kernel: ee.Kernel.circle(1, 'pixels'), // 
//       skipMasked: false //we want to include the masked values, this is where we want to predict
//   });

// /// note: this will take MANY iterations if we only do 1 pixel at a time since it starts from a very thin line segment
// // option: save as a coarse resolution asset, then reduce several times; repeat? 

// print(reduced1);

// Map.addLayer(reduced1, {}, 'ECU reduced');



/*********************************
 * Step 1: grow over 2km (2 times reduced by 1 pixel)
 *  Unmask the original map to the reduced by 2 pixels
// *********************************/

var layer1 = layer_toreduce_mean
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
var layer_2km = layer_toreduce_mean
    .unmask(layer2) //unmask values using the values recalculated above
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(properties);


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
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(covariateName);

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
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(covariateName);



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


//  Unmask the map (already unmasked by 2km extend) to the reduced by 10 pixels
var layer_50km = layer_20km
    .unmask(layer50) //unmask values using the values recalculated above
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(covariateName);




/*********************************
 * Step 5: grow the 50km extended map by another 20 km (reduced 20 more times)
 * Then, unmask the 50km map by the 20km grow
// *********************************/


var layer51 = layer_50km
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer52 = layer51
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer53 = layer52
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer54 = layer53
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer55 = layer54
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer56 = layer55
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer57 = layer56
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer58 = layer57
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer59 = layer58
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer60 = layer59
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer61 = layer60
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer62 = layer61
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer63 = layer62
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer64 = layer63
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer65 = layer64
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer66 = layer65
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer67 = layer66
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer68 = layer67
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer69 = layer68
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer70 = layer69
    .reduceNeighborhood({
      reducer: ee.Reducer.mean(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


//// need to extend another at least 50km to reach edge inner Stockholm area
// trying with more pixels
var layer_70km = layer_50km
    .unmask(layer70) //unmask values using the values recalculated above
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(covariateName);



/*********************************
 * Step 6: grow the 70km extended map by another 80 km (done very corsely as only trying to reach inner lagoon of Stockholm)
 * Then, unmask the 70km map by the 80km grow
// *********************************/

var layer80 = layer_70km
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
var ECU_mean = layer_70km
    .unmask(layer150) //unmask values using the values recalculated above
    .updateMask(dataMask); //masking with the topyBathyEcoMask
//    .clip(site)
    // .rename(covariateName);



/*********************************
 * Step 1: grow over 2km (2 times reduced by 1 pixel)
 *  Unmask the original map to the reduced by 2 pixels
// *********************************/

var layer1 = layer_toreduce_mode
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
//need to extend a second time, also only by 1 pixel to cover the whole area
var layer2 = layer1
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

//  Unmask the original map to the reduced by 2 pixels
var layer_2km = layer_toreduce_mode
    .unmask(layer2) //unmask values using the values recalculated above
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(covariateName);


/*********************************
 * Step 2: grow the 2km extended map by another 10 km (reduced 10 times total)
 * Then, unmask the 2km by the 10km grow
// *********************************/

var layer3 = layer_2km
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer4 = layer3
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer5 = layer4
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer6 = layer5
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer7 = layer6
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer8 = layer7
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


var layer9 = layer8
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer10 = layer9
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


//  Unmask the map (already unmasked by 2km extend) to the reduced by 10 pixels
var layer_10km = layer_2km
    .unmask(layer10) //unmask values using the values recalculated above
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(covariateName);

/*********************************
 * Step 3: grow the 10km extended map by another 10 km (reduced 10 more times)
 * Then, unmask the 10km map by the 20km grow
// *********************************/

var layer11 = layer_10km
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer12 = layer11
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer13 = layer12
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer14 = layer13
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer15 = layer14
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer16 = layer15
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer17 = layer16
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer18 = layer17
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer19 = layer18
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer20 = layer19
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


//  Unmask the map (already unmasked by 2km extend) to the reduced by 10 pixels
var layer_20km = layer_10km
    .unmask(layer20) //unmask values using the values recalculated above
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(covariateName);



/*********************************
 * Step 4: grow the 20km extended map by another 30 km (reduced 30 more times)
 * Then, unmask the 20km map by the 30km grow
// *********************************/


var layer21 = layer_20km
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer22 = layer21
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer23 = layer22
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer24 = layer23
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer25 = layer24
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer26 = layer25
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer27 = layer26
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer28 = layer27
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer29 = layer28
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer30 = layer29
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer31 = layer30
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer32 = layer31
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer33 = layer32
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer34 = layer33
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer35 = layer34
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer36 = layer35
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer37 = layer36
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer38 = layer37
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer39 = layer38
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer40 = layer39
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


var layer41 = layer40
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer42 = layer41
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer43 = layer42
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer44 = layer43
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer45 = layer44
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer46 = layer45
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer47 = layer46
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer48 = layer47
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer49 = layer48
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer50 = layer49
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


//  Unmask the map (already unmasked by 2km extend) to the reduced by 10 pixels
var layer_50km = layer_20km
    .unmask(layer50) //unmask values using the values recalculated above
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(covariateName);




/*********************************
 * Step 5: grow the 50km extended map by another 20 km (reduced 20 more times)
 * Then, unmask the 50km map by the 20km grow
// *********************************/


var layer51 = layer_50km
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer52 = layer51
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer53 = layer52
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer54 = layer53
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer55 = layer54
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer56 = layer55
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer57 = layer56
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer58 = layer57
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer59 = layer58
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer60 = layer59
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer61 = layer60
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer62 = layer61
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
 
var layer63 = layer62
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  })
  
var layer64 = layer63
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer65 = layer64
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer66 = layer65
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer67 = layer66
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer68 = layer67
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer69 = layer68
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer70 = layer69
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mean of values around 
      kernel: ee.Kernel.circle(1, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


//// need to extend another at least 50km to reach edge inner Stockholm area
// trying with more pixels
var layer_70km = layer_50km
    .unmask(layer70) //unmask values using the values recalculated above
    .updateMask(dataMask); //masking with the topyBathyEcoMask
    // .rename(covariateName);



/*********************************
 * Step 6: grow the 70km extended map by another 80 km (done very corsely as only trying to reach inner lagoon of Stockholm)
 * Then, unmask the 70km map by the 80km grow
// *********************************/

var layer80 = layer_70km
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mode of values around 
      kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer90 = layer80
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mode of values around 
      kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer100 = layer90
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mode of values around 
      kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer110 = layer100
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mode of values around 
      kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer120 = layer110
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mode of values around 
      kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer130 = layer120
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mode of values around 
      kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });

var layer140 = layer130
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mode of values around 
      kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });
  
var layer150 = layer140
    .reduceNeighborhood({
      reducer: ee.Reducer.mode(), // mode of values around 
      kernel: ee.Kernel.circle(10, 'pixels'), // circle recommended over square (Daniele)
      skipMasked: false //we want to include the masked values, this is where we want to predict
  });


/*********************************
 * Layer to export.
// *********************************/

//  this is the layer to export
var ECU_mode = layer_70km
    .unmask(layer150) //unmask values using the values recalculated above
    .updateMask(dataMask) //masking with the topyBathyEcoMask
//    .clip(site)
    .int(); // clusters are an integer
    // .rename(covariateName);

/*********************************
 * Test exported reduced layers.
// *********************************/

// var ECU_china = ee.Image('users/tlgm2/covariate_global_tests/ECU_v0_1_china');
// Map.addLayer(ECU_china.select('CHLORO'), {palette:'orange'}, "original reduced ECU china");

// var ECU_china_mode = ee.Image('users/tlgm2/covariate_global_tests/ECU_mode_v0_1_china');
// Map.addLayer(ECU_china_mode.select('CLUSTER'), {palette:'green'}, "mode reduced ECU china");

// var UK_mode = ee.Image('users/tlgm2/covariate_global_tests/ECU_mode_v0_1_uk');
// Map.addLayer(UK_mode, {}, "Reduced UK");

// var UK_mean = ee.Image('users/tlgm2/covariate_global_tests/ECU_mean_v0_1_uk');
// Map.addLayer(UK_mean, {}, "Reduced mean UK");


/*********************************
 * Visualize  layers.
// *********************************/


var world_mode = ee.Image('users/tlgm2/covariate_global/ECU_mode_v0_1');
// Map.addLayer(UK_mode, {}, "Reduced UK");

var world_mean = ee.Image('users/tlgm2/covariate_global/ECU_mean_v0_1');
// Map.addLayer(UK_mean, {}, "Reduced mean UK");

// ************* Numerical layers ********************/
// var flowParams = {
//     min: 0,
//   max: 300000,
//   palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
//   opacity: 0.5,
// };
  

// Map.addLayer(world_mean.select('FLOW'), flowParams, "Flow asset");
// Map.addLayer(img_list.select('FLOW'), flowParams, 'Flow original');

// var chloroParams = {
//     min: 0,
//   max: 35,
//   palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
//   opacity: 0.5,
// };
  
// // Map.addLayer(world_mean.select('CHLORO'), chloroParams, "CHLORO asset");
// // Map.addLayer(img_list.select('CHLORO'), chloroParams, 'CHLORO original');

// var turbParams = {
//     min: 0,
//   max: 3,
//   palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
//   opacity: 0.5,
// };
  
// Map.addLayer(world_mean.select('TURB'), turbParams, "TURB asset");
// Map.addLayer(img_list.select('TURB'), turbParams, 'TURB original');

// var waveParams = {
//     min: 0,
//   max: 5,
//   palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
//   opacity: 0.5,
// };
  
// Map.addLayer(world_mean.select('WAVE'), waveParams, "WAVE asset");
// Map.addLayer(img_list.select('WAVE'), waveParams, 'WAVE original');


// ************* Categorical layers ********************/


var clusterParams = {
    min: 1,
  max: 16,
  palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
  opacity: 0.5,
};

Map.addLayer(world_mode.select('CLUSTER'), clusterParams, "Cluster asset");
Map.addLayer(img_list.select('CLUSTER'), clusterParams, 'Cluster original');


// var erodeParams = {
//     min: 1,
//   max: 4,
//   palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
//   opacity: 0.5,
// };

// Map.addLayer(world_mode.select('ERODE_Code'), erodeParams, "Erode asset");
// Map.addLayer(img_list.select('ERODE_Code'), erodeParams, 'Erode original');


// var emuParams = {
//     min: 1,
//   max: 21,
//   palette: ['blue', 'purple', 'cyan', 'green', 'yellow', 'red'],
//   opacity: 0.5,
// };

// Map.addLayer(world_mode.select('EMU_Code'), emuParams, "EMU asset");
// Map.addLayer(img_list.select('EMU_Code'), emuParams, 'EMU original');



/*********************************
 * Test map covers all of saltmarsh extent.
// *********************************/

// step 1: convert layer to 1s and 0s (1 = has a value, 0 = does not)
// for the present(1s): absolute value: in case of negative values, add 1 in case of 0 values
// unmask to 0 for values not present
var layer_for_boolean0 = world_mode.select('CLUSTER').abs().add(1).unmask(0);

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
  geometry: world,
  crs: marsh_layer_diff.projection(),
  scale: 927.66,
  geometryType: 'polygon',
  eightConnected: false,
  labelProperty: 'extent not covered by covariate',
  maxPixels: 1e13
});


var vectorsDraw = vectors.draw({color: '800080', strokeWidth: 20});
Map.addLayer(vectorsDraw, {}, 'extent not covered by covariate');

// issues near Stockhold - need to reduce another 50 km 


/*********************************
 * SINGLE COVARIATE: Export to Asset.
// *********************************/

var covariateName = 'ECU_mean';
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
  sourceData: 'users/tomworthington81/ECU_Grid',
  sourceLink:'https://www.arcgis.com/home/item.html?id=54df078334954c5ea6d5e1c34eda2c87',
  covariateName: covariateName,
  generationScript: 'https://code.earthengine.google.com/c7f1a7c1817fd2ca8e8f0bf99d049fd6?asset=users%2Ftomworthington81%2FECU_GEE_sel',
  // codePath: 'https://code.earthengine.google.com/?scriptPath=users%2Fmurrnick%2Fglobal-intertidal-change%3Aclassifications%2FcovariateReduce_v3',
  project: 'global-marsh-carbon',
  source: 'Tania-Maxwell',
  title: 'Ecological Coastal Units Numerical Variables [Maxwell Global Tidal Marsh Carbon Covariate Layers v0.1]',
  description: 'Bathy extend 5km. Reduced 150 times with updateMask data mask at all layer 2km, layer 10km, layer 20km, layer 50km, layer 70km, layer 150km. Covariate layers used for testing in the tidal marsh carbon project',
  citation: 'Sayre, R., S. Noble, S. Hamann, R. Smith, D. Wright, S. Breyer, K. Butler, K. Van Graafeiland, C. Frye, D. Karagulle, D. Hopkins, D. Stephens, K. Kelly, Z, basher, D. Burton, J. Cress, K. Atkins, D. van Sistine, B. Friesen, B. Allee, T. Allen, P. Aniello, I Asaad, M. Costello, K. Goodin, P. Harris, M. Kavanaugh, H. Lillis, E. Manca, F. Muller-Karger, B. Nyberg, R. Parsons, J. Saarinen, J. Steiner, and A. Reed. 2018. A new 30 meter resolution global shoreline vector and associated global islands database for the development of standardized global ecological coastal units. Journal of Operational Oceanography – A Special Blue Planet Edition.',
  doi: 'doi:10.1080/1755876X.2018.1529714',
  assetName: assetName,
  dateGenerated: ee.Date(Date.now())
};
print (vars)


//Export final classified image to asset
Export.image.toAsset({
  image: ECU_mean.set(vars), //include variables set above
  description: 'export_'
    .concat(covariateName)
    .concat('_world'),
    // .concat(startDate.slice(0,4))
    // .concat(endDate.slice(0,4)),
  assetId: assetName,
  scale: 1110,
  region: world, 
  maxPixels: 1e13 
});
