import pandas as pd
import os

target_dir = "folder_with_csvs_in"
output_dir = "output_dir"
look_for = ".csv"

f = []
for path, subdirs, files in os.walk(target_dir):
    for name in files:
        f.append(os.path.join(path, name))
f = [file for file in f if look_for in file]

def findnstitch(country_string):
	cdf = pd.DataFrame() 
	files_w_country = [file for file in f if country_string in file]
	for file in files_w_country:
		dfx = pd.read_csv(file, index_col = 0)
		dfx = dfx[dfx.country_EEZ == country_string]
		cdf = pd.concat([cdf, dfx])
	return cdf

for country in country_list: # get this list from the shapefile?
	df = findnstitch(country).to_csv(os.path.join(output_dir, f"{country}.csv"))
