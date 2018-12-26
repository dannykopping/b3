require 'b3/parser'

RSpec.describe 'strace line parsing' do
  let(:basic_line) {
    'write(26, "hello world\n", 12) = 12 <0.000021>'
  }

  let(:basic_line_with_pid) {
    "[pid 10757] #{basic_line}"
  }

  context 'interface' do
    it 'returns a frozen DAO representing the syscall' do
      parsed = B3::Parser.execute(basic_line)

      expect(parsed).to be_a(B3::Model::ParsedSyscall)
      expect(parsed.frozen?).to be(true)
    end
  end

  context 'parsing lines' do
    it 'accurately parses a given line' do
      parsed = B3::Parser.execute(basic_line)

      expect(parsed.pid).to eq(nil)
      expect(parsed.syscall).to eq('write')
      expect(parsed.args).to eq([26, 'hello world\n', 12])
      expect(parsed.result).to eq(12)
      expect(parsed.timing).to eq(0.000021)
    end

    it 'accurately parses a given line with PID' do
      parsed = B3::Parser.execute(basic_line_with_pid)

      expect(parsed.pid).to eq(10757)
      expect(parsed.syscall).to eq('write')
      expect(parsed.args).to eq([26, 'hello world\n', 12])
      expect(parsed.result).to eq(12)
      expect(parsed.timing).to eq(0.000021)
    end

    it 'accurately parses a syscall with no arguments' do
      parsed = B3::Parser.execute('getuid() = 1000 <0.000007>')

      expect(parsed.syscall).to eq('getuid')
      expect(parsed.args).to eq([])
    end

    it 'coerces the data into appropriate data-types' do
      parsed = B3::Parser.execute(basic_line)
      expect(parsed.pid).to be_nil

      # PID is only integer if given, otherwise nil
      parsed = B3::Parser.execute(basic_line_with_pid)
      expect(parsed.pid).to be_a(Integer)


      expect(parsed.syscall).to be_a(String)
      expect(parsed.args).to be_a(Array)
      expect(parsed.result).to be_a(Integer)
      expect(parsed.timing).to be_a(Float)
    end

    it 'fails silently if line is invalid' do
      parsed = B3::Parser.execute('...invalid...')
      expect(parsed).to eq(nil)
    end

    it 'raises a pattern match error if line is invalid and "debug" flag is passed' do
      expect {
        B3::Parser.execute('...invalid...', debug: true)
      }.to raise_error(B3::Error::ParserError, 'Failed to match pattern')
    end

    it 'raises an empty line error if line is blank and "debug" flag is passed' do
      expect {
        B3::Parser.execute(nil, debug: true)
      }.to raise_error(B3::Error::ParserError, 'Empty line')
    end

    it 'ignores lines that do not conform to the naming convention of function names (i.e. syscall resumes)' do
      expect(B3::Parser.execute('[pid 22006] <... read resumed> "]\6\367="..., 8192) = 8192 <0.000029>')).to eq(nil)
    end

    # this is an open problem, but a very cornery corner-case
    xit 'handles inner ") =" value in arguments which might confuse the parser' do
      confusing = <<-EOF
[pid 31112] read(10, "something) ="..., 8192) = 8192 <0.000010>
EOF
      expect(B3::Parser.execute(confusing.chomp)).to_not eq(nil)
    end
  end

  context 'internal strace error-handling' do
    it 'raises an exception when an internal strace message is encountered' do
      line = 'strace: attach: ptrace(PTRACE_SEIZE, 1): Operation not permitted'

      expect { B3::Parser.execute(line) }.to raise_error(B3::Error::Strace)
    end
  end
end
