require 'test/unit'
require_relative '../bin/task_app.rb'

class TestApp < Test::Unit::TestCase

  @@app_help = AppHelper.new

  def setup 
    @tasklist_index = 2       # Use the testing tasklist
    @default_tl = @@app_help.engine.tasklists[2]
    @default_task = @default_tl.tasks[0]
  end

  def test_get_tasklist_titles
    titles = @@app_help.get_tasklist_titles()
    assert_instance_of(Array, titles)
    assert_equal(true, titles.length > 0)
    assert_instance_of(String, titles[0])
  end

  def test_get_task_titles
    task_titles = @@app_help.get_task_titles(@tasklist_index)
    assert_match(/\[.\] \w+/, task_titles[0])
  end

  def test_update_at_index
    old_title = @@app_help.engine.tasklists[@tasklist_index].tasks[0]["title"]
    update_hash = {"title" => old_title + "OLD"}
    updated_task = @@app_help.update_at_index(0,@tasklist_index,update_hash)
    assert_equal(old_title + "OLD", updated_task["title"])
    @@app_help.update_at_index(0,@tasklist_index,{"title" => old_title})
  end

  def test_toggle_status
    old_status = @default_task["status"]
    @@app_help.toggle_status(0, @tasklist_index)
    assert_not_equal(old_status,
                     @@app_help.engine.tasklists[@tasklist_index].tasks[0]["status"])
  end


end

