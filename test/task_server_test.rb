require 'test/unit'
require 'drb/drb'
require 'pry'
require 'pry-debugger'

require_relative '../lib/task_engine/task_server.rb'

SERVER_URI="druby://localhost:8787"

server_thread = Thread.new {
  server = TaskEngine::TaskServer.new(false)
  server.start_server
}

puts "Starting DRb"
DRb.start_service("druby://localhost:0")

$task_server = DRbObject.new_with_uri(SERVER_URI)

puts "Testing for connectivity"
def server_alive?
  tries ||= 4000
  unless $task_server.engine.connected?
    sleep 1
  end
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
    # use the testing tasklist
    # Let previous tests finish uploading to server before starting the next batch
    while $task_server.working? == "run"
      sleep 1
    end

    @default_tl = 3
    #@default_tl = $task_server.get_tasklist_titles.index { |s| s == "Test" }     
    #assert_equal("Test", $task_server.get_tasklist_titles[@default_tl])
  end

  def test_get_tasklist_titles
    result = $task_server.get_tasklist_titles
    assert(result.length > 0, "Should have more than 0 tasklists")
    assert_equal(String, result[0].class)
    assert(result[0].length > 0, "Tasklist name should be longer than 0")
  end

  def test_get_task_titles
    result = $task_server.get_task_titles(@default_tl) 
    assert(result.length > 0, "Should have many tasks")
    assert_equal(String, result[0].class)
    assert_equal(true, result[0].length > 0)
  end

  def test_get_task_lines
    result = $task_server.get_task_lines(@default_tl) 
    assert_match(/\[.\] \w+/, result[0])
    result2 = $task_server.get_task_lines(1) 
    assert_not_equal(result2[0], result[0])
    assert_match(/\[.\] \w+/, result2[0])
  end

  def test_toggle_status
    pre_result = $task_server.get_task_lines(@default_tl)
    $task_server.toggle_status(1,@default_tl)
    post_result = $task_server.get_task_lines(@default_tl) 
    assert_not_equal(pre_result[1], post_result[1])
  end

  def test_update_task_title
    pre_result = $task_server.get_task_titles(@default_tl)
    old_title = pre_result[0]
    new_title = old_title + " changed"

    $task_server.update_at_index(0,@default_tl,{"title" => new_title})
    post_result = $task_server.get_task_titles(@default_tl)

    assert_equal(new_title, post_result[0])
    assert_not_equal(pre_result[0], post_result[0])

    $task_server.update_at_index(0,@default_tl,{"title" => old_title})
  end

  def test_new_task_and_delete_task
    t_list = $task_server.get_task_titles(@default_tl)
    $task_server.new_task("new task", @default_tl)
    post_list = $task_server.get_task_titles(@default_tl)
    assert_equal(t_list.length + 1, post_list.length)
    assert(post_list.include?("new task"))

    # Test delete_task
    $task_server.delete_task(0, @default_tl)
    after_del_list = $task_server.get_task_titles(@default_tl) 
    assert_equal(t_list.length, after_del_list.length)
  end

end

