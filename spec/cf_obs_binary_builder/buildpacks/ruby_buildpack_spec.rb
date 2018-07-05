describe CfObsBinaryBuilder::RubyBuildpack do
  let(:buildpack) { described_class.new("1.0.0") }

  describe "#initialize" do
    it "returns an instance" do
      expect(buildpack).to be_a(described_class)
      expect(buildpack.name).to eq("ruby")
    end
  end
end
