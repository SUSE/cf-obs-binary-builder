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
      expect_any_instance_of(CfObsBinaryBuilder::BaseDependency).to receive(:run).once do |obj|
        expect(obj.dependency).to eq("bundler")
      end

      subject.sync
    end
  end

  describe "#dependencies" do
    it "returns missing dependencies" do
      _, missing_deps, _ = subject.dependencies
      expect(missing_deps.length).to eq(1)
      expect(missing_deps.first).to be_a(CfObsBinaryBuilder::Bundler)
      expect(missing_deps.first.version).to eq("1.16.2")
    end

    it "returns unknown dependencies" do
      allow_any_instance_of(CfObsBinaryBuilder::Syncer).to receive(:dependency_for).and_wrap_original do |original, *args|
        if args[0]["name"] == "bundler"
          nil
        else
          original.call(*args)
        end
      end
      _, _, unknown_deps = subject.dependencies

      expect(unknown_deps).to eq(["bundler"])
    end
  end
end
