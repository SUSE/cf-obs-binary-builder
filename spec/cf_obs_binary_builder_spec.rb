describe CfObsBinaryBuilder, '.run' do
  context "when less than 3 arguments are given" do
    let(:args) { [] }
    it "returns and error" do
      expect{ CfObsBinaryBuilder.run(*args) }.to raise_error(SystemExit, "Wrong number of arguments, please specify: dependency, version and checksum")
    end
  end

  context "when the dependency is not supported" do
    let(:args) { ["not_supported_dependency", "1.2", "1234"] }

    it "returns and error" do
      expect{ CfObsBinaryBuilder.run(*args) }.to raise_error(SystemExit, "Dependency not_supported_dependency not supported!")
    end
  end
end
