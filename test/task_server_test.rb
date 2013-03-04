require 'test/unit'
require 'socket'
require 'pry'

require_relative '../bin/task_server.rb'
auth_file = (Pathname.new(__FILE__) + "../auth.txt").expand_path


$server_thread = Thread.new {
  task_server_main(auth_file)
}

class TestTaskServer < Test::Unit::TestCase

  def setup
    @default_tl = 3
  end

  def communicate(message)
    tries ||= 4
    result = []

    s = TCPSocket.new("", 4481)
    s.puts message
    response = select([s],nil,nil, 1)

    for input in response[0] do
      if input == s then
        while line = s.gets
          result.push line
        end
      else
        puts "Connection timeout"
      end
    end

    return result
  rescue
    sleep(3)
    retry unless (tries -=1).zero?
    raise "Connection refused"
  end

  def test_a_test
    result = self.communicate("a_test")
    assert_equal(String, result[0].class)
    assert(result[0].length > 0, "Should return a string longer than 0")
  end

  def test_get_tasklist_titles
    result = self.communicate("get_tasklist_titles")
    assert(result.length > 0, "Should have more than 0 tasklists")
    assert_equal(String, result[0].class)
    assert(result[0].length > 0, "Tasklist name should be longer than 0")
  end

  def test_get_task_titles
    result = self.communicate("get_task_titles #{@default_tl}")
    assert(result.length > 0, "Should have many tasks")
    assert_equal(String, result[0].class)
    assert_equal(true, result[0].length > 0)
  end

  def test_select_tasklist
    result = self.communicate("select_tasklist #{@default_tl}")
    assert_equal("Test", result[0].chomp)
  end

  def test_get_task_lines
    result = self.communicate("get_task_lines")
    assert_match(/\[.\] \w+/, result[0])
    result2 = self.communicate("get_task_lines 1")
    assert_not_equal(result2[0], result[0])
    assert_match(/\[.\] \w+/, result2[0])
  end
    
end

