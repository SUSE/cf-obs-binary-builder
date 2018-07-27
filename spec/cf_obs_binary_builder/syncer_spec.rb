require_relative "../spec_helper.rb"

describe CfObsBinaryBuilder::Syncer do
  let(:manifest_path) { File.expand_path("../fixtures/ruby-buildpack-manifest.yml", __dir__) }
  subject { described_class.new(manifest_path) }

  before(:each) do
    allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?) do |obj|
      obj.name != "bundler-1.16.2"
    end
  end

  describe "#sync" do
    it "creates missing dependencies" do
      expect_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:create).once do |obj|
        expect(obj.name).to eq("bundler-1.16.2")
      end

      subject.sync
    end
  end

  describe "#missing_deps" do
    it "returns missing dependencies" do
      missing_deps = subject.missing_deps
      expect(missing_deps.length).to eq(1)
      expect(missing_deps.first).to be_a(CfObsBinaryBuilder::Bundler)
      expect(missing_deps.first.version).to eq("1.16.2")
    end
  end
end
