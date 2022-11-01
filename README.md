# Purpose
[Amber Electric](https://www.amber.com.au) is an Australian energy retailer. This script extracts your usage data from their [usage API](https://app.amber.com.au/developers/documentation).
For a given month, this scripts pulls all usage data (in 30 min intervals) and writes it to a CSV for that month in the data directory.
Use these CSVs for your own reporting. There is an option in the command to upload the data file to your specified Google Cloud Storage bucket for use with a reporting tool such as Google Looker Studio.

# Setup
1. Create .env file with
- export AMBER_API_TOKEN=*YOUR AMBER API TOKEN*
- export AMBER_SITE_ID=*YOUR SITE ID*

2. If you want to upload your file to a GCP Storage Bucket (for example for using as the source of a Google Data Studio report)
Add the env vars
- export GOOGLE_CLOUD_STORAGE_DATA_BUCKET=*YOUR BUCKET NAME*
- export GOOGLE_AUTH_SUPPRESS_CREDENTIALS_WARNINGS=true
- Create application default credentials as per https://cloud.google.com/docs/authentication/provide-credentials-adc abd store your application_default_credentials.json file in this directory

3. Create a data directory (this is where monthly exports will be stored) 

# Calling the Script , with data stored in /data
- ruby get_amber_usage_monthly.rb 2021-11 

# Calling the Script, with data stored in /data and uploaded to Google Cloud Storage bucket
- ruby get_amber_usage_monthly.rb 2021-11 --upload_to_gcloud_storage


