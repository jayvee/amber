# Purpose
For a given month, this scripts pulls all usage data (30 min intervals) and writes it to a CSV for that month in the data directory.
Use these CSVs for your own reporting

# Setup
Create .env file with
- export AMBER_API_TOKEN=*YOUR AMBER API TOKEN*
- export AMBER_SITE_ID=*YOUR SITE ID*
  
Create a data directory (this is where monthly exports will be stored) 

# Calling the Script 
- ruby get_amber_usage_monthly.rb 2021-11 

