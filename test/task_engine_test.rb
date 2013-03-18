require 'test/unit'
require_relative '../lib/task_engine'

# Development
require 'pry'
require 'pry-debugger'

class TestTaskEngine < Test::Unit::TestCase

  @@first_time = true

  def first_setup()
    supervisor = TaskEngine::Engine.supervise_as :eng 
    @@engine = Celluloid::Actor[:eng]
  end

  def setup 
    first_setup() if @@first_time == true
    @testlist_index = @@engine.tasklists.index { |x| x["title"] == "Test" }     # use the testing tasklist
    @default_tl = @@engine.tasklists[@testlist_index]
    @default_task = @default_tl.tasks[0]
    @@first_time = false
  end

  def test_get_tasklists
    assert_equal(true, @@engine.tasklists.is_a?(Array)) 
    assert_equal(true, @@engine.tasklists[@testlist_index].is_a?(Hash))
    assert_equal(true, @@engine.tasklists[@testlist_index].key?("title"))
  end

  def test_list_tasks
    assert_equal(Array, @@engine.tasklists[@testlist_index].tasks.class)
    assert_equal(Hash, @@engine.tasklists[@testlist_index].tasks[0].class)
    assert_equal(true, @@engine.tasklists[@testlist_index].tasks[0].key?("title"))
  end

  def test_insert_task
    task_count = @@engine.tasklists[@testlist_index].tasks.size
    new_task = {"title" => "Fifth"}
    tl = @@engine.tasklists[@testlist_index]
    @@engine.insert_task(new_task, tl)
    assert_equal(task_count+1,@@engine.tasklists[@testlist_index].tasks.size)
    assert_equal(true, @@engine.tasklists[@testlist_index].tasks.first.key?("title"))
    assert_equal(true, @@engine.tasklists[@testlist_index].tasks.first["title"].length > 0)
  end

  def test_delete_task
    tl = @@engine.tasklists[@testlist_index]
    task_count = tl.tasks.size
    old_task = tl.tasks[0] 
    @@engine.delete_task(old_task, tl)
    assert_equal(task_count-1,@@engine.tasklists[@testlist_index].tasks.size)
  end

  def test_update_task
    tl = @@engine.tasklists[@testlist_index]
    task = tl.tasks[0]
    old_title = task["title"]
    update = {"title" => old_title + "OLD"}
    updated_task = @@engine.update_task(task, tl, update)
    assert_equal(old_title + "OLD", updated_task["title"])
    @@engine.update_task(updated_task, tl, {"title" => old_title})
  end

end
