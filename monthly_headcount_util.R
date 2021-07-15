# Generates dataframe with details about monthly headcount and utility
# use for several Fiscal Service offices.
# Includes columns Location, Date, Mcf, Mwh, and Monthly Headcount.
# Use the first day of each month to capture total utilities used that month
# and average headcount, when available.


library(tidyverse)
library(readxl)
library(lubridate)


##### import data #####
setwd("C:/Users/bturse02/Documents/github/acop_datathon_2021/")
headcount <- read_excel("Datathon Headcount Dataset.xlsx")
electric <- read_excel("Datathon Utility Dataset.xlsx", sheet = "Electric Hackathon")
gas <- read_excel("Datathon Utility Dataset.xlsx", sheet = "Gas Hackathon")
location_xwalk <- read_excel("location crosswalk.xlsx") # map cities to buildings

# format headcount, gas, and electric tables
# headcount is provided per day, electric and gas provided per month.
# Roll up headcount to average for each month.
monthly_hc <- headcount %>% 
  left_join(select(location_xwalk, `Headcount Locations`, City), 
            by=c("Location"="Headcount Locations")) %>% 
  group_by(Location, `Year Number` = year(Date), `Month Number` = month(Date)) %>% 
  summarise(`Monthly Headcount` = mean(`Individual Count (rounded to nearest 10)`)) %>% 
  mutate(Date=mdy(paste(`Month Number`,"/","1",`Year Number`))) %>% 
  ungroup() %>% 
  select(Date, Location, `Monthly Headcount`)

# gas and electric date is for previous month used utilities. headcount Date is
# for current date. Subtract 1 month from gas and electric to match against
# headcount
monthly_gas <- gas %>% 
  left_join(select(location_xwalk, `Utility Buildings`, Location=`Headcount Locations`),
            by=c("Buliding"="Utility Buildings")) %>% 
  mutate(`Date` = Date %m+% months(-1)) %>% 
  select(`Date`, Location, Mcf) 

monthly_elec <- electric %>% 
  left_join(select(location_xwalk, `Utility Buildings`, Location=`Headcount Locations`),
            by=c("Buliding"="Utility Buildings")) %>% 
  mutate(`Date` = Date %m+% months(-1)) %>% 
  select(`Date`, Location, Mwh) 


# location_monthly_dates_xwalk: empty table with all combinations of Date and Location
# values from utilities and headcount datasets. Used as blank template to
# populate with summarized data.
monthly_dates <- as_tibble(unique(c(monthly_hc$Date,monthly_gas$Date,monthly_elec$Date)))
colnames(monthly_dates) <- "Date"
location_monthly_dates_xwalk = merge(
  select(location_xwalk, Location=`Headcount Locations`), monthly_dates)

# populate location_monthly_dates_xwalk with utility and headcount data
utilities = merge(monthly_gas, monthly_elec, all=TRUE)
monthly_hc_util = merge(location_monthly_dates_xwalk, utilities, all=TRUE)
monthly_hc_util = merge(monthly_hc_util, monthly_hc, all=TRUE)

# keep only dataframe to be imported to power bi dashboard
rm(list=setdiff(ls(),"monthly_hc_util"))
