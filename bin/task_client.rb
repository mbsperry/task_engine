#!/usr/bin/env ruby

require 'socket'
require 'daemons'
require 'pry'
require_relative 'task_server'


def test_io
  s = TCPSocket.new("", 4481)
  s.puts "TASKLIST 1"
  str = s.recv( 100 )
  puts str
  s.close
end

def create_loop
  print "Say when:"
  gets
  loop do
    exit_flag = false
    s = TCPSocket.new('0.0.0.0', 4481)
    result = select([s, STDIN], nil, nil)

    for input in result[0]
      if input == s then
        puts "input"
        puts s.recv(100)
      elsif input == STDIN
        i = STDIN.gets
        if i.chomp == "EXIT"
          exit_flag = true 
          s.puts("EXIT")
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
      s.close
      break
    end

  end
end

auth_file = Pathname.new(Pathname.new(__FILE__).parent + "../auth.txt")
t_server = fork {
  task_server_main(auth_file.expand_path)
}
binding.pry

create_loop
