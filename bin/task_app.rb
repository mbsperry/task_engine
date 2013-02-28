# TODO:
#   - Remove vieditable include
#   - Build my own bindings for adding, editing and deleting tasks
#   - Add methods for sorting tasks
#   - Add methods for showing task due dates.
#       Maybe as a sub-list?
#   - Add binding for showing popup with task notes


require 'rbcurse/core/util/app'
require_relative '../lib/task_engine'

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

  def task_at_index(task_index, tasklist_index)
    task = @engine.tasklists[tasklist_index].tasks[task_index]
    return task
  end

end

if $0 == __FILE__ then

  app_helper = AppHelper.new
  App.new do
    ww = FFI::NCurses.COLS-0
    flow :width => ww, :margin_top => 1, :height => FFI::NCurses.LINES-2 do

      def refresh_tasks(task_lb, tasklist_lb, app_helper)
        curr_index = task_lb.current_index
        task_lb.list(app_helper.get_task_titles(tasklist_lb.current_index))
        task_lb.current_index = curr_index
      end

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
      end #stack

      @task_lb.bind_key(32) { |t|
        app_helper.toggle_status(t.current_index, tasklist_lb.current_index)
        curr_index = t.current_index
        refresh_tasks(t, tasklist_lb, app_helper) 
      } #bind_key(spacebar)

      @task_lb.bind_key(?e, "Edit Task") { |t|
        # TODO: What happens if "Cancel" is chosen? 
        cur_task = 
          app_helper.task_at_index(t.current_index, tasklist_lb.current_index) 
        cur_title = cur_task["title"]
        new_title = get_string("Edit Task Title", :default => cur_title)
        app_helper.update_at_index(
          t.current_index,
          tasklist_lb.current_index,
          {"title" => new_title}
        )
        refresh_tasks(@task_lb, tasklist_lb, app_helper) 
      } #bind_key(e)

    end #flow
  end #app
end #executable
