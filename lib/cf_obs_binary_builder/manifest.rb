class CfObsBinaryBuilder::Manifest
  attr_reader :path, :hash

  BASE_STACK = ENV["BASE_STACK"].to_s
  BUILD_STACKS = ENV["BUILD_STACKS"].to_s.split(',').sort

  def initialize(path)
    if BUILD_STACKS.empty?
      raise "no BUILD_STACKS environment variable set"
    end
    if BASE_STACK.empty?
      raise "no BASE_STACK environment variable set"
    end
    @path = path
    @hash = YAML.load_file(path)
  end

  def filter_dependencies
    hash['dependencies'].delete_if do |d|
      dep = dependency_for(d)
      if d["uri"].include?("buildpacks.cloudfoundry.org") && dep
        if dep.respond_to?('needs_to_be_filtered') && dep.needs_to_be_filtered(@hash)
          true
        end
      end
    end
  end

  def dependencies
    return @dependencies if @dependencies

    filter_dependencies()

    missing_deps = []
    unknown_deps = []
    existing_deps = []
    third_party_deps = []

    base_dependencies.each do |dep_hash|
      print "Checking #{dep_hash["name"]}-#{dep_hash["version"]}..."
      if dep_hash["uri"].include?("buildpacks.cloudfoundry.org")
        dep = dependency_for(dep_hash)
        if dep
          if !dep.obs_package.exists?
            if !dep.respond_to?('ignore_missing') or (dep.respond_to?('ignore_missing') and !dep.ignore_missing)
              puts " doesn't exist"
              missing_deps << dep
            else
              puts "skipping"
            end
          else
            puts " exists"
            existing_deps << dep
          end
        else
          puts " unknown dependency"
          unknown_deps << dep_hash["name"]
        end
      else
        puts " third-party dependency"
        third_party_deps << dep_hash["name"]
      end
    end

    @dependencies = [existing_deps, missing_deps, unknown_deps.uniq, third_party_deps]
  end

  def add_dependency(dependency, s3_bucket)
    (BUILD_STACKS-[BASE_STACK]).each do |stack|
      # FIXME: satisfies_check should be done when filtering the dependency list
      if (dependency.obs_package.respond_to?('satisfies_stack') && dependency.obs_package.satisfies_stack(stack)) || !dependency.obs_package.respond_to?('satisfies_stack')
        artifact = dependency.obs_package.artifact(stack, s3_bucket)
        dependency_manifest_name = name_to_manifest(dependency.dependency)
        element = {
          "name" => dependency_manifest_name,
          "version" => dependency.version,
          "uri" => artifact[:uri],
          "sha256" => artifact[:checksum],
          "cf_stacks" => [stack]
        }
        if dependency_manifest_name == "php"
          element["modules"] = artifact[:modules]
        end
        hash["dependencies"] << element
      end
    end
  end

  #FIXME: unstink this
  def populate!(s3_bucket)
    existing, missing, unknown, third_party = dependencies

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
        add_dependency(dependency, s3_bucket)
      else
        raise "Unknown build status: #{build_status}"
      end
    end

    third_party.each do |dependency|
      original = hash["dependencies"].find { |d| d["name"] == dependency }
      original["cf_stacks"] += (BUILD_STACKS-[BASE_STACK])
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
      dep_class = CfObsBinaryBuilder.get_build_target("CfObsBinaryBuilder::#{hash_from_manifest["name"].capitalize.tr("-","")}")
    end

    dep_class.nil? ? nil : dep_class.new(version)
  end
end
