# frozen_string_literal: true

# require_relative './user.rb'

# This is the main program
class Program
  attr_accessor :users
  attr_accessor :blocks
  attr_accessor :file

  # This is the initial mathod
  def initialize(file_name)
    @users = {}
    @blocks = []
    open_file(file_name)
  end

  # This will open a file
  def open_file(file_name)
    @file = File.open(file_name, 'r')
  end

  def modify_user(from_user, to_user, amount)
    @users.store(from_user, 0) unless @users.key?(from_user) || from_user == 'SYSTEM'
    @users.store(to_user, 0) unless @users.key?(to_user)
    @users[from_user] -= amount unless from_user == 'SYSTEM'
    @users[to_user] += amount
  end

  def transaction(tran)
    multi_tran = tran.split(':')
    multi_tran.each do |x|
      single_tran = x.split(/>|[()]/)
      modify_user(single_tran[0], single_tran[1], single_tran[2].to_i)
    end
  end

  def run
    @file.each do |line|
      @blocks << line
      transaction(line.split('|')[2])
    end
    output
  end

  def output
    @users.sort_by { |k, _v| k }.to_h.each do |key, value|
      puts "#{key}: #{value} billcoins" unless value.zero?
    end
  end
end
