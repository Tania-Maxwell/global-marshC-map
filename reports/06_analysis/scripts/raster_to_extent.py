import os
from osgeo import ogr
from osgeo import osr
from osgeo import gdal

tiff_directory = 'tiles_world_30m/SW/' ### CHANGE HERE TO NW, NE, SE, or SW
output_vector_file = 'tiles_extents/vectors_SW.shp' ### CHANGE HERE TO NW, NE, SE, or SW

driver = ogr.GetDriverByName('ESRI Shapefile')

output_ds = driver.CreateDataSource(output_vector_file)

srs = osr.SpatialReference()
srs.ImportFromEPSG(4326)  # WGS84
output_layer = output_ds.CreateLayer('tiles', srs=srs, geom_type=ogr.wkbPolygon)

### create all the fields for the extent vector ( the tile ID and all 6 output files)

field_name = ogr.FieldDefn('tile_ID', ogr.OFTString)
field_name.SetWidth(96)  # Adjust width as needed
output_layer.CreateField(field_name)

address_pred_0 = ogr.FieldDefn('pred_0', ogr.OFTString)
address_pred_0.SetWidth(254)  # Adjust width as needed
output_layer.CreateField(address_pred_0)

address_aoa_0 = ogr.FieldDefn('aoa_0', ogr.OFTString)
address_aoa_0.SetWidth(254)  # Adjust width as needed
output_layer.CreateField(address_aoa_0)

address_err_0 = ogr.FieldDefn('err_0', ogr.OFTString)
address_err_0.SetWidth(254)  # Adjust width as needed
output_layer.CreateField(address_err_0)

address_pred_30 = ogr.FieldDefn('pred_30', ogr.OFTString)
address_pred_30.SetWidth(254)  # Adjust width as needed
output_layer.CreateField(address_pred_30)

address_aoa_30 = ogr.FieldDefn('aoa_30', ogr.OFTString)
address_aoa_30.SetWidth(254)  # Adjust width as needed
output_layer.CreateField(address_aoa_30)

address_err_30 = ogr.FieldDefn('err_30', ogr.OFTString)
address_err_30.SetWidth(254)  # Adjust width as needed
output_layer.CreateField(address_err_30)

# tiff_file = "export_LA_low_forAndre.tif"
# tiff_file = "export_NW_30m-0000197120-0000448000.tif"

# Loop through the TIFF files in the directory, extract their footprints, and add records to the attribute table
for tiff_file in os.listdir(tiff_directory):
    if tiff_file.endswith('.tif'):
        # Open the TIFF file
        ds = gdal.Open(os.path.join(tiff_directory, tiff_file))
        
        width = ds.RasterXSize
        height = ds.RasterYSize

        # Get the footprint geometry (extent)
        geotransform = ds.GetGeoTransform() # not this only gives the minX and maxY. need to get max X using width, minY with height
        # Extract the values from the geotransform tuple: 
        originX, pixelWidth, rotation1, originY, rotation2, pixelHeight = geotransform

        # Calculate the extent coordinates
        minX = originX
        maxX = originX + (width * pixelWidth)
        minY = originY + (height * pixelHeight)
        maxY = originY
        

        ## make a geometry from those points
        ring = ogr.Geometry(ogr.wkbLinearRing)
        ring.AddPoint(minX, maxY)
        ring.AddPoint(maxX, maxY)
        ring.AddPoint(maxX, minY)
        ring.AddPoint(minX, minY)
        ring.AddPoint(minX, maxY)
        footprint = ogr.Geometry(ogr.wkbPolygon)
        footprint.AddGeometry(ring)
        
        # Create a feature and set its attributes
        feature = ogr.Feature(output_layer.GetLayerDefn())
        feature.SetGeometry(footprint)
        feature.SetField('tile_ID', tiff_file)  # Set the tile name
        feature.SetField('pred_0', ('model_NW/snakesteps/04_output/nndm_pred_0_30cm_t_ha_'+ tiff_file))  # Set the tile address
        feature.SetField('aoa_0', ('model_NW/snakesteps/04_output/AOA_nndm_0_30_'+ tiff_file))
        feature.SetField('err_0', ('model_NW/snakesteps/04_output/error_0_30_nndm_'+ tiff_file))
        feature.SetField('pred_30', ('model_NW/snakesteps/04_output/nndm_pred_30_100cm_t_ha_'+ tiff_file))  # Set the tile address
        feature.SetField('aoa_30', ('model_NW/snakesteps/04_output/AOA_nndm_30_100_'+ tiff_file))
        feature.SetField('err_30', ('model_NW/snakesteps/04_output/error_30_100_nndm_'+ tiff_file))


        # Add the feature to the layer
        output_layer.CreateFeature(feature)
        
        # Clean up
        feature = None
        ds = None

# Close the output vector dataset
output_ds = None

print("Job finished")