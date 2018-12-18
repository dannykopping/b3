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
      parsed = B3::Parser.parse(basic_line)

      expect(parsed).to be_a(B3::Model::ParsedSyscall)
      expect(parsed.frozen?).to be(true)
    end
  end

  context 'parsing lines' do
    it 'accurately parses a given line' do
      parsed = B3::Parser.parse(basic_line)

      expect(parsed.pid).to eq(nil)
      expect(parsed.syscall).to eq('write')
      expect(parsed.args).to eq([26, 'hello world\n', 12])
      expect(parsed.result).to eq(12)
      expect(parsed.time).to eq(0.000021)
    end

    it 'accurately parses a given line with PID' do
      parsed = B3::Parser.parse(basic_line_with_pid)

      expect(parsed.pid).to eq(10757)
      expect(parsed.syscall).to eq('write')
      expect(parsed.args).to eq([26, 'hello world\n', 12])
      expect(parsed.result).to eq(12)
      expect(parsed.time).to eq(0.000021)
    end

    it 'coerces the data into appropriate data-types' do
      parsed = B3::Parser.parse(basic_line)
      expect(parsed.pid).to be_nil

      # PID is only integer if given, otherwise nil
      parsed = B3::Parser.parse(basic_line_with_pid)
      expect(parsed.pid).to be_a(Integer)


      expect(parsed.syscall).to be_a(String)
      expect(parsed.args).to be_a(Array)
      expect(parsed.result).to be_a(Integer)
      expect(parsed.time).to be_a(Float)
    end

    it 'fails silently if line is invalid' do
      parsed = B3::Parser.parse('...invalid...')
      expect(parsed).to eq(nil)
    end

    it 'raises a pattern match error if line is invalid and "debug" flag is passed' do
      expect {
        B3::Parser.parse('...invalid...', debug: true)
      }.to raise_error(B3::Error::ParserError, 'Failed to match pattern')
    end

    it 'raises an empty line error if line is blank and "debug" flag is passed' do
      expect {
        B3::Parser.parse(nil, debug: true)
      }.to raise_error(B3::Error::ParserError, 'Empty line')
    end
  end

  context 'internal strace error-handling' do
    it 'raises an exception when an internal strace message is encountered' do
      line = 'strace: attach: ptrace(PTRACE_SEIZE, 1): Operation not permitted'

      expect { B3::Parser.parse(line) }.to raise_error(B3::Error::Strace)
    end
  end
end
