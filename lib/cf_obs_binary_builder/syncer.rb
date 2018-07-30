class CfObsBinaryBuilder::Syncer
  attr_reader :manifest_path

  UPSTREAM_STACK="cflinuxfs2"

  def initialize(manifest_path)
    @manifest_path = manifest_path
  end

  def sync
    missing_deps.each do |dep|
      checksum = CfObsBinaryBuilder::Checksum.for(dep.dependency, dep.version)
      dep.run(checksum)
    end
  end

  def missing_deps
    dependencies = stack_dependencies_from_manifest
    dependencies
      .map { |hash| dependency_for(hash) }
      .select { |dep| !dep.obs_package.exists? }
  end

  private

  def stack_dependencies_from_manifest
    dependencies = YAML.load_file(manifest_path)["dependencies"]
    dependencies = dependencies.select{ |d| d["cf_stacks"].include?(UPSTREAM_STACK) }
  end

  def find_latest_jdk_build(minor_version, update_version)
    openjdk_html = open("http://hg.openjdk.java.net/jdk8u/jdk8u/tags").read
    openjdk_html.scan(/jdk#{minor_version}u#{update_version}-b(\d+)/).flatten.map(&:to_i).max
  end

  def version_from_manifest(dep_hash)
    if dep_hash["name"] == "openjdk1.8-latest"
      minor_version = 8
      update_version = dep_hash["uri"][/openjdk-1.8.0_(\d+)-/, 1]
      build = find_latest_jdk_build(minor_version, update_version)
      "jdk#{minor_version}u#{update_version}-b#{build}"
    else
      dep_hash["version"]
    end
  end

  def dependency_for(hash_from_manifest)
    version = version_from_manifest(hash_from_manifest)

    if hash_from_manifest["name"] == "openjdk1.8-latest"
      dep_class = CfObsBinaryBuilder::Openjdk
    else
      dep_class = CfObsBinaryBuilder.get_build_target("CfObsBinaryBuilder::#{hash_from_manifest["name"].capitalize}")
    end
    dependency = dep_class.new(version)
  end
end
