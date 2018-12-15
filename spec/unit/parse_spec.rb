require 'b3/parser'

RSpec.describe 'strace line parsing' do
  let(:basic_line) {
    '[pid 10757] write(26, "hello world\n", 12) = 12 <0.000021>'
  }

  context 'interface' do
    it 'returns a frozen DAO representing the syscall' do
      parsed = B3::Parser.parse(basic_line)

      expect(parsed).to be_a(B3::Model::ParsedSyscall)
      expect(parsed.frozen?).to be(true)
    end
  end

  context 'parsing valid lines' do
    it 'accurately parsed a given line' do
      parsed = B3::Parser.parse(basic_line)

      expect(parsed.pid).to eq(10757)
      expect(parsed.syscall).to eq('write')
      expect(parsed.args).to eq(['26', '"hello world\n"', '12'])
      expect(parsed.result).to eq(12)
      expect(parsed.time).to eq(0.000021)
    end

    it 'coerces the data into appropriate data-types' do
      parsed = B3::Parser.parse(basic_line)

      expect(parsed.pid).to be_a(Integer)
      expect(parsed.syscall).to be_a(String)
      expect(parsed.args).to be_a(Array)
      expect(parsed.result).to be_a(Integer)
      expect(parsed.time).to be_a(Float)
    end
  end

  context 'internal strace error-handling' do
    it 'raises an exception when an internal strace message is encountered' do
      line = 'strace: attach: ptrace(PTRACE_SEIZE, 1): Operation not permitted'

      expect { parsed = B3::Parser.parse(line) }.to raise_error(B3::Error::Strace)
    end
  end
end
