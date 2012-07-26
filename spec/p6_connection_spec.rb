require "rspec"
require "p6_connection"

#ENV['http_proxy'] = "http://127.0.0.1:8888"

describe "The P6 Connection" do

  USERNAME = 'admin'
  PASSWORD = 'SSSSSecretz!'                 # adjust to your environment
  BASE_URL = 'http://192.168.2.1:7001/p6ws' # ditto
  PROJECT_ID = 'EC00501'                    # ditto

  before(:all) do
    @p6_connection = P6Connection.new(USERNAME, PASSWORD, BASE_URL, PROJECT_ID)
  end

  after(:each) do
    @p6_connection.disconnect()
  end

  it "should connect to P6" do
    @p6_connection.connect().should be_true
  end

  it "should get activities" do
    @p6_connection.connect().should be_true
    activities = @p6_connection.get_activities(PROJECT_ID)
    activities.each do |activity|
      puts activity[:object_id] + " " + activity[:id] + " " + activity[:actual_labor_units]
    end
  end

  it "should update an activity" do
    @p6_connection.connect().should be_true
    response = @p6_connection.update_activity('95439', '120')
    response.should be_true
  end

end
