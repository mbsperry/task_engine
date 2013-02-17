require 'test/unit'
require_relative '../bin/task_app.rb'

class TestApp < Test::Unit::TestCase

  @@app_help = AppHelper.new

  def test_get_tasklist_titles
    titles = @@app_help.get_tasklist_titles()
    assert_instance_of(Array, titles)
    assert_equal(true, titles.length > 0)
    assert_instance_of(String, titles[0])
  end

  def test_get_task_titles
    task_titles = @@app_help.get_task_titles(2)
    assert_match(/\[.\] \w+/, task_titles[0])
  end

  def test_update_task_title
    old_task_title = @@app_help.engine.tasklists[2].tasks[0]["title"]
    tasklist = @@app_help.engine.tasklists[2]
    task = @@app_help.engine.tasklists[2].tasks[0]
    update_hash = { "title" => old_task_title + "OLD" }
    @@app_help.engine.update_task(task, tasklist, update_hash)
    new_task_title = @@app_help.engine.tasklists[2].tasks[0]["title"]
    assert_equal(old_task_title + "OLD", new_task_title) 
    
  end

end

