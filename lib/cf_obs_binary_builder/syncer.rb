class CfObsBinaryBuilder::Syncer
  attr_reader :manifest_path

  UPSTREAM_STACK="cflinuxfs2"

  def initialize(manifest_path)
    @manifest_path = manifest_path
  end

  # Returns a list of unknown dependencies (for which a class should be created)
  def sync
    missing, unknown = missing_deps
    missing.each do |dep|
      puts "Creating package for #{dep.package_name}"
      checksum = CfObsBinaryBuilder::Checksum.for(dep.dependency, dep.version)
      dep.run(checksum)
    end

    return unknown
  end

  def missing_deps
    dependencies = stack_dependencies_from_manifest
    missing_deps = []
    unknown_deps = []

    dependencies.each do |hash|
      dep = dependency_for(hash)
      if dep
        puts "Checking if #{dep.package_name} exists"
        if !dep.obs_package.exists?
          missing_deps << dep
        else
          puts "Already exists"
        end
      else
        unknown_deps << hash["name"]
      end
    end

    [missing_deps, unknown_deps.uniq]
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

    dep_class.nil? ? nil : dep_class.new(version)
  end
end
