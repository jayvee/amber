require 'net/http'
require 'net/https'
require 'json'
require 'dotenv'
require 'date'
require 'csv'
require 'byebug'

Dotenv.load

AMBER_API_TOKEN=ENV['AMBER_API_TOKEN']
AMBER_SITE_ID=ENV['AMBER_SITE_ID']

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
  response_json.each { |h| h.delete("tariffInformation") } # remove tariffInformation from all data, some early data doesn't have the information
  return response_body
end

def write_monthly_file_json(month)
  response_body = get_amber_usage_response(month)
  file_name = "data/amber_usage_#{month}.json"
  File.write(file_name,JSON.pretty_generate(JSON.parse(response_body)))
  puts "File #{file_name} written to data directory"
end

def write_monthly_file_csv(month)
  response_body = get_amber_usage_response(month)
  file_name = "data/amber_usage_#{month}.csv"
  headers = response_json.first.keys
  CSV.open(file_name, "w", 
  :write_headers=> true,
  :headers=> headers) do |csv| 
    response_json.each do |hash|
      csv << hash.values
    end
  end
  puts "File #{file_name} written to data directory"
end

write_monthly_file_csv(month)