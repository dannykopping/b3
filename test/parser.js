var expect = require('expect.js');
var parser = require('../lib/parser.js');
var errors = require('../lib/errors.js');

var options = {
  debug: process.env.DEBUG == 'true',
  trace: process.env.TRACE == 'true',
};

describe('strace output parsing', function() {
  describe('basic functionality', function() {
    let basic_line = String.raw `write(26, "hello world\n", 12) = 12 <0.000021>`;
    
    it('accurately parses a given line', function() {
      expect(parser.parseLine(basic_line, options)).to.eql({
        pid: null,
        syscall: 'write',
        args: [
          26,
          String.raw `hello world\n`,
          12
        ],
        result: 12,
        timing: 0.000021,
        type: parser.syscallType
      })
    });

    // maybe turn this into json-schema or something similar
    it('accurately coerces values into appropriate data type', function() {
      const parsed = parser.parseLine(basic_line, options);
      expect(typeof parsed.pid == 'number' || parsed.pid == null).to.be.true;
      expect(parsed.syscall).to.be.a('string');
      expect(parsed.args).to.be.an('array');
      expect(typeof parsed.result == 'string' || typeof parsed.result == 'number').to.be.true;
      expect(parsed.timing).to.be.a('number');
    });

    it('accurately parses a given line with a PID', function() {
      const result = {
        pid: 10757,
          syscall: 'write',
        args: [
          26,
          String.raw `hello world\n`,
          12
        ],
        result: 12,
        timing: 0.000021,
        type: parser.syscallType
      };

      expect(parser.parseLine(String.raw `[pid 10757] ${basic_line}`, options)).to.eql(result);
      expect(parser.parseLine(String.raw `10757 ${basic_line}`, options)).to.eql(result);
    });

    it('accurately parses a syscall with no arguments', function() {
      expect(parser.parseLine(String.raw `getuid() = 1000 <0.000007>`, options)).to.eql({
        pid: null,
        syscall: 'getuid',
        args: [],
        result: 1000,
        timing: 0.000007,
        type: parser.syscallType
      });
    });

    it('accurately parses a syscall with no timing data', function() {
      expect(parser.parseLine(String.raw `getuid() = 1000`, options)).to.eql({
        pid: null,
        syscall: 'getuid',
        args: [],
        result: 1000,
        timing: null,
        type: parser.syscallType
      });
    });

    it('accurately parses a syscall with a single argument', function() {
      expect(parser.parseLine(String.raw `close(4) = 0 <0.000011>`, options)).to.eql({
        pid: null,
        syscall: 'close',
        args: [4],
        result: 0,
        timing: 0.000011,
        type: parser.syscallType
      });
    });

    it('refuses to parse unfinished syscalls', function() {
      expect(function() {
        parser.parseLine(String.raw `6955  <... futex resumed> )             = -1 ETIMEDOUT (Connection timed out)`, options)
      }).to.throwException(function(e) {
        expect(e).to.be.a(errors.UnfinishedSyscallException)
      });

      expect(function (){
        try {
          parser.parseLine(String.raw`7016  futex(0x7ff23c537108, FUTEX_WAIT_PRIVATE, 0, {tv_sec=0, tv_nsec=12399422} <unfinished ...>`, options).to.eql(null);s
        } catch(e) {}
      })
    });

    it('fails silently if debug mode is disable and given line is invalid', function() {
      expect(parser.parseLine(String.raw `...invalid...`, {debug:false})).to.eql(null);
    });

    it('throws an exception if debug mode is enabled and given line is invalid', function() {
      expect(function() {
        parser.parseLine(String.raw `...invalid...`, {debug:true})
      }).to.throwException();
    });

    it('returns null for an empty line', function() {
      expect(parser.parseLine('', options)).to.equal(null);
      expect(parser.parseLine('    ', options)).to.equal(null);
      expect(parser.parseLine(null, options)).to.equal(null);
    });

    it('handles values in arguments which might confuse the parser', function() {
      expect(parser.parseLine(String.raw `[pid 31112] read(10, "something) ="..., 8192) = 8192 <0.000010>`, options)).to.eql({
        pid: 31112,
        syscall: 'read',
        args: [10, 'something) =', 8192],
        result: 8192,
        timing: 0.000010,
        type: parser.syscallType
      });
    });
  });

  describe('argument parsing', function() {
    it('handles syscalls with simple string arguments', function() {
      expect(parser.parseLine(String.raw `read(10, "1234567890", 10) = 10`, options)).to.eql({
        pid: null,
        syscall: 'read',
        args: [10, '1234567890', 10],
        result: 10,
        timing: null,
        type: parser.syscallType
      });
    });

    it('handles syscalls with string arguments with inner quotes', function() {
      expect(parser.parseLine(String.raw `read(10, "123'45'6\"7\"890", 10) = 10`, options)).to.eql({
        pid: null,
        syscall: 'read',
        args: [10, '123\'45\'6\"7\"890', 10],
        result: 10,
        timing: null,
        type: parser.syscallType
      });
    });

    it('handles syscalls with complex string arguments', function() {
      const line = String.raw `write(3, "invalid: \255\nkanji: \346\274\242\345\255\227", 24) = 24`;
      expect(parser.parseLine(line, options)).to.eql({
        pid: null,
        syscall: 'write',
        args: [3, String.raw `invalid: \255\nkanji: \346\274\242\345\255\227`, 24],
        result: 24,
        timing: null,
        type: parser.syscallType
      });
    });

    it('handles syscalls with address arguments and results', function() {
      const line = String.raw `brk(0x55ffa15ba000) = 0x55ffa15ba000 <0.000009>`;
      expect(parser.parseLine(line, options)).to.eql({
        pid: null,
        syscall: 'brk',
        args: [0x55ffa15ba000],
        result: 0x55ffa15ba000,
        timing: '0.000009',
        type: parser.syscallType
      });
    });

    it('handles syscalls with several flags as object values', function() {
      const line = String.raw `poll([{fd=161, events=POLLIN|POLLOUT}], 1, -1) = 1 ([{fd=161, revents=POLLOUT}])`;
      const parsed = parser.parseLine(line, options);
      expect(parsed.args).to.eql([[{
          fd: 161,
          events: ['POLLIN', 'POLLOUT']
        }], 1, -1]);
    });

    it('handles syscalls with a complex result value', function() {
      const line = String.raw `poll([{fd=161, events=POLLIN|POLLOUT}], 1, -1) = 1 ([{fd=161, revents=POLLOUT}])`;
      const parsed = parser.parseLine(line, options);
      expect(parsed.result).to.eql('1 ([{fd=161, revents=POLLOUT}])');
    });

    it('handles syscall with NULL arguments', function() {
      const line = String.raw `select(42, [41], NULL, NULL, NULL) = 1 (in [41])`
      const parsed = parser.parseLine(line, options);
      expect(parsed.args).to.eql([
        42,
        [41],
        null,
        null,
        null
      ])
    });

    describe('complex arguments & edge-cases', function() {
      it('handles syscalls with values resembling function calls', function() {
        const line = String.raw `10808 recvmsg(6, [{{nla_len=8, nla_type=RTA_OIF}, if_nametoindex("wlx503eaa54c52c")}]) = 1328 <0.000017>`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([6, [[{nla_len: 8, nla_type: ['RTA_OIF']}, {function:'if_nametoindex', params: ['wlx503eaa54c52c']}]]]);
      });

      it('handles syscalls with object values resembling function calls - single argument', function () {
        // because why the hell, not.

        const line = String.raw `connect(161, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("127.0.0.53")}, 16) = 0`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([
          161,
          {
            sa_family: ['AF_INET'],
            sin_port: {function: 'htons', params: [53]},
            sin_addr: {function: 'inet_addr', params: ['127.0.0.53']},
          },
          16
        ]);
      });

      it('handles syscalls with object values resembling function calls - multiple arguments', function () {
        // because why the hell, not.

        const line = String.raw `11365 stat("/dev/pts/3", {st_rdev=makedev(136, 0)}) = 0`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([
          '/dev/pts/3',
          {
            st_rdev: {function: 'makedev', params: [136, 0]},
          }
        ]);
      });

      it('handles syscalls with an ellipsis', function () {
        const line = String.raw `6645  sendto(75, "\20\3\0\0\20\0\1\0\0\0\0\0\0\0\0\0\5\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"..., 784, MSG_NOSIGNAL, NULL, 0) = 784`;
        expect(parser.parseLine(line, options)).to.eql({
          pid: 6645,
          syscall: 'sendto',
          args: [
            75,
            String.raw `\20\3\0\0\20\0\1\0\0\0\0\0\0\0\0\0\5\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0`,
            784,
            ['MSG_NOSIGNAL'],
            null,
            0
          ],
          result: 784,
          timing: null,
          type: parser.syscallType
        });
      });

      it('handles nested objects', function () {
        const line = String.raw `6392  recvmsg(161, {msg_name=NULL, msg_namelen=0, msg_iov=[{iov_base="\3$81p\366\177\0Z\1\0\0L\0 \5\0\0\0\0\245\3*\1\246\3\372\0\20\0\1\0", iov_len=4096}], msg_iovlen=1, msg_controllen=0, msg_flags=0}, 0) = 32`;
        expect(parser.parseLine(line, options)).to.eql({
          pid: 6392,
          syscall: 'recvmsg',
          args: [
            161,
            {
              msg_name: null,
              msg_namelen: 0,
              msg_iov: [{
                iov_base: String.raw `\3$81p\366\177\0Z\1\0\0L\0 \5\0\0\0\0\245\3*\1\246\3\372\0\20\0\1\0`,
                iov_len: "4096"
              }],
              msg_iovlen: 1,
              msg_controllen: 0,
              msg_flags: 0
            },
            0
          ],
          result: 32,
          timing: null,
          type: parser.syscallType
        });
      });

      // i.e. objects without keys
      it('handles anonymous nested objects', function() {
        const line = String.raw `10808 recvmsg(6, [{{nla_len=8, nla_type=RTA_TABLE}, RT_TABLE_MAIN}]) = 1328 <0.000017>`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([6, [[{nla_len: 8, nla_type: ['RTA_TABLE']}, ['RT_TABLE_MAIN']]]]);
      });

      // see https://en.wikipedia.org/wiki/Escape_sequences_in_C
      // C code to produce line:
      // `fprintf(stdout, "escape sequences: \a,\b,\f,\t,\r,\v,\\,\',\",\?,\1234,\xDK,\e,\U0001F4A9,\u6500\n");`
      it('handles arguments with escape sequences', function () {
        const line = String.raw `write(1, "escape sequences: \7,\10,\f,\t,\r,\v,\\,',\",?,S4,\rK,\33,\360\237\222\251,\346\224\200\n", 55) = 55`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([
          1,
          String.raw `escape sequences: \7,\10,\f,\t,\r,\v,\,',",?,S4,\rK,\33,\360\237\222\251,\346\224\200\n`,
          55
        ]);
      });

      it('handles key-value pairs like one would find in objects, but, like not in an object...', function() {
        const line = String.raw `11365 clone(flags=0x1234) = 12227`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([{
          name: "flags",
          value: "0x1234",
        }]);
      });

      it('handles strange ioctl format', function() {
        const line = String.raw `11365 ioctl(16, TCGETS, {B38400 opost isig icanon echo ...}) = 0`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([16, ['TCGETS'], ['B38400', 'opost', 'isig', 'icanon', 'echo', '...']]);
      });

      it('handles abbreviated arguments', function() {
        const line = String.raw `execve("/usr/bin/xdg-open", ["xdg-open", "."], 0x7ffdb094c968 /* 54 vars */) = 0`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql(['/usr/bin/xdg-open', ['xdg-open', '.'], 0x7ffdb094c968]);
      });

      it('handles abbreviated entries', function() {
        const line = String.raw `12056 getdents(7, /* 9 entries */, 32768) = 344 <0.000017>`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([7, '...', 32768]);
      });

      it('handles alternate flag list display (space)', function() {
        const line = String.raw `[pid  2227] rt_sigprocmask(SIG_UNBLOCK, [RTMIN RT_1], NULL, 8) = 0 <0.000006>`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([['SIG_UNBLOCK'], ['RTMIN', 'RT_1'], null, 8]);
      });

      it('handles alternate flag list display (or literal)', function() {
        const line = String.raw `10827 ioctl(6, DRM_IOCTL_I915_GETPARAM or DRM_IOCTL_TEGRA_CLOSE_CHANNEL, 0x7ffcc9dd2d80) = 0 <0.000009>`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([6, ['DRM_IOCTL_I915_GETPARAM', 'DRM_IOCTL_TEGRA_CLOSE_CHANNEL'], 0x7ffcc9dd2d80]);
      });

      it('handles alternate flag list display with a bitwise operator', function() {
        const line = String.raw `[pid  2227] rt_sigprocmask(SIG_UNBLOCK, ~[RTMIN RT_1], NULL, 8) = 0 <0.000006>`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([['SIG_UNBLOCK'], { operator:'~', elements:['RTMIN', 'RT_1'] }, null, 8]);
      });

      it('handles socket display [enclosed]', function() {
        const line = String.raw `getpeername(3, {sa_family=AF_UNIX, sun_path=@"/tmp/.X11-unix/X0"}, [124->20]) = 0 <0.000010>`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([3, {sa_family: ['AF_UNIX'], sun_path: '/tmp/.X11-unix/X0'}, {ulen: 124, rlen: 20}]);
      });

      it('handles socket display', function() {
        const line = String.raw `10808 recvmsg(6, {msg_name={sa_family=AF_NETLINK, msg_namelen=128->12}}) = 1328 <0.000017>`;
        const parsed = parser.parseLine(line, options);
        expect(parsed.args).to.eql([6, {msg_name:{sa_family: ['AF_NETLINK'], msg_namelen: {ulen: 128, rlen: 12}}}]);
      });
    });
  });
});

describe('strace events', function() {
  it('handles strace alerts', function() {
    const line = String.raw `12225 +++ exited with 0 +++`
    const parsed = parser.parseLine(line, options);
    expect(parsed).to.eql({
      pid: 12225,
      alert: 'exited with 0',
      type: parser.alertType
    })
  });

  it('handles strace errors', function() {
    const line = String.raw `strace: attach: ptrace(PTRACE_SEIZE, 1): Operation not permitted`;
    const parsed = parser.parseLine(line, options);
    expect(parsed).to.eql({
      error: 'attach: ptrace(PTRACE_SEIZE, 1): Operation not permitted',
      type: parser.errorType
    })
  });

  it('handles stopped processes', function() {
    const line = String.raw `[pid 20390] --- SIGSTOP {si_signo=SIGSTOP, si_code=SI_USER, si_pid=20405, si_uid=1000} ---`;
    const parsed = parser.parseLine(line, options);

    expect(parsed).to.eql({
      pid: 20390,
      type: parser.stoppedType,
      alert: {
        signal: 'SIGSTOP',
        data: {
          si_signo: ['SIGSTOP'],
          si_code: ['SI_USER'],
          si_pid: 20405,
          si_uid: 1000
        }
      }
    });
  });
});
