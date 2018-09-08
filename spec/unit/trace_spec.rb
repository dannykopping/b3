require 'b3/commands/trace'

RSpec.describe B3::Commands::Trace do
  it "executes `trace` command successfully" do
    output = StringIO.new
    options = {}
    command = B3::Commands::Trace.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
