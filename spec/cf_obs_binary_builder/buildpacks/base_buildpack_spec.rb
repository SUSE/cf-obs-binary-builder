describe CfObsBinaryBuilder::BaseBuildpack do
  let(:buildpack) { described_class.new("foo", "1.0.0") }
  let(:manifest_path) { File.expand_path("../../../fixtures/ruby-buildpack-manifest.yml", __FILE__) }

end
