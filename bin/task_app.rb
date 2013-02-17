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
end

if $0 == __FILE__ then

  app_helper = AppHelper.new
  App.new do
    ww = FFI::NCurses.COLS-0
    flow :width => ww, :margin_top => 1, :height => FFI::NCurses.LINES-2 do

      tasklist_lb = listbox :list => app_helper.get_tasklist_titles, :title => "[ Tasklists ]",
        :width_pc => "30"
      tasklist_lb.bind_key(?l, "Select List") do |t|
        @task_lb.remove_all
        l = app_helper.get_task_titles(tasklist_lb.current_index)
        l.each_with_index { |x, i|
          @task_lb[i] = x
        }
      end #bind_key(l)

      stack :margin_top => 0, :width_pc => ww-20 do
        @task_lb = listbox :list => app_helper.get_task_titles(0), 
          :title => "[ todos ]", 
          :name => "tasks", 
          :row => 1, :height => FFI::NCurses.LINES-4
      end #stack
      @task_lb.bind_key(?e, "Edit Task") { |t|
# Need something here
      } #bind_key(e)

    end #flow
  end #app
end #executable
