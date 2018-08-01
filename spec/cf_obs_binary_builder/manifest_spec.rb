require_relative "../spec_helper.rb"

describe CfObsBinaryBuilder::Manifest do
  let(:manifest_path) { File.expand_path("../fixtures/ruby-buildpack-manifest.yml", __dir__) }
  subject { described_class.new(manifest_path) }

  before(:each) do
    allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?) do |obj|
      obj.name != "bundler-1.16.2"
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
      allow_any_instance_of(described_class).to receive(:dependency_for).and_wrap_original do |original, *args|
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

  describe "#populate!" do
    it "fails if some dependencies are not available yet" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?) do |obj|
        obj.name != "bundler-1.16.2"
      end

      expect(subject.populate!).to be(false)
    end

    it "adds dependencies for sle12 and opensuse42" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?).and_return(true)
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:build_succeeded?).and_return(true)
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:artifact_checksum).and_return("abcde12345")

      subject.populate!

      stack_deps = described_class::BUILD_STACKS.map do |stack|
        subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?(stack) }.map { |d| d["name"] }
      end

      (1..(stack_deps.count-1)).each do |index|
        expect(stack_deps[index]).to eq(stack_deps[0])
      end
    end
  end
end
