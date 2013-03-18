#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rake/testtask'

Rake::TestTask.new do |t|
  cmd = "bin/task_server.rb"
  $p = IO.popen(cmd)

  t.libs << "test"
  t.test_files = FileList['test/*test.rb']
  t.verbose = true
end

Rake::Task["test"].enhance do
  Process.kill('INT', $p.pid)
end


