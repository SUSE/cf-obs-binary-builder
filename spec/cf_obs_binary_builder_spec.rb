require_relative "spec_helper"

describe CfObsBinaryBuilder do
  describe '.run' do
    context "when less than 3 arguments are given" do
      let(:args) { ["dependency"] }
      it "returns and error" do
        expect{ CfObsBinaryBuilder.run(*args) }.to raise_error(SystemExit, "Wrong number of arguments, please specify: dependency, version and checksum")
      end
    end

    context "when the dependency is not supported" do
      let(:args) { ["dependency", "not_supported_dependency", "1.2", "1234"] }

      it "returns and error" do
        expect{ CfObsBinaryBuilder.run(*args) }.to raise_error(SystemExit, "Dependency not_supported_dependency not supported!")
      end
    end
  end

  describe ".get_dependency" do
    it "returns the proper classes" do
      {
        "ruby" => described_class::Ruby,
        "bundler" => described_class::Bundler,
        "openjdk" => described_class::Openjdk,
        "foo" => nil
      }.each do |name, klass|
        expect(described_class.get_build_target(name)).to eq(klass)
      end
    end
  end
end
