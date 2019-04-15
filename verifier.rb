# frozen_string_literal: true

require 'flamegraph'
require_relative './program.rb'

Flamegraph.generate('flame_graph.html') do
  if ARGV.count > 1
    puts 'Usage: number of arguments has to be one!'
    exit(0)
  end
  file = Program.open_file(ARGV[0])
  exit(0) if file == false
  program = Program.new(file)
  error = program.run
  puts error unless error.is_a? Integer
end
