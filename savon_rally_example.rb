require 'savon'
require 'pp'

#ENV['http_proxy'] = "http://127.0.0.1:8888"

Savon.configure do |config|
  config.log = true
end

HTTPI.log = true

client = Savon::Client.new do
  http.auth.basic "yeti@rallydev.com","RallyDev"
  http.auth.ssl.verify_mode = :none
  wsdl.document = "https://trial.rallydev.com/slm/webservice/1.22/meta/1148554124/rally.wsdl"
end

#pp client.wsdl.soap_actions

#response = client.request :get_current_user
#object = response.to_hash[:get_current_user_response][:get_current_user_return]
#puts "#{object[:user_name]} (#{object[:email_address]})"

query_response = client.request :query_original_request do
  soap.body = {
    :workspace => nil,
    :artifact_type => 'Defect',
    :query => '(State = "Open")',
    :order => nil,
    :fetch => true,
    :start => 1,
    :pagesize => 100
  }
end

query_result_hash = query_response.to_hash[:query_response][:query_return]

puts "Total defects found: #{query_result_hash[:total_result_count]}"
puts "-------------------"

query_result_hash[:results][:object].each do |defect|
  puts "#{defect[:name]} --- #{defect[:formatted_id]} --- #{defect[:object_id]}"
end


