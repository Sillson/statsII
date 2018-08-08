###################################################################################################
## Installs any missing packages -- barring system constraints ( will not fix binary dependencies )
###################################################################################################
installMissingPackages <- function(package_name) {
  if (! (package_name %in% rownames(installed.packages())) ) {
    install.packages(package_name, repos="http://cran.rstudio.com/")
  }
}

#################################################
## Loads all required packages in a package list
################################################
loadRequiredPackages <- function(list) {
  for (package in list) {
    installMissingPackages(package)
    library(package, character.only=TRUE)
  }
}

packages <- c('jsonlite', 'sqldf','dplyr', 'glue', 'lubridate')

loadRequiredPackages(packages)

query_date <- "20180804"

# Gather Bike Path Data
# The Capitol City Path didn't begin counting until June 2015. We want to start our analysis is May. So we'll do May 2015 onwards until today
southwest_path <- fromJSON(glue::glue("http://www.eco-public.com/api/cw6Xk4jW4X4R/data/periode/100016754?begin=20150630&end={query_date}&step=4"))
capitol_city <- fromJSON(glue::glue("http://www.eco-public.com/api/cw6Xk4jW4X4R/data/periode/100020865?begin=20150630&end={query_date}&step=4"))

# Only use May thru October
southwest_path <- southwest_path %>% 
  select(date,comptage) %>% 
  filter(month(date) %in% c(07,08))
# race condition where we receive a duplicate on 2016-10-30 that is null
southwest_path <- na.omit(southwest_path)

capitol_city <- capitol_city %>% 
  select(date,comptage) %>% 
  filter(month(date) %in% c(07,08))
# race condition where we receive a duplicate on 2016-10-30 that is null
capitol_city <- na.omit(capitol_city)

bike_path_counts <- sqldf("select southwest_path.date, SUM(southwest_path.comptage + capitol_city.comptage) AS count from southwest_path join capitol_city ON southwest_path.date = capitol_city.date GROUP BY southwest_path.date")

weather_data <- read.csv('weather_data.csv')

bike_path_counts$date <- as.Date(bike_path_counts$date)
weather_data$date <- as.Date(weather_data$date)


df <- merge(bike_path_counts,weather_data)

df <- df %>%
  select(date,count,temp,temp_min,temp_max,prcp) %>% 
  filter(!wday(date) %in% c(1, 7))