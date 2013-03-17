require 'drb/drb'
require_relative '../task_engine'
require_relative 'version.rb'

# Debugging
require 'pry'
require 'pry-debugger'

module TaskEngine

  class TaskServer

    attr_accessor :engine

    def self.start(auth_file)
      server_uri="druby://localhost:8787"

      # The object that handles requests on the server
      front_object=self.new(auth_file)

      $SAFE = 1   # disable eval() and friends

      DRb.start_service(server_uri, front_object)
      # Wait for the drb server thread to finish before exiting.
      DRb.thread.join
    end  

    def initialize(auth_file)
      puts "task_server version: #{VERSION}"
      puts "Initializing task_server"
      parent = Pathname.new(__FILE__).parent
      @data_file = Pathname.new(parent + '../../task_data').expand_path
      if @data_file.exist?
        File.open(@data_file, "r") { |file|
          @engine = Marshal.load(file)
        }
        Thread.new {
          @engine.refresh
        }
      else
        @engine = TaskEngine::Engine.new(auth_file)
        self.serialize_engine
      end
      puts "task_engine running"
    end

    def serialize_engine
      File.open(@data_file, "wb") { |file|
        Marshal.dump(@engine, file)
      }
    end

    def alive?()
      return true
    end

    def refresh()
      @engine.refresh
      return "Refreshing cache"
    end

    def get_tasklist_titles
      return @engine.tasklists.map { |x| x["title"] }
    end

    def get_tasklist_title(selected_tl_index)
      return @engine.tasklists[selected_tl_index]["title"]
    end

    def get_task_titles(index)
      return @engine.tasklists[index].tasks.map { |x| x["title"] }
    end

    def get_task_lines(index)
      return @engine.tasklists[index].tasks.map { |x| 
        if x["status"] == "needsAction"
          status_string = "[ ]"
        else x["status"] == "completed"
          status_string = "[X]"
        end
        "#{status_string} #{x["title"]}" }
    end

    def update_at_index(task_index, tasklist_index, update_hash)
      tasklist = @engine.tasklists[tasklist_index]
      task = tasklist.tasks[task_index]
      @engine.update_task(task, tasklist, update_hash)
    end

    def toggle_status(task_index, tasklist_index)
      tasklist = @engine.tasklists[tasklist_index]
      task = tasklist.tasks[task_index]
      update_hash = case task["status"]
                   when "needsAction" then {"status" => "completed"}
                   when "completed" then {"status" => "needsAction",
                                          "completed" => nil}
                   end
      task.merge!(update_hash)
      update_thread = Thread.new {
        @engine.update_task(task, tasklist, update_hash)
      }
    end

    def task_at_index(task_index, tasklist_index)
      task = @engine.tasklists[tasklist_index].tasks[task_index]
      return task
    end

  end

end

