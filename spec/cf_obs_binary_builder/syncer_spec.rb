require_relative "../spec_helper.rb"

describe CfObsBinaryBuilder::Syncer do
  let(:manifest_path) { File.expand_path("../fixtures/ruby-buildpack-manifest.yml", __dir__) }
  subject { described_class.new(manifest_path) }

  describe "#sync"

  describe "#missing_deps" do
    it "returns missing dependencies" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?).and_return(false)

      missing_deps = subject.missing_deps
      expect(missing_deps.length).to eq(5)
      expect(missing_deps.first["name"]).to eq("bundler")
      expect(missing_deps.first["version"]).to eq("1.16.2")
      expect(missing_deps.first["uri"]).to eq("https://buildpacks.cloudfoundry.org/dependencies/bundler/bundler-1.16.2.tgz")
    end
  end
end
