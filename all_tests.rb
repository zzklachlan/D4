require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require_relative 'program'

class ProgramTest < Minitest::Test
	def setup
		@mock_file = Minitest::Mock.new("test file")
		@test_program = Program::new @mock_file
		@test_program.users = { '123456' => 10, '345678' => 0, '567890' => 0 }
	end
	
	def test_new_program_not_nil
		refute_nil @test_program
		assert_kind_of Program, @test_program
	end

	# This test self.open_file
  def test_self_open_file
		file_name = 'name'
		assert_output("Usage: ruby verifier.rb <name_of_file> \n    name_of_file = name of file to verify\n"){
			Program.open_file(file_name)
		}
  end
	
	def test_modify_user
		@test_program.modify_user('123456', '345678', 5)
		assert_equal @test_program.users['123456'], 5
	end

	def test_modify_nonexisting_user
		@test_program.modify_user('SYSTEM', '123123', 20)
		assert_equal @test_program.users['123123'], 20
	end

	def test_transaction
		mock_addr = Minitest::Mock.new("mock")
		def @test_program.check_invalid_format(a, b, c, d, e); 0; end
		def @test_program.modify_user(x, y, z); nil; end

		assert_equal @test_program.transaction('735567>995917(1):577469>995917(1)', 3), 0
	end

	def test_check_valid_string
		assert_equal @test_program.check_string('789987'), true
	end

	def test_check_invalid_string
		assert_equal @test_program.check_string('123abc'), false
	end

	def test_check_valid_format
		def @test_program.check_string(x); true; end
		assert_equal @test_program.check_invalid_format('123456', '345678', 10, 3, '123456>345678(10)'), 0
	end

	def test_check_invalid_format
		#def @test_program.check_string(x); true; end
		assert_equal @test_program.check_invalid_format(nil, nil, 10, 3, '123456>345678(10)'), 5
	end

	def test_check_valid_block_number
		assert_equal @test_program.check_block_number(3, 3), 0
	end

	def test_check_invalid_block_number
		assert_equal @test_program.check_block_number(3, 5), 2
	end

	def test_check_valid_prev_hash
		assert_equal @test_program.check_prev_hash('34de', '34de', 3), 0
	end

	def test_check_invalid_prev_hash
		assert_equal @test_program.check_prev_hash('34de', '56xs', 3), 4
	end

	def test_check_valid_timestamp
		assert_equal @test_program.check_timestamp('1234.1234', '1234.5678', 3), 0
	end

	def test_check_invalid_timestamp
		assert_equal @test_program.check_timestamp('1234.5678', '1234.1234', 3), 3
	end

	def test_check_valid_balance
		@test_program.users['345678'] = 5
		@test_program.users['567890'] = 3
		
		assert_equal @test_program.check_balance, 0
	end

	def test_check_invalid_balance
		@test_program.users['345678'] = -5
		@test_program.users['567890'] = 3
		
		assert_equal @test_program.check_balance, ['6', '345678', -5]
	end

	def test_check_valid_hash 
		assert_equal @test_program.check_hash('0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '288d'), 0
	end

	def test_check_invalid_hash 
		assert_equal @test_program.check_hash('0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '287d'), ['7', '0|0|SYSTEM>569274(100)|1553184699.650330000', '287d', '288d']
	end
	
	def test_cheack_valid_extra_pipe
		assert_equal @test_program.check_extra_pipe([1,1,1,1,1]), 0
	end

	def test_cheack_invalid_extra_pipe
		assert_equal @test_program.check_extra_pipe([1,1,1,1,1,1]), 1
	end
	
	def test_check_block_extra_pipe
		def @test_program.check_extra_pipe(x); 1; end
		assert_equal "Line 3: extra pipe found! \nBLOCKCHAIN INVALID", @test_program.check_block(['0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '288d'], '1553184699.650330000', '288d', 3)
	end

	def test_check_block_number
		def @test_program.check_extra_pipe(x); 0; end
		def @test_program.check_block_number(x, y); 2; end
		assert_equal "Line 3: Invalid block number 0, should be 3 \nBLOCKCHAIN INVALID", @test_program.check_block(['0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '288d'], '1553184699.650330000', '288d', 3)
	end

	def test_check_block_timestamp
		def @test_program.check_extra_pipe(x); 0; end
		def @test_program.check_block_number(x,y); 0;end
		def @test_program.check_timestamp(x,y,z); 3; end
		assert_equal "Line 3: Previous timestamp 1553184699.650330000 => "\
		"new timestamp 1553184699.650330000 \nBLOCKCHAIN INVALID", @test_program.check_block(['0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '288d'], '1553184699.650330000', '288d', 3)
	end

	def test_check_block_prev_hash
		def @test_program.check_extra_pipe(x); 0; end
		def @test_program.check_block_number(x, y); 0; end
		def @test_program.check_timestamp(x, y, z); 0; end
		def @test_program.check_prev_hash(x, y, z); 4; end
		assert_equal "Line 3: Previous has was 0, should be 288d\nBLOCKCHAIN INVALID", @test_program.check_block(['0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '288d'], '1553184699.650330000', '288d', 3)
	end

	def test_check_block_transaction
		def @test_program.check_extra_pipe(x); 0; end
		def @test_program.check_block_number(x, y); 0; end
		def @test_program.check_timestamp(x, y, z); 0; end
		def @test_program.check_prev_hash(x, y, z); 0; end
		def @test_program.transaction(x, y); 5; end
		assert_equal "Line 3: Could not parse transactions list 'SYSTEM>569274(100)' \nBLOCKCHAIN INVALID", @test_program.check_block(['0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '288d'], '1553184699.650330000', '288d', 3)
	end

	def test_check_block_balance
		def @test_program.check_extra_pipe(x); 0; end
		def @test_program.check_block_number(x, y); 0; end
		def @test_program.check_timestamp(x, y, z); 0; end
		def @test_program.check_prev_hash(x, y, z); 0; end
		def @test_program.transaction(x, y); 0; end
		def @test_program.check_balance(); ['6', '123456', '-10']; end
		assert_equal "Line 3: address 123456 has -10 billcoins! \nBLOCKCHAIN INVALID", @test_program.check_block(['0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '288d'], '1553184699.650330000', '288d', 3)
	end

	def test_check_block_hash
		def @test_program.check_extra_pipe(x); 0; end
		def @test_program.check_block_number(x, y); 0; end
		def @test_program.check_timestamp(x, y, z); 0; end
		def @test_program.check_prev_hash(x, y, z); 0; end
		def @test_program.transaction(x, y); 0; end
		def @test_program.check_balance(); 0; end
		def @test_program.check_hash(a, b, c, d, e); ['7', '0|0|SYSTEM>569274(100)|1553184699.650330000', '95bc', '288d']; end
		assert_equal "Line 3: String '0|0|SYSTEM>569274(100)|1553184699.650330000' hash set to 95bc, "\
    "should be 288d\nBLOCKCHAIN INVALID", @test_program.check_block(['0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '288d'], '1553184699.650330000', '288d', 3)
	end

	def test_check_block_balance
    def @test_program.check_extra_pipe(x); 0; end
    def @test_program.check_block_number(x,y); 0;end
    def @test_program.check_timestamp(x,y,z); 0; end
    def @test_program.check_prev_hash(x,y,z); 0; end
		def @test_program.transaction(x,y); 0;end
		def @test_program.check_balance(); 0; end
		def @test_program.check_hash(a, b, c, d, e); 0; end
    assert_equal 0, @test_program.check_block(['0', '0', 'SYSTEM>569274(100)', '1553184699.650330000', '288d'], '1553184699.650330000', '288d', 3)
	end
	
	def test_run
		mock_file = Minitest::Mock.new('file')
		program3 = Program.new(mock_file)
		def mock_file.each; "1|1|1|1|1\n"; end
		def String.chomp; "1|1|1|1|1";end
		def String.split(y); [1,1,1,1,1];end
		@test_program.error_code = 1
		assert_output(""){program3.run}
	end

	def test_output
		#puts @test_program.users
		users = { '123456' => 10, '345678' => 0, '567890' => 0 }
		def users.sort_by; { '123456' => 10, '345678' => 0, '567890' => 0 }; end
		assert_output("123456: 10 billcoins\n") {
			@test_program.output(users)
		}
	end
end