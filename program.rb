# frozen_string_literal: true

# require_relative './user.rb'
require 'flamegraph'

# This is the main program
class Program
  attr_accessor :users
  attr_accessor :blocks
  attr_accessor :file
  attr_accessor :hash_val

  # This is the initial mathod
  def initialize(file_name)
    @users = {}
    @blocks = []
    @hash_val = {}
    open_file(file_name)
  end

  # This will open a file
  def open_file(file_name)
    @file = File.open(file_name, 'r')
  rescue StandardError
    puts 'Usage: ruby verifier.rb <name_of_file>
    name_of_file = name of file to verify'
    exit(0)
  end

  # This modifies user's amount
  def modify_user(from_user, to_user, amount)
    @users.store(from_user, 0) unless @users.key?(from_user) || from_user == 'SYSTEM'
    @users.store(to_user, 0) unless @users.key?(to_user)
    @users[from_user] -= amount unless from_user == 'SYSTEM'
    @users[to_user] += amount
  end

  # This takes care of every single transaction
  def transaction(tran)
    multi_tran = tran.split(':')
    multi_tran.each do |x|
      single_tran = x.split(/>|[()]/)
      modify_user(single_tran[0], single_tran[1], single_tran[2].to_i)
    end
  end

  # This method checks the block number
  def check_block_number(count, b_num)
    return if count == b_num.to_i

    puts "Line #{count}: Invalid block number #{b_num}, should be #{count} \nBLOCKCHAIN INVALID"
    exit(0)
  end

  def check_prev_hash(prev_hash, curr_hash, b_num)  
    unless prev_hash.eql? curr_hash
      puts "Line #{b_num}: Previous has was #{curr_hash}, should be #{prev_hash}"
      puts 'BLOCKCHAIN INVALID'
      exit(0)
    end
  end

  def check_timestamp(prev_time, curr_time, b_num)
    prev_time1 = prev_time.split('.')[0]
    prev_time2 = prev_time.split('.')[1]
    curr_time1 = curr_time.split('.')[0]
    curr_time2 = curr_time.split('.')[1]
    unless prev_time1.to_i == curr_time1.to_i && prev_time2.to_i < curr_time2.to_i
      puts "Line #{b_num}: Previous timestamp #{prev_time} => new timestamp #{curr_time}"
      puts 'BLOCKCHAIN INVALID'
      exit(0)
    end
  end

  def check_balance(b_num)
    invalid_addr = ''
    invalid_balance = 0
    @users.each do |key, value|
      if value < 0
        invalid_addr = key 
        invalid_balance = value 
        break
      end
    end

    unless invalid_addr == ''
      puts "Line #{b_num}: address #{invalid_addr} has #{invalid_balance} billcoins!"
      puts 'BLOCKCHAIN INVALID'
      exit(0)
    end
  end

  # run the program
  def run
    count = 0
    prev_hash = ''
    prev_timestamp = ''
    curr_block = []
    @file.each do |line|
      @blocks << line.chomp # each line is a block
      curr_block = @blocks[count].split('|')      
      check_block_number(count, curr_block[0])
      check_timestamp(prev_timestamp, curr_block[3], curr_block[0].to_i) unless count.zero?
      check_prev_hash(prev_hash, curr_block[1], curr_block[0].to_i) unless count.zero?
      transaction(curr_block[2])
      check_balance(curr_block[0].to_i)
      prev_timestamp = curr_block[3]
      prev_hash = curr_block[4]
      count += 1
    end
    output
  end

  # output the result
  def output
    @users.sort_by { |k, _v| k }.to_h.each do |key, value|
      puts "#{key}: #{value} billcoins" unless value.zero?
    end
  end
end
