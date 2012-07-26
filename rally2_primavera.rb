# Copyright 2002-2012 Rally Software Development Corp. All Rights Reserved.

require File.dirname(__FILE__) + "/lib/rally_logger"
require File.dirname(__FILE__) + "/lib/rally_connection"
require File.dirname(__FILE__) + "/lib/p6_connection"

#ENV['http_proxy'] = "http://127.0.0.1:8888"

RALLY_USERNAME  = 'rallyuser@company.com'
RALLY_PASSWORD  = 'mypassword'
RALLY_URL       = 'sandbox.rallydev.com'
RALLY_WORKSPACE = 'Test Workspace'
RALLY_PROJECT   = 'Test Project'

P6_USERNAME     = 'admin'
P6_PASSWORD     = 'adminpassword'
P6_URL          = 'http://server.company.com:7001/p6ws'
P6_PROJECT_ID   = 'IT00351'

RUN_INTERVAL = 1 #Number of minutes to sleep before doing the data transfer again
#RUN_INTERVAL = -1 # if you only want to run this once...

def build_activity_oid_map()
  activity_object_ids = {}
  activities = @p6_connection.get_activities(P6_PROJECT_ID)
  activities.each do |activity|
    activity_object_ids[activity[:id]] = activity[:object_id]
  end
  activity_object_ids
end

def update_p6_activities(rally_entries, activity_object_ids)
  rally_entries.each_pair do |activity_id, hours|
    if activity_object_ids.has_key?(activity_id)
      result = @p6_connection.update_activity(activity_object_ids[activity_id], hours.to_s)
      RallyLogger.info(self, "Activity #{activity_id} (#{activity_object_ids[activity_id]}) " +
          "update to #{hours.to_s} success: #{result}")
    end

  end
end

def log_rally_info(result)
  RallyLogger.info(self, "Found #{result.size} time entries in Rally:")
  result.each_pair { |activity_id, time| RallyLogger.info(self, "#{activity_id} is #{time}") }
end

def login_to_rally()
  @rally_connection = RallyConnection.new(RALLY_USERNAME, RALLY_PASSWORD,
                                          'https://' + RALLY_URL + '/slm', 1.16, 
                                          RALLY_WORKSPACE, RALLY_PROJECT)
  if !@rally_connection.connect()
    raise "Unable to connect to Rally"
  end
end

def login_to_p6()
  @p6_connection = P6Connection.new(P6_USERNAME, P6_PASSWORD, P6_URL, P6_PROJECT_ID)
  if !@p6_connection.connect()
    raise "Unable to connect to P6"
  end
end

loop do

  begin
    login_to_rally()
    login_to_p6()

    entries    = @rally_connection.get_time_entries()
    rally_info = @rally_connection.aggregate_time_entries(entries)
    log_rally_info(rally_info)

    activity_object_ids = build_activity_oid_map()
    update_p6_activities(rally_info, activity_object_ids)
    @p6_connection.disconnect()

  rescue => ex
    puts "Exception! #{ex.class}: #{ex.message}"
    puts ex.backtrace.join("\n")
    RallyLogger.exception(self, ex)
    exit!

  ensure
    exit! if RUN_INTERVAL < 0
    sleep(60 * RUN_INTERVAL)
  end
end

