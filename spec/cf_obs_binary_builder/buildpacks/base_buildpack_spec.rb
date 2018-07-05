describe CfObsBinaryBuilder::BaseBuildpack do
  let(:buildpack) { described_class.new("foo", "1.0.0") }

  describe "#manifest_dependencies" do
    before(:each) do
      expect(buildpack).to receive(:parsed_manifest).and_return(
        YAML.load_file(File.expand_path("../../../fixtures/ruby-buildpack-manifest.yml", __FILE__))
      )
    end

    it "returns the list of dependencies" do
      expected = [
        { name: "bundler", version: "1.16.2" },
        { name: "jruby", version: "9.1.17.0" },
        { name: "jruby", version: "9.2.0.0" },
        { name: "node", version: "4.9.1" }
      ]

      expect(buildpack.manifest_dependencies).to match_array(expected)
    end
  end
end
