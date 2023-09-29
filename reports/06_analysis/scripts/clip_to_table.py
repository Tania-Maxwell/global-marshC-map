"""TB 21/09/23 This script checks whether pixels in the input rasters 
are within any country boundaries, then outputs the data as a table. """

import numpy as np
import pandas as pd
import os
import sys
import rasterio
import geopandas as gpd
from rasterio.features import rasterize
from rasterio.transform import from_bounds
from shapely.geometry import shape

    # Inputs 
# Change these as needed; currently you can write "pathtoraster1.tif,pathtoraster2.tif" etc 
# and it will split them into a list like ["pathtoraster1.tif", "pathtoraster2.tif", ... ]. 
data_rasters_list = sys.argv[1].split(",")
output_table_name = "output_name.csv" # probably use sys.argv[2] to pass this in with snakemake?

# You can probs do this generatively from the filenames but I couldn't recall the names of your
# .tifs. The first two are fixed, the others need to be in the order you list the input rasters.
column_names = ["country_iso3", "pixel_areas_m2"] + ["pred_30","aoa_30","err_30",
                                                     "pred_100","aoa_100","err_100"] 

# I have a geopackage with all the countries in - if this isn't the case for your country data 
# you'll maybe need to do this slightly differently but shouldn't be too difficult.
shapefile_data_path = "path1/path2/wherever_your_shapefile_is.gpkg"
shapefile = os.path.join(shapefile_data_path)
layer = "ne_50m_admin_0_countries" # this is what the country dat is called in mine
country_data = gpd.read_file(shapefile, layer = layer)

    # Functions
def get_pixel_areas(dataset):
    """Calculates the area of each pixel in m2, assuming the units of
    extent in your input data are degrees (I think they should be). This 
    is a bit rough, you may want to check this! The input variable is a 
    rasterio dataset."""
    latitudes = np.linspace(dataset.bounds.bottom, dataset.bounds.top, 
                            dataset.height)
    R = 6371000
    y0 = R * np.sin(np.deg2rad(dataset.res[0]))
    ydist = R * (np.sin(np.deg2rad(abs(latitudes))) \
                 - np.sin(np.deg2rad(abs(latitudes) - dataset.res[0])))
    return np.multiply(np.full_like(dataset.read(1), 1).T, (ydist * y0)).T
def get_country_mask(bounds, width, height, cdat):
    """Rasterize country boundaries to match geotiff grid. This returns 
    ones where the country is."""
    transform = from_bounds(*bounds, width, height)
    country_raster = rasterize(
        cdat.geometry,
        out_shape=(height, width),
        transform=transform,
        dtype=int,
        fill=0)
    return country_raster

    # Main
# Get boundaries from the first data raster
with rasterio.open(data_rasters_list[0]) as temp_ds:
    pixel_areas = get_pixel_areas(temp_ds)
    # Get the boundary of the first .tif
    bounds = temp_ds.bounds
    width = temp_ds.width
    height = temp_ds.height
    bbox_polygon = shape({
        "type": "Polygon","coordinates": [
        [(bounds.left, bounds.bottom),(bounds.left, bounds.top),
        (bounds.right, bounds.top),(bounds.right, bounds.bottom),
        (bounds.left, bounds.bottom),]]})
    temp_ds.close()

# Output table
df = pd.DataFrame(columns = column_names)

# Add countries contained to a str for easier reading later!
addstr = []

# Loop through countries, check if they contain the tif (faster 
# than rasterising each country first).
country_ids = country_data["ISO_A3"]
for c, cid in enumerate(country_ids):
    # You might need to change ISO_A3 to whatever indexing your gpkg uses
    cdat = country_data[country_data['ISO_A3'] == cid] 
    intersects = cdat.geometry.intersects(bbox_polygon).any()
    dfx = pd.DataFrame(columns = column_names) # mini df for each country
    # Contains .tif?
    if intersects:
        # rasterise the country of interest
        mask = get_country_mask(bounds, width, height, cdat)
        # read in each .tif 
        for f, file in enumerate(data_rasters_list):
            col_name = column_names[f+2]
            dataset = rasterio.open(file).read(1)
            ds_masked = dataset * mask
            r_idx, c_idx = np.nonzero(ds_masked)
            dfx[col_name] = ds_masked[r_idx,c_idx] # add the non-zero values to the dataframe
        dfx["pixel_areas_m2"] = pixel_areas[r_idx,c_idx] # fill in pixel areas
        dfx["country_iso3"] = cid # fill in country labels
        addstr.append(cid)
    print(" " * 100,end = "\r")
    print(f"prog: {round(c/len(country_ids),4)}",end = "\r")
    df = pd.concat([df, dfx])

otn = output_table_name.split(".")[0] + "_".join(addstr) + output_table_name.split(".")[-1]
df.to_csv(otn)