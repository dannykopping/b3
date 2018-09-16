ppid = nil
pid = Process.pid.to_i

def get_command(pid)
  `cat /proc/#{pid}/comm`.strip
end

tree = {pid => get_command(pid)}

until pid == 1 do
  ppid = `cat /proc/#{pid}/stat | awk '{print $4}'`.strip.to_i
  cmd = get_command(pid)
  tree[ppid] = cmd
  pid = ppid
end

x = tree.sort_by {|pid, _| pid}
require 'byebug'
byebug
y = 0