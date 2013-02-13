require 'test/unit'
require_relative '../lib/task_engine'

class TestTaskEngine < Test::Unit::TestCase

  @@engine = TaskEngine.new

  def test_get_tasklists
    assert_equal(true, @@engine.tasklists.is_a?(Array)) 
    assert_equal(true, @@engine.tasklists[0].is_a?(Hash))
    assert_equal(true, @@engine.tasklists[0].key?("title"))
  end

  def test_list_tasks
    assert_equal(Array, @@engine.tasklists[0].tasks.class)
    assert_equal(Hash, @@engine.tasklists[0].tasks[0].class)
    assert_equal(true, @@engine.tasklists[0].tasks[0].key?("title"))
  end

end
