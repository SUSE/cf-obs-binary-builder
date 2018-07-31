describe CfObsBinaryBuilder::Jruby do
  describe "#initialize" do
    it "validates the version number" do
      expect {
        CfObsBinaryBuilder::Jruby.new "1.2.3"
      }.to raise_error(/Invalid version/)
    end

    it "parses the ruby and the jruby version" do
      jruby = CfObsBinaryBuilder::Jruby.new "9.2.0.0"
      expect(jruby.ruby_version).to eq("2.5")
      expect(jruby.jruby_version).to eq("9.2.0.0")
    end
  end
end
