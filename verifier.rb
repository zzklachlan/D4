# frozen_string_literal: true

require_relative './program.rb'

program = Program.new(ARGV[0])
program.run
