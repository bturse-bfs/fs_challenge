# Generates dataframe with details about daily headcount and monthly utility
# use for several Fiscal Service offices.
# Includes columns Location, Date, Mcf, Mwh, and Daily Headcount.
# The first day of each month includes a measure of monthly utilities used that month, 
# when available.


library(tidyverse)
library(readxl)
library(lubridate)


##### import data #####
setwd("C:/Users/bturse02/Documents/github/acop_datathon_2021/")
headcount <- read_excel("Datathon Headcount Dataset.xlsx") %>% 
  select(Location, Date,
         `Daily Headcount`=`Individual Count (rounded to nearest 10)`)
electric <- read_excel("Datathon Utility Dataset.xlsx", sheet = "Electric Hackathon") %>% 
  select(Date, Building = Buliding, Mwh)
gas <- read_excel("Datathon Utility Dataset.xlsx", sheet = "Gas Hackathon") %>% 
  select(Date, Building = Buliding, Mcf)
location_xwalk <- read_excel("location crosswalk.xlsx") # map cities to buildings

# gather standardized names using location_xwalk
utilities = merge(electric,gas,all=TRUE) %>% 
  left_join(location_xwalk, by=c("Building"="Utility Buildings")) %>% 
  select(Date,Location=`Headcount Locations`,Mcf,Mwh)

# location_daily_dates_xwalk: all combinations of locations and  unique date
# values available on the headcount, electricity, or gas datasets. Used as blank
# template to populate with summarized data.
daily_dates <- as_tibble(unique(c(headcount$Date,utilities$Date)))
colnames(daily_dates) <- "Date"
location_daily_dates_xwalk = merge(
  select(location_xwalk, Location=`Headcount Locations`), 
  daily_dates)

# populate location_daily_dates_xwalk with utility and headcount data
daily_hc_util <- merge(location_daily_dates_xwalk, utilities, all=TRUE)
daily_hc_util = merge(daily_hc_util, headcount, all=TRUE)

# keep only dataframe to be imported to power bi dashboard
rm(list=setdiff(ls(),"daily_hc_util"))
