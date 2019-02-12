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
        "Ruby" => described_class::Ruby,
        "Bundler" => described_class::Bundler,
        "Openjdk" => described_class::Openjdk,
        "Foo" => nil
      }.each do |name, klass|
        expect(described_class.get_build_target(name)).to eq(klass)
      end
    end
  end

  describe ".parse_stack_mappings!" do
    let(:json_mapping) do
      '{"sle12": "cflinuxfs2", "opensuse42": "cflinuxfs2", "cfsle15fs": "cflinuxfs3"}'
    end
    let(:expected_mapping) do
      {'sle12' => "cflinuxfs2", 'opensuse42' => "cflinuxfs2", "cfsle15fs" => "cflinuxfs3"}
    end
    it 'returns a proper hash' do
      expect(described_class.parse_stack_mappings!(json_mapping)).to eq(expected_mapping)
    end
    it 'raises an error' do
      expect{ described_class.parse_stack_mappings!('') }.to raise_error('no STACK_MAPPINGS environment variable set')
    end
  end
end
