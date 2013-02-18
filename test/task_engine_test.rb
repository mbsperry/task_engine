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

  def test_insert_task
    task_count = @@engine.tasklists[2].tasks.size
    new_task = {"title" => "Fifth"}
    tl = @@engine.tasklists[2]
    @@engine.insert_task(new_task, tl)
    assert_equal(task_count+1,@@engine.tasklists[2].tasks.size)
    assert_equal(true, @@engine.tasklists[2].tasks.first.key?("title"))
    assert_equal(true, @@engine.tasklists[2].tasks.first["title"].length > 0)
  end

  def test_delete_task
    tl = @@engine.tasklists[2]
    task_count = tl.tasks.size
    old_task = tl.tasks[0] 
    @@engine.delete_task(old_task, tl)
    assert_equal(task_count-1,@@engine.tasklists[2].tasks.size)
  end

  def test_update_task
    tl = @@engine.tasklists[2]
    task = tl.tasks[0]
    old_title = task["title"]
    update = {"title" => old_title + "OLD"}
    updated_task = @@engine.update_task(task, tl, update)
    assert_equal(old_title + "OLD", updated_task["title"])
    @@engine.update_task(updated_task, tl, {"title" => old_title})
  end

end
