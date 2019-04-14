# frozen_string_literal: true

require 'flamegraph'
require_relative 'program'

Flamegraph.generate('flame_graph.html') do
	program = Program.new(ARGV[0])
	program.run
end