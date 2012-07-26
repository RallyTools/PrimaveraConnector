require "rspec"
require "rally_connection"

#ENV['http_proxy'] = "http://127.0.0.1:8888"

describe "The RallyConnection" do

  USERNAME = 'foobakus@largecorp.com'  # adjust to your environment
  PASSWORD = 'SSSSSSecretz!'           # ditto
  BASE_URL = 'https://rally1.rallydev.com/slm' # adjust to your environment
  WS_VERSION = '1.16'
  WORKSPACE = 'Bongo'   # adjust to your environment
  PROJECT   = 'Boards'  # adjust to your environment

  before(:all) do
    @rally_connection = RallyConnection.new(USERNAME,  PASSWORD, 
                                            BASE_URL,  WS_VERSION, 
                                            WORKSPACE, PROJECT)
  end

  it "should connect to Rally" do
    @rally_connection.connect().should == true
  end

  it "should find the workspace" do
    @rally_connection.connect()
    @rally_connection.workspace.name.should == WORKSPACE
  end

  it "should find the project" do
    @rally_connection.connect()
    @rally_connection.project.name.should == PROJECT
  end

  it "should find time entries" do
    @rally_connection.connect()
    entries = @rally_connection.get_time_entries()
    entries.total_result_count.should == 16
    puts "Found #{entries.total_result_count} matching time entries"
  end

  it "should find time values" do
    @rally_connection.connect()
    values = @rally_connection.get_time_values()
    values.total_result_count.should == 20
    puts "Found #{values.total_result_count} matching time values:"
  end

  it "should find aggregate time entries" do
    @rally_connection.connect()
    entries = @rally_connection.get_time_entries()
    result = @rally_connection.aggregate_time_entries(entries)
    #puts "Result has #{result.size} entries"
    #result.each_pair {|key, value| puts "#{key} is #{value}" }
    result["EC1220"].should == 13.0
  end
end
