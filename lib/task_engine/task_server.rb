require 'socket'
require_relative '../task_engine'
require_relative 'version.rb'

# Debugging
require 'pry'
require 'pry-debugger'

module TaskEngine

  class AppHelper

    attr_accessor :engine

    def initialize(auth_file)
      @engine = TaskEngine::Engine.new(auth_file)


#      parent = Pathname.new(__FILE__).parent
#      @data_file = Pathname.new(parent + '../../task_data').expand_path
#      if @data_file.exist?
#        File.open(@data_file, "r") { |file|
#          @engine = Marshal.load(file)
#        }
#        Thread.new {
#          @engine.refresh
#        }
#      else
#        @engine = TaskEngine::Engine.new(auth_file)
#        self.serialize_engine
#      end
    end

    def serialize_engine
      File.open(@data_file, "wb") { |file|
        Marshal.dump(@engine, file)
      }
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

  class TaskServer

    def self.run(auth_file)

      selected_tl_index = 0
      host = '0.0.0.0'
      port = 4481

      puts "Starting task_server, version: #{VERSION}"
      app_helper = AppHelper.new(auth_file)
      puts "task_engine running"
      puts "Listening on #{host} port #{port}"

      listener = TCPServer.new(host, port)

      Socket.accept_loop(listener) do |connection, _|
        input = connection.gets.chomp
        args = input.split(', ')
        command = args[0]
        case command
        when "a_test" then
          connection.puts "This is a test"
        when "TERM" then
          connection.close
          break
        when "EXIT" then
          connection.close
        when "get_tasklist_titles" then
          connection.puts app_helper.get_tasklist_titles
        when "get_task_titles" then
          tl_index = (args[1] && args[1].to_i) || selected_tl_index
          connection.puts app_helper.get_task_titles(tl_index)
        when "select_tasklist" then
          selected_tl_index = args[1].to_i
          connection.puts app_helper.get_tasklist_title(selected_tl_index)
        when "get_selected_tasklist" then
          connection.puts app_helper.get_tasklist_title(selected_tl_index)
        when "get_task_lines" then
          tl_index = (args[1] && args[1].to_i) || selected_tl_index
          connection.puts app_helper.get_task_lines(tl_index)
        when "update_at_index" then
          index = args[1]
        when "toggle_status" then
          task_index = args[1].to_i
          tl_index = (args[2] && args[2].to_i) || selected_tl_index
          result = app_helper.toggle_status(task_index, tl_index)
          connection.puts app_helper.get_task_lines(tl_index)
        when "update_task_title" then
          # REQUIRES a tasklist index
          task_index = args[1].to_i
          tl_index = args[2].to_i 
          new_title = args[3]
          app_helper.update_at_index(
            task_index,
            tl_index,
            {"title" => new_title}
          )
          connection.puts app_helper.get_task_titles(tl_index)
        when "refresh" then
          app_helper.engine.refresh()
          connection.puts "Refreshing cache"
        else
          connection.puts("Unknown command")
        end
        connection.close
      end  

    end
  end
end

