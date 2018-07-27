class CfObsBinaryBuilder::Syncer
  attr_reader :manifest_path

  UPSTREAM_STACK="cflinuxfs2"

  def initialize(manifest_path)
    @manifest_path = manifest_path
  end


  def missing_deps
    dependencies = stack_dependencies_from_manifest
    dependencies.each do |dep_hash|
      dep = dependency_for(dep_hash)
      if dep.obs_package.exists?
        puts "Package #{dep.package_name} already exists."
      else
        puts "Didn't find package a package for #{dep.package_name} on OBS. Will create it now"
        #dep.run # TODO: Uncomment when we fix the checksum
      end
    end
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

  def dependency_for(hash_from_manifest)
    checksum = "foo" # Checksum.for(dep_hash["name"], dep_hash["version"])

    if hash_from_manifest["name"] == "openjdk1.8-latest"
      minor_version = 8
      update_version = hash_from_manifest["uri"][/openjdk-1.8.0_(\d+)-/, 1]
      build = find_latest_jdk_build(minor_version, update_version)
      CfObsBinaryBuilder::Openjdk.new("jdk#{minor_version}u#{update_version}-b#{build}", checksum)
    else
      dep_class = CfObsBinaryBuilder.get_build_target("CfObsBinaryBuilder::#{hash_from_manifest["name"].capitalize}")
      dependency = dep_class.new(hash_from_manifest["version"], checksum)
    end
  end
end
