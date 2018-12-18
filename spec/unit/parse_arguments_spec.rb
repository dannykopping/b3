require 'b3/arguments_parser'

RSpec.describe 'strace argument parsing' do
  context 'interface' do
    it 'returns a frozen array representing the syscall\'s arguments' do
      parsed = B3::ArgumentsParser.parse('0')

      expect(parsed).to be_a(Array)
      expect(parsed.frozen?).to be(true)
    end
  end

  context 'syscall argument parsing' do
    it 'should handle syscalls with simple string arguments' do
      # e.g.
      # man 2 symlink
      # ...
      #   `symlink(const char *target, const char *linkpath)`
      # ...
      parsed = B3::ArgumentsParser.parse('"source", "target"')
      expect(parsed).to eq(['source', 'target'])
    end

    it 'should handle syscalls with complex string arguments' do
      # e.g.
      # man 2 write
      # ...
      #   `write(int fd, const void *buf, size_t count)`
      # ...

      arguments = <<-EOF
1, "i'm a string with \"different\" kinds of quotes (even \342\200\230non-ascii\342\200\231)", 68
EOF

      parsed = B3::ArgumentsParser.parse(arguments)
      expect(parsed).to eq([1, "i'm a string with \"different\" kinds of quotes (even ‘non-ascii’)", 68])
    end

    it 'should handle syscalls with multiple arguments' do
      # e.g.
      # man 2 lseek
      # ...
      #   `lseek(int fd, off_t offset, int whence)`
      # ...
      parsed = B3::ArgumentsParser.parse('27, 8192, SEEK_SET')
      expect(parsed).to eq([27, 8192, 'SEEK_SET'])
    end

    it 'should handle syscalls with a NULL argument' do
      # e.g.
      # man 2 mmap
      # ...
      #   `*mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset)`
      # ...
      parsed = B3::ArgumentsParser.parse('NULL, 16384, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0')
      expect(parsed).to eq([nil, 16384, 'PROT_READ|PROT_WRITE', 'MAP_PRIVATE|MAP_ANONYMOUS', -1, 0])
    end

    it 'should handle syscalls with an array argument' do
      # e.g.
      # man 2 select
      # ...
      #   ```*select(int nfds, fd_set *readfds, fd_set *writefds,
      #            fd_set *exceptfds, struct timeval *timeout);```
      #
      #   fd_set is just an array of file descriptors
      # ...
      #
      parsed = B3::ArgumentsParser.parse('[7,10,19], NULL, [7, "a string", NULL]')
      expect(parsed).to eq([[7,10,19], nil, [7, 'a string', nil]])
    end

    skip 'should handle syscalls with an nested array arguments' do
      # arguments parser cannot currently handle this without converting to a lexer,
      # which seems like a bridge too far right now. if i find any syscalls that
      # leverage nested arrays, i will consider fixing this
    end
  end
end
