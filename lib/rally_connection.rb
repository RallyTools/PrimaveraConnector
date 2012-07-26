require "rally_rest_api"
require File.dirname(__FILE__) + "/rally_logger"

class RallyConnection

  attr_accessor :workspace
  attr_accessor :project

  def initialize(user, password, url, ws_version, workspace, project)
    @username = user
    @password = password
    @base_url = url
    @ws_version = ws_version
    @workspace_name = workspace
    @project_name = project
  end

  def connect()
    RallyLogger.info(self, "Connecting to Rally")
    begin
      @rally = RallyRestAPI.new(:username => @username, :password => @password, :base_url => @base_url,
                                :http_headers => get_custom_headers(), :version => @ws_version)
    rescue Exception => ex
      RallyLogger.error(self, "Exception #{ex.class}: #{ex.message} trying to log in " +
          "to Rally at #{@base_url} as user #{@username}")
      puts "Exception #{ex.class}: #{ex.message} Trying to log in to Rally at #{@base_url} as user #{@username}"
      return false
    end

    @workspace = find_workspace(@workspace_name)
    @project = find_project(@workspace, @project_name)

    if (@workspace && @project)
      RallyLogger.info(self, "Connected to Rally")
      RallyLogger.info(self, "  Server: #{@base_url}")
      RallyLogger.info(self, "  Workspace: #{@workspace_name}")
      RallyLogger.info(self, "  Project: #{@project_name}")
      return true
    else
      return false
    end
  end

  def get_custom_headers()
    custom_headers = CustomHttpHeader.new
    custom_headers.name    = @integration_name    ||= "Rally Connector for Primavera"
    custom_headers.version = @integration_version ||= "0.1"
    custom_headers.vendor  = @integration_vendor  ||= "Rally"
    custom_headers
  end

  def find_workspace(workspace_name)
    workspace = @rally.user.subscription.workspaces.find { |w| w.name == workspace_name && w.state == 'Open' }
    if workspace.nil?
      RallyLogger.error(self, "Couldn't find an open Rally workspace named #{workspace_name}")
    end
    workspace
  end

  def find_project(workspace, project_name)
    project = nil
    begin
      project = workspace.projects.find { |p| p.name == project_name && p.state == 'Open' }
    rescue Exception => ex
      project = nil
    end
    project
  end

  def get_time_entries()
    oid = @project.object_i_d
    query_result = @rally.find(:time_entry_item, :workspace => @workspace, :fetch => true) do
      equal :project, '/project/' + oid
      not_equal :task, '""'
    end
    query_result
  end

  def get_time_values()
    oid = @project.object_i_d
    query_result = @rally.find(:time_entry_value, :workspace => @workspace, :fetch => true) do
      equal "TimeEntryItem.Project", '/project/' + oid
      not_equal "TimeEntryItem.Task", '""'
    end
    query_result
  end

  #TODO: Make data access efficient - lazy reads below result in many small requests to server
  def aggregate_time_entries(entries)
    result = {}
    entries.each do |entry|
      if entry.values != nil
        p6activity = entry.task.p6_activity
        if !p6activity.nil?
          if !result.has_key?(p6activity)
            result[p6activity] = 0.0
          end
          entry.values.each do |value|
            result[p6activity] += value.hours.to_f
          end
        end
      end
    end
    result
  end
end
