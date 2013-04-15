require 'drb/drb'
require 'thread'

require_relative '../task_engine'
require_relative 'version.rb'

# Debugging
require 'pry'
require 'pry-debugger'

S_URI="druby://localhost:8787"
DATA_FOLDER = Pathname.new('~/.task_server/').expand_path

module TaskEngine

  # Thanks to http://burgestrand.se/code/ruby-thread-pool/ for
  # the excellent thread pool idea. This is a much simplified version b/c
  # I really only need one worker.
  class Worker

    def initialize(&refresh_block)
      @queue = Queue.new
      @refreshed = true

      @thread = Thread.new do
        catch(:exit) do
          loop do
            job, args = @queue.pop
            job.call(*args)
            if @queue.length == 0 && @refreshed == false
              refresh_block.call
              @refreshed = true
            end
          end
        end
      end
    end

    def schedule(*args, &block)
      @queue.push Proc.new { @refreshed = false }
      @queue.push [block, args]
    end

    def shutdown
      schedule { throw :exit }
      @thread.join
    end

    def status
      @refreshed ? "sleep" : "working"
    end

    def queue_length
      @queue.length
    end

  end

  class TaskServer

    attr_accessor :engine

    def initialize(serialize)
      puts "task_server version: #{VERSION}"
      puts "Initializing task_server"

      unless DATA_FOLDER.exist?
        Dir.mkdir(DATA_FOLDER, 0700)
      end

      auth_file = DATA_FOLDER + 'gt'
      @data_file = Pathname.new(DATA_FOLDER + 'task_data').expand_path

      @worker = Worker.new { @engine.refresh }
      if serialize
        initialize_with_serialization(auth_file)
      else
        @engine = Engine.new(auth_file)
        @no_serialize = true
      end

      #@engine = TaskEngine::Engine.new(auth_file)
      puts "task_engine running"
    end

    # Allows for serialization to disk.
    def initialize_with_serialization(auth_file)
      if @data_file.exist?
        File.open(@data_file, "r") do |file|
          @engine = Marshal.load(file)
        end 
        @worker.schedule { @engine.refresh }
      else
        @engine = Engine.new(auth_file)
        serialize_engine()
      end
    end

    def start_server
      # The object that handles requests on the server
      front_object=self

      $SAFE = 0   # disable eval() and friends

      DRb.start_service(S_URI, front_object)
      # Wait for the drb server thread to finish before exiting.
      trap("INT") do
        puts "Shutting down"
        @worker.shutdown
        Thread.kill(DRb.thread)
      end
      DRb.thread.join
    end

    # Returns "sleep" or "working"
    def working?
      @worker.status
    end

    def serialize_engine
      File.open(@data_file, "wb", 0600) do |file|
        Marshal.dump(@engine, file)
      end 
    end

    def refresh()
      serialize_engine() unless no_serialize 
      @worker.schedule { @engine.refresh }
    end

    def get_tasklist_titles
      @engine.tasklists.map { |x| x["title"] }
    end

    def get_tasklist_title(selected_tl_index)
      @engine.tasklists[selected_tl_index]["title"]
    end

    def get_task_titles(index)
      @engine.tasklists[index].tasks.map { |x| x["title"] }
    end

    def get_task_lines(index)
      @engine.tasklists[index].tasks.map do |x| 
        if x["status"] == "completed"
          status_string = "[X]"
        else
          status_string = "[ ]"
        end
        "#{status_string} #{x["title"]}" 
      end
    end

    def sort_tasks(tl_index)
      tasklist = @engine.tasklists[tl_index]
      @engine.sort_tasks(tasklist)
    end

    def update_at_index(task_index, tasklist_index, update_hash)
      tasklist = @engine.tasklists[tasklist_index]
      task = tasklist.tasks[task_index]
      task.merge!(update_hash)
      @worker.schedule do 
        @engine.update_task(task, tasklist, update_hash)
      end 
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
      @worker.schedule do
        @engine.update_task(task, tasklist, update_hash)
      end 
    end

    def task_at_index(task_index, tasklist_index)
      task = @engine.tasklists[tasklist_index].tasks[task_index]
      return task
    end

    def new_task(task_name, tl_index)
      tasklist = @engine.tasklists[tl_index]
      new_task = { "title" => task_name }
      tasklist.tasks.unshift new_task
      @worker.schedule do
        result = @engine.insert_task(new_task, tasklist)
      end 
    end

    def delete_task(task_index, tl_index)
      tasklist = @engine.tasklists[tl_index]
      task = tasklist.tasks[task_index]
      tasklist.tasks.delete_at(task_index)
      @worker.schedule do
        result = @engine.delete_task(task, tasklist)
      end 
    end

  end

end

