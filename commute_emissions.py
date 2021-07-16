import os
from numpy import unique
from pandas.core.tools.numeric import to_numeric
import requests
import json
import pandas as pd

##### Import Data #####
os.chdir("C:/Users/bturse02/Documents/github/acop_datathon_2021")
# import commute challenge data and combine with CBSA codes from census.
# Core Based Statistical Areas: https://www.census.gov/topics/housing/housing-patterns/about/core-based-statistical-areas.html
commute = pd.read_csv("Datathon Commute Data.csv",usecols=["COMMUTE DISTANCE (rounded to nearest 2 miles)","DUTY CITY"])
commute.columns = ["Distance", "DUTY CITY"]
cbsa_codes_df = pd.read_csv("commute city code xwalk.csv",usecols=["DUTY CITY","City","CBSA"])
cbsa_codes = set([code for code in cbsa_codes_df["CBSA"]])
cities = [city for city in cbsa_codes_df["City"]]

commute = commute.merge(cbsa_codes_df)
commute["CBSA"] = commute["CBSA"].astype(str)

# ACS measure of what % of people drive alone to work by statistical area
drive_pe = pd.DataFrame(columns=['Census Percent Drive Alone','CBSA'])
	
for code in cbsa_codes:
    print(code)
    # ACS 5 year profile variable DP03_0019PE: Percent!!COMMUTING TO WORK!!Workers 16 years and over!!Car, truck, or van -- drove alone
    # https://api.census.gov/data/2019/acs/acs5/profile/variables.html
    commute_api_url = "https://api.census.gov/data/2019/acs/acs5/profile?get=DP03_0019PE&&for=metropolitan%20statistical%20area/micropolitan%20statistical%20area:"+str(code)
    r = requests.get(commute_api_url)
    r.json()
    pe_cbsa = r.json()[1]
    drive_pe = drive_pe.append(pd.DataFrame([pe_cbsa], columns=drive_pe.columns))

commute_emissions = commute.merge(drive_pe).drop(["DUTY CITY", "CBSA"],axis=1)

commute_emissions["Distance"] = pd.to_numeric(commute_emissions["Distance"])
commute_emissions["Census Percent Drive Alone"] = pd.to_numeric(commute_emissions["Census Percent Drive Alone"])/100

commute_emissions["adjusted_drive_alone_distance"] = commute_emissions["Distance"]*commute_emissions["Census Percent Drive Alone"]

lbs_co2_per_mi = 404*0.00220462     # average grams emissions per mile for passenger vehicle
                                    # https://www.epa.gov/greenvehicles/greenhouse-gas-emissions-typical-passenger-vehicle
                                    # converted to lbs

commute_emissions["adjusted_lbs_co2"] = commute_emissions["adjusted_drive_alone_distance"]*lbs_co2_per_mi

commute_emissions['city_distance_cumsum_co2'] = commute_emissions.sort_values('Distance').groupby('City')['adjusted_lbs_co2'].transform(pd.Series.cumsum)
