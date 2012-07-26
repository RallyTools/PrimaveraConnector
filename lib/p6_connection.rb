require "savon"
require "pp"

require File.dirname(__FILE__) + "/rally_logger"

#TODO: Add error handling (soap faults, etc.)
class P6Connection

  def initialize(user, password, url, project_id)
    @username = user
    @password = password
    @base_url = url
    @project_id = project_id

    Savon.configure do |config|
      config.log = false
    end
    HTTPI.log = false
  end

  def connect()
    RallyLogger.info(self, "Connecting to P6")
    wsdl_url = @base_url + "/services/AuthenticationService?wsdl"
    user = @username
    password = @password

    @auth_client = Savon::Client.new do
      http.auth.ssl.verify_mode = :none
      wsdl.document = wsdl_url
    end

    begin
      @auth_response = @auth_client.request :login do
        soap.namespaces["xmlns"] = "http://xmlns.oracle.com/Primavera/P6/WS/Authentication/V1"
        soap.body = {
            "UserName" => user,
            "Password" => password
        }
      end
      RallyLogger.info(self, "Connected to P6")
      RallyLogger.info(self, "  Server: #{@base_url}")
      return true

    rescue Exception => ex
      RallyLogger.error(self, "Exception #{ex.class}: #{ex.message} trying to log in " +
          "to P6 at #{@base_url} as user #{user}")
      puts "Exception #{ex.class}: #{ex.message} Trying to log in to P6 at #{@base_url} as user #{user}"
      return false
    end
  end

  def get_project(project_id)
    project_url = @base_url + "/services/ProjectService?wsdl"

    client = Savon::Client.new do
      http.auth.ssl.verify_mode = :none
      wsdl.document = project_url
    end
    client.http.headers["Cookie"] = @auth_response.http.headers["Set-Cookie"]

    project_response = client.request :read_projects do
      soap.namespaces["xmlns"] = "http://xmlns.oracle.com/Primavera/P6/WS/Project/V1"
      soap.body = {
          "Field" => "Id",
          "Filter" => "Id='" + project_id + "'"
      }
    end
    project_response
  end

  def get_activities(project_id)
    activities_url = @base_url + "/services/ActivityService?wsdl"

    client = Savon::Client.new do
      http.auth.ssl.verify_mode = :none
      wsdl.document = activities_url
    end
    client.http.headers["Cookie"] = @auth_response.http.headers["Set-Cookie"]

    activity_response = client.request :read_activities do
      soap.namespaces["xmlns"] = "http://xmlns.oracle.com/Primavera/P6/WS/Activity/V1"
      soap.body = {
          "Filter" => "ProjectId='" + project_id + "'",
          "Field" => ["Id", "ProjectName", "ActualLaborUnits"]
      }
    end

    activity_response.to_hash[:read_activities_response][:activity]
  end

  def update_activity(activity_id, actual_labor_units)
    activities_url = @base_url + "/services/ActivityService?wsdl"

    client = Savon::Client.new do
      http.auth.ssl.verify_mode = :none
      wsdl.document = activities_url
    end
    client.http.headers["Cookie"] = @auth_response.http.headers["Set-Cookie"]

    update_response = client.request :update_activities do
      soap.namespaces["xmlns"] = "http://xmlns.oracle.com/Primavera/P6/WS/Activity/V1"
      soap.body = "<Activity><ObjectId>" + activity_id + "</ObjectId><ActualLaborUnits>" +
          actual_labor_units + "</ActualLaborUnits></Activity>"
    end

    update_response.to_hash[:update_activities_response][:return]
  end

  def disconnect()
    logout_response = @auth_client.request :logout do
      soap.namespaces["xmlns"] = "http://xmlns.oracle.com/Primavera/P6/WS/Authentication/V1"
      soap.body = {
      }
    end
  end

end