require_relative "../spec_helper.rb"

describe CfObsBinaryBuilder::Manifest do
  let(:base_stack) { "cflinuxfs2" }
  let(:build_stacks) { ["sle12"] }
  let(:manifest_path) { File.expand_path("../fixtures/ruby-buildpack-manifest.yml", __dir__) }
  let(:stack_mappings) do
    { 'sle12' => 'cflinuxfs2', 'sle15' => 'cflinuxfs3' }
  end
  let(:small_manifest_path) { File.expand_path("../fixtures/ruby-buildpack-small-manifest.yml", __dir__) }

  subject { described_class.new(manifest_path) }

  before(:each) do
    allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?) do |obj|
      obj.name != "bundler-1.17.3"
    end
  end

  describe "#dependencies_status" do
    subject { described_class.new(small_manifest_path) }

    let(:arg_for_failed) do
      {
        "sle15"=>{"bundler-1.17.3"=>"failed"},
        "sle12"=>{"bundler-1.17.3"=>"failed"}
      }
    end

    let(:arg_for_in_process) do
      {
        "sle15"=>{"bundler-1.17.3"=>"in_process"},
        "sle12"=>{"bundler-1.17.3"=>"failed", }
      }
    end

    let(:arg_for_unknown) do
      {
        "sle15"=>{"bundler-1.17.3"=>"unknown_status"},
        "sle12"=>{"bundler-1.17.3"=>"failed", }
      }
    end

    let(:arg_for_succeeded) do
      {
        "sle15"=>{"bundler-1.17.3"=>"succeeded"},
        "sle12"=>{"bundler-1.17.3"=>"failed", }
      }
    end

    let(:arg_for_unknown) do
      {
        "sle15"=>{"bundler-1.17.3"=>"unknown"},
        "sle12"=>{"bundler-1.17.3"=>"failed", }
      }
    end

    let(:stack_mappings) do
      # sle12 will be ignored because cflinuxfs2 has no deps in the yaml
      { "sle12" => "cflinuxfs2", "sle15" => "cflinuxfs3" }
    end

    it "returns failed when there are failed dependencies" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?).
        and_return(true)

      expect(subject.dependencies_status(arg_for_failed, stack_mappings)).
             to eq(:failed)
    end

    it "returns in_process when there are no failed but in_process dependencies" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?).
        and_return(true)

      expect(subject.dependencies_status(arg_for_in_process, stack_mappings)).
             to eq(:in_process)
    end

    it "returns succeeded when there all dependencies are succeeded" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?).
        and_return(true)

      expect(subject.dependencies_status(arg_for_succeeded, stack_mappings)).
             to eq(:succeeded)
    end

    it "returns in_process when there is a dependency with an unknown status" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?).
        and_return(true)

      expect(subject.dependencies_status(arg_for_unknown, stack_mappings)).
             to eq(:in_process)
    end

    it "raises if some dependencies are missing" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?) do |obj|
        obj.name != "bundler-1.17.3"
      end

      expect { subject.dependencies_status({}, stack_mappings) }.to raise_error(/Missing: bundler-1.17.3/m)
    end

    it "raises if some dependencies are missing" do
      allow_any_instance_of(described_class).to receive(:dependency_for).and_wrap_original do |original, *args|
        if args[0]["name"] == "bundler"
          nil
        else
          original.call(*args)
        end
      end

      expect { subject.dependencies_status(arg_for_succeeded, stack_mappings) }.to raise_error(/Unknown: bundler/m)
    end
  end

  describe "#dependencies" do
    subject { described_class.new(small_manifest_path) }

    let(:package_statuses) do
      { "sle15" => { "bundler-1.17.3" => :succeeded }}
    end
    let(:base_stack) { "cflinuxfs3" }

    it "returns missing dependencies" do
      _, missing_deps, _, _ = subject.dependencies(
        base_stack,
        { "sle15" => { "something-else-2.0" => :succeeded }}
      )
      expect(missing_deps.length).to eq(1)
      expect(missing_deps.first).to be_a(CfObsBinaryBuilder::Bundler)
      expect(missing_deps.first.version).to eq("1.17.3")
    end

    it "returns unknown dependencies" do
      allow_any_instance_of(described_class).to receive(:dependency_for).and_wrap_original do |original, *args|
        if args[0]["name"] == "bundler"
          nil
        else
          original.call(*args)
        end
      end
      _, _, unknown_deps = subject.dependencies(base_stack, package_statuses)

      expect(unknown_deps).to eq(["bundler"])
    end

    it "return third-party dependencies" do
      _, _, _, third_party_deps = subject.dependencies(base_stack, package_statuses)

      expect(third_party_deps).to eq(["Miniconda2"])
    end
  end

  describe "#populate!" do
    subject { described_class.new(small_manifest_path) }
    let(:package_statuses) do
      { "sle15" => { "bundler-1.17.3" => :succeeded }}
    end

    it "adds dependencies for sle12" do
      # The only dependency where the uri is important it openjdk
      # (to find the "update" version). Stub it to this value for every
      # dependency to avoid calling the internetz from the tests.
      # The uri value should match the one from the fixture manifest yml file.
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:artifact).
        and_return({
          uri: "https://buildpacks.cloudfoundry.org/dependencies/manual-binaries/jruby/openjdk-1.8.0_192-6254bacb.tar.gz",
          checksum: "abcde12345"
        })

      subject.populate!(stack_mappings, package_statuses, "buildpacks-staging")

      # TODO: Remove the gsub hack when we remove the OBS part from the openjdk version
      base_stack_deps = subject.hash["dependencies"].
        select { |d| d["cf_stacks"].include?("cflinuxfs3") }.map { |d| "#{d["name"]}-#{d["version"]}" }
      added_stack_deps = subject.hash["dependencies"].
        select { |d| d["cf_stacks"].include?("sle15") }.map { |d| "#{d["name"]}-#{d["version"]}".gsub(/_\d{3}$/,"") }
      expect(base_stack_deps.sort).to eq(added_stack_deps.sort)
    end

    it "leaves the base stack dependencies intact" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:artifact).
        and_return({
          uri: "https://buildpacks.cloudfoundry.org/dependencies/manual-binaries/jruby/openjdk-1.8.0_192-6254bacb.tar.gz",
          checksum: "abcde12345"
        })

      base_stack_deps_before = subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?("cflinuxfs3") }.map { |d| "#{d["name"]}-#{d["version"]}" }
      subject.populate!(stack_mappings, package_statuses, "buildpacks-staging")
      base_stack_deps_after = subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?("cflinuxfs3") }.map { |d| "#{d["name"]}-#{d["version"]}" }
      expect(base_stack_deps_before.sort).to eq(base_stack_deps_after.sort)
    end
  end
end
