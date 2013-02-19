# TODO:
#   - Remove vieditable include
#   - Build my own bindings for adding, editing and deleting tasks
#   - Add methods for sorting tasks
#   - Add methods for showing task due dates.
#       Maybe as a sub-list?
#   - Add binding for showing popup with task notes


require 'rbcurse/core/util/app'
require 'rbcurse/core/include/vieditable'
require_relative '../lib/task_engine'

class RubyCurses::List
  include ViEditable
end

class AppHelper

  attr_accessor :engine

  def initialize
    @engine = TaskEngine.new
  end

  def get_tasklist_titles
    return @engine.tasklists.map { |x| x["title"] }
  end

  def get_task_titles(index)
    return @engine.tasklists[index].tasks.map { |x| 
      if x["status"] == "needsAction"
        status_string = "[ ]"
      else x["status"] == "completed"
        status_string = "[X]"
      end
      "#{status_string} #{x["title"]}" }
  end

  def update_at_index(task_index, tasklist_index, update_hash)
    tasklist = @engine.tasklists[tasklist_index]
    task = tasklist.tasks[task_index]
    @engine.update_task(task, tasklist, update_hash)
  end

  def toggle_status(task_index, tasklist_index)
    tasklist = @engine.tasklists[tasklist_index]
    task = tasklist.tasks[task_index]
    update_hash = case task["status"]
                 when "needsAction" then {"status" => "completed"}
                 when "completed" then {"status" => "needsAction",
                                        "completed" => nil}
                 end
    result = @engine.update_task(task, tasklist, update_hash)
  end

end

if $0 == __FILE__ then

  app_helper = AppHelper.new
  App.new do
    ww = FFI::NCurses.COLS-0
    flow :width => ww, :margin_top => 1, :height => FFI::NCurses.LINES-2 do

      tasklist_lb = listbox(:list => app_helper.get_tasklist_titles, 
                            :title => "[ Tasklists ]", 
                            :width_pc => "30"
                           )
      tasklist_lb.bind_key(?l, "Select List") do |t|
        @task_lb.list(app_helper.get_task_titles(tasklist_lb.current_index))
      end #bind_key(l)

      stack :margin_top => 0, :width_pc => ww-20 do
        @task_lb = listbox( :list => app_helper.get_task_titles(0), 
          :title => "[ todos ]", 
          :name => "tasks", 
          :row => 1, :height => FFI::NCurses.LINES-4 )
        @task_lb.vieditable_init_listbox
      end #stack

      @task_lb.bind_key(32) { |t|
        app_helper.toggle_status(t.current_index, tasklist_lb.current_index)
        curr_index = t.current_index
        @task_lb.list(app_helper.get_task_titles(tasklist_lb.current_index))
        @task_lb.current_index = curr_index
      }
      @task_lb.bind_key(?e, "Edit Task") { |t|
      } #bind_key(e)

    end #flow
  end #app
end #executable
