# Copyright 2002-2011 Rally Software Development Corp. All Rights Reserved.

require File.dirname(__FILE__) + "/lib/rally_logger"
require File.dirname(__FILE__) + "/lib/rally_connection"
require File.dirname(__FILE__) + "/lib/p6_connection"

#ENV['http_proxy'] = "http://127.0.0.1:8888"

RALLY_USERNAME  = 'authorized_user@rallydev.com'
RALLY_PASSWORD  = 'YourPW_here'
RALLY_SERVER    = 'rally1.rallydev.com' # or could be trial, or your OnPrem Rally server
RALLY_WORKSPACE = 'Primavera'  # Or whatever your project name is
RALLY_PROJECT   = 'Sample Project'  # replace with value appropos for your environment

P6_USERNAME     = 'admin'
P6_PASSWORD     = 'Your_P6_PW_here'
P6_URL          = 'http://your_primavera_host:7001/p6ws'
P6_PROJECT_ID   = 'IT00351'   # this is just an example, replace with value appropos to your environment 

#RUN_INTERVAL = 1 #Number of minutes to sleep before doing the data transfer again
RUN_INTERVAL = -1 # a negative interval results in the connector running once and exiting

def build_activity_oid_map()
  activity_object_ids = {}
  activities = @primavera.get_activities(P6_PROJECT_ID)
  activities.each do |activity|
    activity_object_ids[activity[:id]] = activity[:object_id]
  end
  activity_object_ids
end

def update_primavera_activities(rally_entries, activity_object_ids)
  rally_entries.each_pair do |activity_id, hours|
    if activity_object_ids.has_key?(activity_id)
      result = @primavera.update_activity(activity_object_ids[activity_id], hours.to_s)
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
  rally_url = "https://%s/slm" % RALLY_SERVER
  wsapi_version = 1.16
  @rally = RallyConnection.new(RALLY_USERNAME, RALLY_PASSWORD, rally_url, wsapi_version, 
                               RALLY_WORKSPACE, RALLY_PROJECT)
  if !@rally.connect()
    raise "Unable to connect to Rally"
  end
end

def login_to_primavera()
  @primavera = P6Connection.new(P6_USERNAME, P6_PASSWORD, P6_URL, P6_PROJECT_ID)
  if !@primavera.connect()
    raise "Unable to connect to P6 (Primavera)"
  end
end

###################
# MAIN LOOP
###################

while true do
    begin
        login_to_rally()
        login_to_primavera()

        time_entries = @rally.get_time_entries()
        time_entries.each do |te|
          #charges = []
          #te.values.each do |v|
          #  charges << v.hours.to_i
          #end
          charges = te.values.collect {|v| v.hours.to_i}
          time_entry_info = [te.work_product_display_string, te.task_display_string,
                             te.week_start_date.split('T')[0], charges]
          puts "%-18.18s  %-24.24s  week %s hours charged: %s" % time_entry_info
          #time_entry_info = [te.work_product.formatted_i_d, te.work_product_display_string, 
          #                   te.task.formatted_i_d,         te.task_display_string,
          #                   te.week_start_date.split('T')[0], charges]
          #puts "|%s| %-18.18s  |%s| %-24.24s  week %s hours charged: %s" % time_entry_info
        end
        rally_info = @rally.aggregate_time_entries(time_entries)
        log_rally_info(rally_info)
        rally_info.each_pair do |activity_id, hours|
            puts "Hours for Activity #{activity_id}: #{hours}"
        end

        activity_object_ids = build_activity_oid_map()  # id to oid mapping
        puts "there are %d items in the activity_object_ids map" % activity_object_ids.length
        update_primavera_activities(rally_info, activity_object_ids)
        @primavera.disconnect()

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

