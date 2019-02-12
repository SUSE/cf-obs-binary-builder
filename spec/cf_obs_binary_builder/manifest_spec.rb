require_relative "../spec_helper.rb"

describe CfObsBinaryBuilder::Manifest do
  let(:base_stack) { "cflinuxfs2" }
  let(:build_stacks) { ["sle12","opensuse42"] }
  let(:manifest_path) { File.expand_path("../fixtures/ruby-buildpack-manifest.yml", __dir__) }
  subject { described_class.new(manifest_path) }

  before(:each) do
    allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?) do |obj|
      obj.name != "bundler-1.17.3"
    end
  end

  describe "#dependencies" do
    it "returns missing dependencies" do
      _, missing_deps, _ = subject.dependencies(base_stack)
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
      _, _, unknown_deps = subject.dependencies(base_stack)

      expect(unknown_deps).to eq(["bundler"])
    end

    it "return third-party dependencies" do
      _, _, _, third_party_deps = subject.dependencies(base_stack)

      expect(third_party_deps).to eq(["Miniconda2"])
    end
  end

  describe "#dependencies_for_stack" do
    it "returns dependencies for the given stack" do
      _, missing_deps, _ = subject.dependencies(base_stack)
      expect(missing_deps.length).to eq(1)
      expect(missing_deps.first).to be_a(CfObsBinaryBuilder::Bundler)
      expect(missing_deps.first.version).to eq("1.17.3")
    end
  end

  describe "#populate!" do
    let(:stack_mappings) do
      { 'sle12' => 'cflinuxfs2', 'opensuse42' => 'cflinuxfs2', 'cfsle15fs' => 'cflinuxfs3' }
    end

    it "raises if some dependencies are missing or unknown" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?) do |obj|
        obj.name != "bundler-1.17.3"
      end
      allow_any_instance_of(described_class).to receive(:dependency_for).and_wrap_original do |original, *args|
        if args[0]["name"] == "node"
          nil
        else
          original.call(*args)
        end
      end

      expect { subject.populate!(stack_mappings, "buildpacks-staging") }.to raise_error(/Missing: bundler-1.17.3.*Unknown: node/m)
    end

    it "adds dependencies for sle12 and opensuse42" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?).and_return(true)
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:build_status).and_return(:succeeded)
      # The only dependency where the uri is important it openjdk (to find the "update" version).
      # Stub it to this value for every dependency to avoid calling the internetz from the tests.
      # The uri value should match the one from the fixture manifest yml file.
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:artifact).and_return(
        {
          uri: "https://buildpacks.cloudfoundry.org/dependencies/manual-binaries/jruby/openjdk-1.8.0_192-6254bacb.tar.gz",
          checksum: "abcde12345"
        })

      subject.populate!(stack_mappings, "buildpacks-staging")
      base_stack_deps = subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?("cflinuxfs2") }.map { |d| "#{d["name"]}-#{d["version"]}" }
      # TODO: Remove the gsub hack when we remove the OBS part from the openjdk version
      added_stack_deps = subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?("sle12") }.map { |d| "#{d["name"]}-#{d["version"]}".gsub(/_\d{3}$/,"") }
      expect(base_stack_deps.sort).to eq(added_stack_deps.sort)

      added_stack_deps = subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?("opensuse42") }.map { |d| "#{d["name"]}-#{d["version"]}".gsub(/_\d{3}$/,"")  }
      expect(base_stack_deps.sort).to eq(added_stack_deps.sort)

      base_stack_deps = subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?("cflinuxfs3") }.map { |d| "#{d["name"]}-#{d["version"]}" }
      added_stack_deps = subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?("cfsle15fs") }.map { |d| "#{d["name"]}-#{d["version"]}".gsub(/_\d{3}$/,"") }
      expect(base_stack_deps.sort).to eq(added_stack_deps.sort)
    end

    it "leaves the base stack dependencies intact" do
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:exists?).and_return(true)
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:build_status).and_return(:succeeded)
      allow_any_instance_of(CfObsBinaryBuilder::ObsPackage).to receive(:artifact).and_return(
        {
          uri: "https://buildpacks.cloudfoundry.org/dependencies/manual-binaries/jruby/openjdk-1.8.0_192-6254bacb.tar.gz",
          checksum: "abcde12345"
        })


      base_stack_deps_before = subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?("cflinuxfs2") }.map { |d| "#{d["name"]}-#{d["version"]}" }
      subject.populate!(stack_mappings, "buildpacks-staging")
      base_stack_deps_after = subject.hash["dependencies"].
          select { |d| d["cf_stacks"].include?("cflinuxfs2") }.map { |d| "#{d["name"]}-#{d["version"]}" }
      expect(base_stack_deps_before.sort).to eq(base_stack_deps_after.sort)
    end
  end
end
