require 'test/unit'
require 'socket'
require 'pry'
require 'pry-debugger'

require_relative '../lib/task_engine/task_server.rb'
auth_file = (Pathname.new(__FILE__) + "../auth.txt").expand_path


$server_thread = Thread.new {
  TaskEngine::TaskServer.run(auth_file)
}

def server_alive?
  tries ||= 4
  s = TCPSocket.new("", 4481)
  s.puts "a_test"
  s.gets
  s.close
rescue
  unless (tries-=1).zero?
    sleep(3)
    retry
  else
    raise "Connection Failed"
  end
end

server_alive?()

class TestTaskServer < Test::Unit::TestCase

  def setup
    @default_tl = 3
  end

  def communicate(message)
    s = TCPSocket.new("", 4481)
    s.puts message
    response = select([s],nil,nil, 3)

    if response[0][0] == s 
      while line = s.gets
        result ||= []
        result.push line
      end
    elsif response == nil
      raise "Connection timeout"
    end

    result || ["No response"]
  end

  def test_a_test
    result = self.communicate("a_test")
    assert_equal(String, result[0].class)
    assert(result[0].length > 0, "Should return a string longer than 0")
  end

  def test_select_tasklist
    result = self.communicate("select_tasklist, #{@default_tl}")
    assert_equal("Test", result[0].chomp)
    result2 = self.communicate("get_selected_tasklist")
    assert_equal("Test", result2[0].chomp)
  end

  def test_get_tasklist_titles
    result = self.communicate("get_tasklist_titles")
    assert(result.length > 0, "Should have more than 0 tasklists")
    assert_equal(String, result[0].class)
    assert(result[0].length > 0, "Tasklist name should be longer than 0")
  end

  def test_get_task_titles
    result = self.communicate("get_task_titles, #{@default_tl}")
    assert(result.length > 0, "Should have many tasks")
    assert_equal(String, result[0].class)
    assert_equal(true, result[0].length > 0)
  end

  def test_get_task_lines
    result = self.communicate("get_task_lines")
    assert_match(/\[.\] \w+/, result[0])
    result2 = self.communicate("get_task_lines, 1")
    assert_not_equal(result2[0], result[0])
    assert_match(/\[.\] \w+/, result2[0])
  end

  def test_toggle_status
    pre_result = self.communicate("get_task_lines, #{@default_tl}")
    post_result = self.communicate("toggle_status, 1, 3")
    assert(post_result.length > 1, "Should have returned many task lines")
    assert_match(/\[.\] \w+/, post_result[1])
    assert_not_equal(pre_result[1], post_result[1])
  end

  def test_update_task_title
    refreshed = self.communicate("refresh")[0].chomp
    assert_equal("Refreshing cache", refreshed)
    pre_result = self.communicate("get_task_titles, #{@default_tl}")
    old_title = pre_result[0].chomp
    new_title = old_title + " changed"
    post_result = self.communicate("update_task_title, 0, 3, #{new_title}")
    assert_equal(new_title, post_result[0].chomp)
    assert_not_equal(pre_result[0], post_result[0])
    self.communicate("update_task_title, 0, 3, #{old_title}")
  end
    

end

