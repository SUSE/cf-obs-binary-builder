require_relative "spec_helper"

describe '.log' do
  context "when log level is info" do
    before { ENV["VERBOSITY"] = "info" }
    it "prints errors, warnings and info" do
      expect { log('This is a message', "error") }.
        to output("This is a message\n").to_stdout
      expect { log('This is a message', "warning") }.
        to output("This is a message\n").to_stdout
    end

    it "does not print debug messages" do
      expect { log('This is a message', "debug") }.
        to_not output("This is a message\n").to_stdout
    end
  end
end
