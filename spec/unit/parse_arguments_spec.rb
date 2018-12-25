require 'b3/arguments_parser'

RSpec.describe 'strace argument parsing' do
  context 'interface' do
    it 'returns a frozen array representing the syscall\'s arguments' do
      parsed = B3::ArgumentsParser.execute('0')

      expect(parsed).to eq([0])
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
      parsed = B3::ArgumentsParser.execute('"source", \'target\'')
      expect(parsed).to eq(['source', 'target'])
    end

    it 'should handle syscalls with complex string arguments' do
      # e.g.
      # man 2 write
      # ...
      #   `write(int fd, const void *buf, size_t count)`
      # ...

      arguments = <<-EOF
1, "i'm a string with \\"different\\" kinds of quotes (even \342\200\230non-ascii\342\200\231)", 'another "value"', 68
EOF

      parsed = B3::ArgumentsParser.execute(arguments.chomp)
      expect(parsed).to eq([1, "i'm a string with \"different\" kinds of quotes (even ‘non-ascii’)", 'another "value"', 68])
    end

    it 'should handle syscalls with a NULL argument' do
      # e.g.
      # man 2 brk
      # ...
      #   `brk (void *addr)`
      # ...
      parsed = B3::ArgumentsParser.execute('NULL')
      expect(parsed).to eq([nil])
    end

    it 'should handle syscalls with a multiple flags' do
      # e.g.
      # man 2 mmap
      # ...
      #   `*mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset)`
      # ...
      parsed = B3::ArgumentsParser.execute('NULL, 16384, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0')
      expect(parsed).to eq([nil, 16384, ['PROT_READ', 'PROT_WRITE'], ['MAP_PRIVATE', 'MAP_ANONYMOUS'], -1, 0])
    end

    it 'should handle a single flag as a constant, and not return an array (because it is not possible to distinguish between a flag and constant)' do
      # e.g.
      # man 2 mmap
      # ...
      #   `*mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset)`
      # ...
      parsed = B3::ArgumentsParser.execute('NULL, 16384, PROT_READ, MAP_PRIVATE, -1, 0')
      expect(parsed).to eq([nil, 16384, 'PROT_READ', 'MAP_PRIVATE', -1, 0])
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
      parsed = B3::ArgumentsParser.execute('[7,10,19], NULL, [7, "a string", NULL]')
      expect(parsed).to eq([[7,10,19], nil, [7, 'a string', nil]])
    end

    it 'should handle syscalls with an nested array arguments' do
      # this is a bit of an academic example, since I have not encountered any
      # syscalls with nested arrays just yet

      parsed = B3::ArgumentsParser.execute('[[["inner"], 123], \'outer\']')
      expect(parsed).to eq([[['inner'], 123], 'outer'])
    end

    it 'should handle escape sequences as arguments' do
      parsed = B3::ArgumentsParser.execute('"\n", \'\t\'')
      expect(parsed).to eq(['\n', '\t'])
    end

    it 'should handle syscalls with a struct argument' do
      # e.g.
      # man 2 writev
      # ...
      #   `writev(int fd, const struct iovec *iov, int iovcnt);`
      #
      #    struct iovec {
      #        void  *iov_base;    /* Starting address */
      #        size_t iov_len;     /* Number of bytes to transfer */
      #    };
      # ...
      #
      parsed = B3::ArgumentsParser.execute('1, [{iov_base="something", iov_len=9}, {iov_base="\n", iov_len=1}], 2')
      expect(parsed).to eq([1, [{iov_base: 'something', iov_len: 9}, {iov_base: '\n', iov_len: 1}], 2])
    end

    it 'should handle addresses' do
      parsed = B3::ArgumentsParser.execute('3, {address=0xDEADBeef}')
      expect(parsed).to eq([3, {address: '0xDEADBeef'}])
    end

    it 'should handle incomplete objects' do
      parsed = B3::ArgumentsParser.execute('3, {st_mode=S_IFREG|0644, st_size=99571, ...}')
      expect(parsed).to eq([3, {st_mode: ['S_IFREG', '0644'], st_size: 99571}])
    end

    it 'should handle comments' do
      parsed = B3::ArgumentsParser.execute('"/bin/ls", ["ls"], 0x7ffcd01c8b48 /* 78 vars */')
      expect(parsed).to eq(['/bin/ls', ['ls'], '0x7ffcd01c8b48'])
    end

    it 'should handle expressions as object values' do
      # e.g.
      # man 2 prlimit64
      # ...
      #   `prlimit(pid_t pid, int resource, const struct rlimit *new_limit, struct rlimit *old_limit)`
      #
      #   struct rlimit {
      #      rlim_t rlim_cur;  /* Soft limit */
      #      rlim_t rlim_max;  /* Hard limit (ceiling for rlim_cur) */
      #   };
      #

      parsed = B3::ArgumentsParser.execute('0, RLIMIT_STACK, NULL, {rlim_cur=8192*1024, rlim_max=RLIM64_INFINITY}')
      expect(parsed).to eq([0, "RLIMIT_STACK", nil, {:rlim_cur=>"8192*1024", :rlim_max=>"RLIM64_INFINITY"}])
    end
  end
end
