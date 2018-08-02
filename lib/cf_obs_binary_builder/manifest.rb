class CfObsBinaryBuilder::Manifest
  attr_reader :path, :hash

  BASE_STACK = "cflinuxfs2"
  BUILD_STACKS = [ "cflinuxfs2", "sle12", "opensuse42" ]

  def initialize(path)
    @path = path
    @hash = YAML.load_file(path)
  end

  def dependencies
    return @dependencies if @dependencies

    missing_deps = []
    unknown_deps = []
    existing_deps = []

    base_dependencies.each do |dep_hash|
      print "Checking #{dep_hash["name"]}-#{dep_hash["version"]}..."
      dep = dependency_for(dep_hash)
      if dep
        if !dep.obs_package.exists?
          puts " doesn't exist"
          missing_deps << dep
        else
          puts " exists"
          existing_deps << dep
        end
      else
        puts " unknown dependency"
        unknown_deps << dep_hash["name"]
      end
    end

    @dependencies = [existing_deps, missing_deps, unknown_deps.uniq]
  end

  def populate!
    existing, missing, unknown = dependencies

    if missing.any? || unknown.any?
      missing_deps = missing.map(&:package_name).join(", ")
      unknown_deps = unknown.join(", ")
      raise("Missing or unknown dependencies encountered.\nMissing: #{missing_deps}\nUnknown: #{unknown_deps}")
    end

    existing.each do |dependency|
      print "Checking #{dependency.package_name}... "

      build_status = dependency.obs_package.build_status

      case build_status
      when :failed
        puts "failed"
        return :failed
      when :in_process
        puts "in process"
        return :in_process
      when :succeeded
        puts "available"
        (BUILD_STACKS-[BASE_STACK]).each do |stack|
          artifact = dependency.obs_package.artifact(stack)

          hash["dependencies"] << {
            "name" => name_to_manifest(dependency.dependency),
            "version" => dependency.version,
            "uri" => artifact[:uri],
            "sha256" => artifact[:checksum],
            "cf_stacks" => [stack]
          }
        end
      else
        raise "Unknown build status: #{build_status}"
      end
    end

    :succeeded
  end

  def write(path)
    File.write(path, hash.to_yaml)
  end

  private

  def base_dependencies
    hash["dependencies"].select{ |d| d["cf_stacks"].include?(BASE_STACK) }
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

  def name_to_manifest(name)
    name == "openjdk" ? "openjdk1.8-latest" : name
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

