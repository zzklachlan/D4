# frozen_string_literal: true

# require 'flamegraph'
require_relative 'program'

program = Program.new(ARGV[0])
program.run
