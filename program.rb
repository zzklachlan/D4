# frozen_string_literal: true

require 'flamegraph'

# This is the main program
class Program
  attr_accessor :users
  attr_accessor :blocks
  attr_accessor :file
  attr_accessor :hash_val
  attr_accessor :error_code

  # This is the initial mathod
  def initialize(file)
    @users = {}
    @blocks = []
    @hash_val = {}
    @error_code = 0
    @file = file
  end

  # This will open a file
  def self.open_file(file_name)
    begin
      file = File.open(file_name, 'r')
    rescue StandardError
      puts "Usage: ruby verifier.rb <name_of_file> \n    name_of_file = name of file to verify"
      return false
    end
    file
  end

  # This modifies user's amount
  def modify_user(from_user, to_user, amount)
    @users.store(from_user, 0) unless @users.key?(from_user) || from_user == 'SYSTEM'
    @users.store(to_user, 0) unless @users.key?(to_user)
    @users[from_user] -= amount unless from_user == 'SYSTEM'
    @users[to_user] += amount
  end

  # This takes care of every single transaction
  def transaction(tran, b_num)
    error_code = 0
    multi_tran = tran.split(':')
    multi_tran.each do |x|
      single_tran = x.split(/>|[()]/)
      error_code = check_invalid_format(single_tran[0], single_tran[1], single_tran[2].to_i, b_num, tran)
      return error_code if error_code == 5

      modify_user(single_tran[0], single_tran[1], single_tran[2].to_i)
    end
    0
  end

  def check_string(string)
    string.scan(/\D/).empty?
  end

  def check_invalid_format(from_addr, to_addr, amount, _b_num, _tran)
    return 5 if from_addr.nil? || to_addr.nil? || amount.nil?

    is_valid = true
    is_valid = false unless from_addr.length == 6 && to_addr.length == 6
    is_valid = false if amount.negative?
    is_valid = false if check_string(from_addr) == false && from_addr != 'SYSTEM'
    is_valid = false if check_string(to_addr) == false && to_addr != 'SYSTEM'

    return 5 if is_valid == false

    0
  end

  # This method checks the block number
  def check_block_number(count, b_num)
    return 2 unless count == b_num.to_i

    0
  end

  def check_prev_hash(prev_hash, curr_hash, _b_num)
    return 4 unless prev_hash.eql? curr_hash

    0
  end

  def check_timestamp(prev_time, curr_time, _b_num)
    prev_time1 = prev_time.split('.')[0].to_i
    prev_time2 = prev_time.split('.')[1].to_i
    curr_time1 = curr_time.split('.')[0].to_i
    curr_time2 = curr_time.split('.')[1].to_i

    return 3 if prev_time1 > curr_time1 || (prev_time1 == curr_time1 && prev_time2 > curr_time2)

    0
  end

  def check_balance
    @users.each do |key, value|
      return ['6', key, value] if value.negative?
    end
    0
  end

  def check_hash(block_number, previous_hash, transaction_string, timestamp_string, expected_hash)
    string_to_hash = "#{block_number}|#{previous_hash}|#{transaction_string}|#{timestamp_string}"
    sum = 0
    x_val = 0
    string_to_hash.unpack('U*').each do |x|
      if !@hash_val.key?(x)
        x_val = ((x**3000) + (x**x) - (3**x)) * (7**x)
        @hash_val[x] = x_val
      else
        x_val = @hash_val[x]
      end
      sum += x_val
    end
    sum = (sum % 65_536).to_s(16)
    return ['7', string_to_hash, expected_hash, sum] unless expected_hash == sum

    0
  end

  def check_extra_pipe(block)
    return 1 unless block.length == 5

    0
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
      @error_code = check_extra_pipe(curr_block)
      return "Line #{count}: extra pipe found! \nBLOCKCHAIN INVALID" if error_code == 1

      @error_code = check_block_number(count, curr_block[0])
      if error_code == 2
        return "Line #{count}: Invalid block number #{curr_block[0]}, should be #{count} \nBLOCKCHAIN INVALID"
      end

      @error_code = check_timestamp(prev_timestamp, curr_block[3], curr_block[0].to_i) unless count.zero?
      if error_code == 3
        return "Line #{count}: Previous timestamp #{prev_timestamp} => "\
        "new timestamp #{curr_block[3]} \nBLOCKCHAIN INVALID"
      end

      @error_code = check_prev_hash(prev_hash, curr_block[1], curr_block[0].to_i) unless count.zero?
      if error_code == 4
        return "Line #{count}: Previous has was #{curr_block[1]}, should be #{prev_hash}\nBLOCKCHAIN INVALID"
      end

      @error_code = transaction(curr_block[2], curr_block[0])
      if error_code == 5
        return "Line #{count}: Could not parse transactions list '#{curr_block[2]}' \nBLOCKCHAIN INVALID"
      end

      error_balance = check_balance
      @error_code = error_balance[0].to_i if error_balance.is_a? Array
      if error_code == 6
        return "Line #{count}: address #{error_balance[1]} has #{error_balance[2]} billcoins! \nBLOCKCHAIN INVALID"
      end

      error_hash = check_hash(curr_block[0], curr_block[1], curr_block[2], curr_block[3], curr_block[4])
      @error_code = error_hash[0].to_i if error_hash.is_a? Array
      if error_code == 7
        return "Line #{count}: String '#{error_hash[1]}' hash set to #{error_hash[2]}, "\
        "should be #{error_hash[3]}\nBLOCKCHAIN INVALID"
      end

      prev_timestamp = curr_block[3]
      prev_hash = curr_block[4]
      count += 1
    end
    output
    error_code
  end

  # output the result
  def output
    @users.sort_by { |k, _v| k }.to_h.each do |key, value|
      puts "#{key}: #{value} billcoins" unless value.zero?
    end
  end
end
