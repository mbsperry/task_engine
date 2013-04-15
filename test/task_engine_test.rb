require 'test/unit'
require_relative '../lib/task_engine'
require 'pry'
require 'pry-debugger'

# TODO:
# Consolidate new and delete tasks, make sure to reset
# State at end of test


class TestTaskEngine < Test::Unit::TestCase

  AUTH_FILE = Pathname.new('~/.task_server/gt').expand_path
  @@engine = TaskEngine::Engine.new(AUTH_FILE)

  def setup 
    @@engine.refresh
    @testlist_index = @@engine.tasklists.index { |x| x["title"] == "Test" }     # use the testing tasklist
    @default_tl = @@engine.tasklists[@testlist_index]
    @default_task = @default_tl.tasks[0]
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

  def test_sort_tasks
    @@engine.sort_tasks(@default_tl)
    sorted = true
    in_order = false
    @default_tl.tasks.each do |task|
      if task["status"] == "completed" && in_order == false
        in_order = true
      elsif (task["status"] != "completed") && in_order == true
        sorted = false
      end
    end
    assert_equal(true, sorted)
  end

  def test_insert_task_and_delete_task
    task_count = @@engine.tasklists[@testlist_index].tasks.size
    new_task = {"title" => "newtask"}
    tl = @@engine.tasklists[@testlist_index]
    @@engine.insert_task(new_task, tl)
    @@engine.refresh
    assert_equal(task_count+1,@@engine.tasklists[@testlist_index].tasks.size)
    assert_equal(true, @@engine.tasklists[@testlist_index].tasks.first.key?("title"))
    assert_equal(true, @@engine.tasklists[@testlist_index].tasks.first["title"].length > 0)
    new_task = @@engine.tasklists[@testlist_index].tasks[0]
    @@engine.delete_task(new_task, tl)
    @@engine.refresh
    assert_equal(task_count,@@engine.tasklists[@testlist_index].tasks.size)
  end

  def test_update_task
    tl = @@engine.tasklists[@testlist_index]
    task = tl.tasks[0]
    old_title = task["title"]
    update = {"title" => old_title + "OLD"}
    @@engine.update_task(task, tl, update)
    @@engine.refresh
    updated_task = @@engine.tasklists[@testlist_index].tasks.select do |t| 
      t["id"] == task["id"]
    end[0]
    assert_equal(old_title + "OLD", updated_task["title"])
    @@engine.update_task(updated_task, tl, {"title" => old_title})
  end

end
