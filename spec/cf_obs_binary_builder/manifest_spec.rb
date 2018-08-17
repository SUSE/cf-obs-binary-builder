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

    it "return third-party dependencies" do
      _, _, _, third_party_deps = subject.dependencies

      expect(third_party_deps).to eq(["Miniconda2"])
    end
  end

  describe "#populate!" do
    it "raises if some dependencies are missing or unknown" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?) do |obj|
        obj.name != "bundler-1.16.2"
      end
      allow_any_instance_of(described_class).to receive(:dependency_for).and_wrap_original do |original, *args|
        if args[0]["name"] == "node"
          nil
        else
          original.call(*args)
        end
      end

      expect { subject.populate!("buildpacks-staging") }.to raise_error(/Missing: bundler-1.16.2.*Unknown: node/m)
    end

    it "adds dependencies for sle12 and opensuse42" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?).and_return(true)
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:build_status).and_return(:succeeded)
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:artifact).and_return({uri: "https://foo", checksum: "abcde12345"})

      subject.populate!("buildpacks-staging")

      stack_deps = described_class::BUILD_STACKS.map do |stack|
        subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?(stack) }.map { |d| d["name"] }
      end

      (1..(stack_deps.count-1)).each do |index|
        expect(stack_deps[index]).to match_array(stack_deps[0])
      end
    end
  end
end
