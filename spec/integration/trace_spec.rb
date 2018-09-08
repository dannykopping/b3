RSpec.describe "`b3 trace` command", type: :cli do
  it "executes `b3 help trace` command successfully" do
    output = `b3 help trace`
    expected_output = <<-OUT
Usage:
  b3 trace

Options:
  -h, [--help], [--no-help]  # Display usage information

Trace a process
    OUT

    expect(output).to eq(expected_output)
  end
end
