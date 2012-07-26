require 'savon'
require 'pp'

#ENV['http_proxy'] = "http://127.0.0.1:8888"

P6_SERVER_IDENT  = 'vmprimavera'
P6_API_PORT      = 7001
P6_ACCESS = "%s:%s" % [P6_SERVER_IDENT, P6_API_PORT]

service_wsdl_template = "http://#{P6_ACCESS}/p6ws/services/%s?wsdl"
authentication_service_wsdl = service_wsdl_template % 'AuthenticationService'
project_service_wsdl        = service_wsdl_template % 'ProjectService'
activity_service_wsdl       = service_wsdl_template % 'ActivityService'

p6_xml_ns = "http://xmlns.oracle.com/Primavera/P6/WS/Authentication/V1"

Savon.configure do |config|
  config.log = false
end

HTTPI.log = false

auth_client = Savon::Client.new do
  http.auth.ssl.verify_mode = :none
  wsdl.document = authentication_service_wsdl
end

##
## puts "-" * 64
## pp auth_client.wsdl.soap_actions
## puts "-" * 64
##

auth_response = auth_client.request :login do
  soap.namespaces["xmlns"] = p6_xml_ns
  soap.body = { "UserName" => "admin",
                "Password" => "RallyDev"
              }
end

session_cookie = auth_response.http.headers["Set-Cookie"]
##
## puts "Session Cookie: %s" % session_cookie
##pp auth_response.http.headers["Set-Cookie"].split(';')[0]
##

client2 = Savon::Client.new do
  http.auth.ssl.verify_mode = :none
  wsdl.document = project_service_wsdl
end

client2.http.headers["Cookie"] = session_cookie

project_response = client2.request :read_projects do
  soap.namespaces["xmlns"] = p6_xml_ns
  # ID EC00501 is the "human" identifier for the project 'Haitang Corporate Park'
  soap.body = { "Field" => ["Id", "Name"],
                "Filter" => "Id='EC00501'"
              }
end

pp project_response.to_hash

client3 = Savon::Client.new do
  http.auth.ssl.verify_mode = :none
  wsdl.document = activity_service_wsdl
end

client3.http.headers["Cookie"] = session_cookie

activity_response = client3.request :read_activities do
  soap.namespaces["xmlns"] = p6_xml_ns
  soap.body = { "Filter" => "ProjectId='EC00501'",
                "Field"  => ["Id", "ProjectName", "ProjectId", "ActualLaborUnits"]
              }
end

##
#puts "-------------------------"
#pp activity_response.to_hash
#puts "-------------------------"
##

update_response = client3.request :update_activities do
  soap.namespaces["xmlns"] = p6_xml_ns
  # ObjectID 95439 is associated with EC1490 'Rough-In Phase Begins'
  # and we'll set the ActualLaborUnits (in hours) to 120 which will then show in P6 as 15.0 days
  soap.body = "<Activity><ObjectId>95439</ObjectId><ActualLaborUnits>120</ActualLaborUnits></Activity>"
end


#########################
# an update_response looks like:
#<Savon::SOAP::Response:0x00000100b0b5c0
# @http=
#  #<HTTPI::Response:0x00000100b06c78
#   @body=
#
# @http=
#   @body=
#    "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"><SOAP-ENV:Header></SOAP-ENV:Header><SOAP-ENV:Body><UpdateActivitiesResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://xmlns.oracle.com/Primavera/P6/WS/Activity/V1\"><Return>true</Return></UpdateActivitiesResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>",
#   @code=200,
#
#  ... and other stuff,  you'd really be interested in the code 
#      and the <Return>true or false</Return> in the body

##
##puts "!" * 64
##pp update_response.http.code
##pp update_response.http.body
##puts "!" * 64
##

activity_response = client3.request :read_activities do
  soap.namespaces["xmlns"] = p6_xml_ns
  soap.body = {
    "Filter" => "ObjectId=95439",
    "Field" => ["Id", "ProjectName", "ActualLaborUnits"]
  }
end

##  to observe that the ActualLaborUnits actually did get set...
##puts "-------------------------"
pp activity_response.http.body
##puts "-------------------------"
##

logout_response = auth_client.request :logout do
  soap.namespaces["xmlns"] = p6_xml_ns
  soap.body = { }
end

#pp logout_response
