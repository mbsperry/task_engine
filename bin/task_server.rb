#!/usr/bin/env ruby

require 'socket'
require_relative '../lib/task_engine'

class AppHelper

  attr_accessor :engine

  def initialize(auth_file)
    @engine = TaskEngine::Engine.new(auth_file)
  end

  def get_tasklist_titles
    return @engine.tasklists.map { |x| x["title"] }
  end

  def get_tasklist_title(tl_index)
    return @engine.tasklists[tl_index]["title"]
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
    result = @engine.update_task(task, tasklist, update_hash)
  end

  def task_at_index(task_index, tasklist_index)
    task = @engine.tasklists[tasklist_index].tasks[task_index]
    return task
  end

end

def task_server_main(auth_file)

  app_helper = AppHelper.new(auth_file)
  tl_index = 0

  listener = TCPServer.new('0.0.0.0', 4481)

  Socket.accept_loop(listener) do |connection, _|
    input = connection.gets.chomp
    args = input.split
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
      connection.puts app_helper.get_task_titles(tl_index)
    when "select_tasklist" then
      tl_index = args[1].to_i
      connection.puts app_helper.get_tasklist_title(tl_index)
    when "get_task_lines" then
      index = args[1].to_i || tl_index
      connection.puts app_helper.get_task_lines(index)
    when "update_at_index" then
      index = args[1]
    when "toggle_status" then
      index = args[1]
    else
      connection.puts("Unknown command")
    end
    connection.close
  end  

end

if $0 == __FILE__ then
  auth_file = Pathname.new(Pathname.new(__FILE__).parent + "../auth.txt")
  task_server_main(auth_file)
end
