# B3 Tracer

## Limitations

 - cannot currently handle stdin
 - cannot handle unfinished/resume lines (only show in verbose?)
 
## Roadmap

 - add syscall/syscall category renderers (i.e. highlight file handles for file syscalls, etc)gettid
 - possible swap out Open3 for https://ruby-doc.org/stdlib-2.2.3/libdoc/pty/rdoc/PTY.html
   - in order to read stdin interactively, pipe data in
 - replace Thor with https://rubygems.org/gems/clamp
 - add option to parent the process or run as detached grandchild
 - recategorise "pure" syscalls