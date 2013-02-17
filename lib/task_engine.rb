require 'rubygems'
require 'google/api_client'
require 'launchy'
require 'pry'
require 'encryptor'

# A simple Hash wrapper that includes a tasks instance variable
# @tasks is an array which holds hashes of the tasks
class Tasklist < Hash
  attr_accessor :tasks
end

class TaskEngine

  CLIENT_ID = '843951960730-ugvc3nvoiugblhsk7b1s992o8ao2pu2l.apps.googleusercontent.com'
  CLIENT_SECRET = 'xMeRi5c5HisYLDdULeYCWlG7'
  OAUTH_SCOPE = 'https://www.googleapis.com/auth/tasks'
  REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob'

  Encryptor.default_options.merge!(:key => CLIENT_ID)

  attr_reader :client
  attr_accessor :tasklists

  def initialize
    @tasklists = []

    setup
    authorize
    get_tasklists
    @tasklists.each { |tl|
      get_tasks(tl)
    }
  end

  # Create a new API @client & load the Google Drive API 
  def setup
    @client = Google::APIClient.new(
      :application_name => 'Task Engine',
      :application_version => '0.1' )
    @api = @client.discovered_api('tasks', 'v1')
  end

  # Request authorization
  def authorize
    @client.authorization.client_id = CLIENT_ID
    @client.authorization.client_secret = CLIENT_SECRET
    @client.authorization.scope = OAUTH_SCOPE
    @client.authorization.redirect_uri = REDIRECT_URI

    uri = @client.authorization.authorization_uri

    # Does auth code exist?
    # Or get a new one and exchange it for the access token
    if File.exists?("auth.txt")
      File.open("auth.txt", "r") { |file|
        @client.authorization.refresh_token = file.gets.chomp.decrypt
        @client.authorization.grant_type = 'refresh_token'
        auth = @client.authorization.fetch_access_token!
      }
    else
      Launchy.open(uri)
      $stdout.write  "Enter authorization code: "
      @client.authorization.code = gets.chomp
      auth = @client.authorization.fetch_access_token!
      File.open("auth.txt", "w") { |file|
        file.puts @client.authorization.refresh_token.encrypt
      }
    end
  end

  # Retrieves all the tasklists
  def get_tasklists
    array = @client.execute(@api.tasklists.list).data.to_hash["items"]
    array.each { |h|
      @tasklists.push Tasklist[h]
    }
  end

  # Populates the tasks in any given tasklist
  def get_tasks(tasklist)
    tasklist_id = tasklist["id"]
    tasklist.tasks = @client.execute(
      :api_method => @api.tasks.list,
      :parameters => {:tasklist => tasklist_id}
    ).data.to_hash["items"]
  end

  # Inserts a task into a task list.
  # Tasklist is passed in, but refers to an instance variable
  # of the TaskEngine.
  def insert_task(task, tasklist)
    result = @client.execute(
      :api_method => @api.tasks.insert,
      :body_object => task,
      :parameters => {:tasklist => tasklist["id"]}
    )
    get_tasks(tasklist)
  end

  def delete_task(task, tasklist)
    result = @client.execute(
      :api_method => @api.tasks.delete,
      :parameters => {:tasklist => tasklist["id"], :task => task["id"]}
    )
    get_tasks(tasklist)
    
  end

  def update_task(task, tasklist, update_hash)
    results = @client.execute(
      :api_method => @api.tasks.patch,
      :body_object => update_hash,
      :parameters => {:tasklist => tasklist["id"], :task => task["id"]}
    )
    get_tasks(tasklist)
  end 

end

if $0 == __FILE__
  a = TaskEngine.new
end
