require_relative "../spec_helper.rb"

describe CfObsBinaryBuilder::Syncer do
  let(:base_stack) { "cflinuxfs2" }
  let(:manifest_path) { File.expand_path("../fixtures/ruby-buildpack-manifest.yml", __dir__) }
  subject { described_class.new(manifest_path) }

  before(:each) do
    allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?) do |obj|
      obj.name != "bundler-1.17.3"
    end
    allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:create)
    allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:checkout)
    allow(CfObsBinaryBuilder::Checksum).to receive(:for)
  end

  describe "#sync" do
    it "creates missing dependencies" do
      expect_any_instance_of(CfObsBinaryBuilder::BaseDependency).to receive(:run).once do |obj|
        expect(obj.dependency).to eq("bundler")
      end

      subject.sync(base_stack)
    end
  end
end
