#!/usr/bin/env ruby

require 'drb/drb'
#require 'pry'
#require 'pry-debugger'
require_relative 'task_server.rb'


def test_io
  s = TCPSocket.new("", 4481)
  s.puts "TASKLIST 1"
  str = s.recv( 100 )
  puts str
  s.close
end

def create_loop
  loop do
    exit_flag = false
    begin
      s = TCPSocket.new('0.0.0.0', 4481)
    rescue
      retry
    end
    puts "---------------------------"
    puts "task_server running"
    print ">>> "
    result = select([s, STDIN], nil, nil)

    for input in result[0]
      if input == s then
        puts "input"
        puts s.recv(100)
      elsif input == STDIN
        i = STDIN.gets
        if i.chomp == "quit"
          exit_flag = true 
          break
        else
          s.puts(i)
          while line = s.gets
            puts line.chop
          end
        end
      end
    end

    if exit_flag == true then
      break
    end

  end
end

auth_file = Pathname.new(Pathname.new(__FILE__).parent + "../../auth.txt")
# puts "Waiting for task_server..."
# puts "---------------------------"
# t_server_thread = Thread.new {
#   TaskEngine::TaskServer.run(auth_file.expand_path)
# }
# 
# create_loop

t_server_thread = Thread.new {
  TaskEngine::TaskServer.start(auth_file)
} 

SERVER_URI="druby://localhost:8787"

begin
  tries ||= 4
  DRb.start_service("druby://localhost:0")
  task_server = DRbObject.new_with_uri(SERVER_URI)
  puts task_server.get_task_lines(3)
rescue
  if (tries-=1)
    sleep 3
    retry
  end
end
