require 'net/http'
require 'net/https'
require 'json'
require 'dotenv'
require 'date'
require 'csv'
require 'byebug'
require "google/cloud/storage"

Dotenv.load

AMBER_API_TOKEN=ENV['AMBER_API_TOKEN']
AMBER_SITE_ID=ENV['AMBER_SITE_ID']
DATA_FOLDER="data"

month = ARGV[0]

raise ArgumentError, "must supply env variables AMBER_API_TOKEN and AMBER_SITE_ID" if AMBER_API_TOKEN.empty? || AMBER_SITE_ID.empty?

def get_amber_usage(site_id, first_day, last_day)
    uri = URI("https://api.amber.com.au/v1/sites/#{site_id}/usage?startDate=#{first_day}&endDate=#{last_day}&resolution=30")
  
    # Create client
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  
    # Create Request
    req =  Net::HTTP::Get.new(uri)
    # Add headers
    req.add_field "Authorization", "Bearer #{AMBER_API_TOKEN}"
  
    # Fetch Request
    res = http.request(req)
    #puts "Response HTTP Status Code: #{res.code}"
    #puts "Response HTTP Response Body: #{res.body}"
    return res.body
  rescue StandardError => e
    puts "HTTP Request failed (#{e.message})"
end

def get_amber_usage_response(month)
  first_day_of_month = month + "-01"
  start_date_of_month = Date.parse(month + "-01") 
  end_date_of_month = (start_date_of_month >> 1)-1
  response_body = get_amber_usage(AMBER_SITE_ID,start_date_of_month.to_s,end_date_of_month.to_s)
  response_json = JSON.parse(response_body)
  response_json.each { |h| h.delete("tariffInformation") } # remove tariffInformation from all data, some early data doesn't have the information
  response_json.each { |h| h.delete("descriptor") } # remove descriptor from all data
  return response_json
end

def write_monthly_file_json(month,file_name,file_path)
  response_json = get_amber_usage_response(month)
  File.write(file_name,JSON.pretty_generate(response_json))
  puts "File #{file_path} written to #{file_path}"
end

def write_monthly_file_csv(month,file_name,file_path)
  response_json = get_amber_usage_response(month)
  file_name = "data/amber_usage_#{month}.csv"
  headers = response_json.first.keys
  CSV.open(file_path, "w", 
  :write_headers=> true,
  :headers=> headers) do |csv| 
    response_json.each do |hash|
      csv << hash.values
    end
  end
  puts "File #{file_name} written to #{file_path}"
end

def upload_datafile_to_gcloud_storage(file_name,file_path)
  puts "Uploading #{file_path} to Google Cloud Storage Bucket #{GOOGLE_CLOUD_STORAGE_DATA_BUCKET} in Project ID #{GOOGLE_CLOUD_PROJECT_ID} ..."
  storage = Google::Cloud::Storage.new project_id: GOOGLE_CLOUD_PROJECT_ID
  bucket  = storage.bucket GOOGLE_CLOUD_STORAGE_DATA_BUCKET, skip_lookup: true
  file = bucket.create_file file_path, file_name
  puts "Uploaded #{file_path} as #{file.name} in Google Cloud Storage Bucket #{GOOGLE_CLOUD_STORAGE_DATA_BUCKET}"
  return file
end

file_name = "amber_usage_#{month}.csv"
file_path = File.join(DATA_FOLDER,file_name)
write_monthly_file_csv(month,file_name,file_path)


if ARGV[1] == "--upload_to_gcloud_storage"
  GOOGLE_CLOUD_PROJECT_ID=ENV['GOOGLE_CLOUD_PROJECT_ID']
  GOOGLE_CLOUD_STORAGE_DATA_BUCKET=ENV['GOOGLE_CLOUD_STORAGE_DATA_BUCKET']
  raise ArgumentError, "must supply env variables GOOGLE_CLOUD_STORAGE_DATA_BUCKET and GOOGLE_CLOUD_PROJECT_ID" if GOOGLE_CLOUD_STORAGE_DATA_BUCKET.empty? || GOOGLE_CLOUD_PROJECT_ID.empty?
  file = upload_datafile_to_gcloud_storage(file_name,file_path)
end


  


