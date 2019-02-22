class CfObsBinaryBuilder::Manifest
  attr_reader :path, :hash

  def initialize(path)
    @path = path
    @hash = YAML.load_file(path)
  end

  # Given a stack, this method returns 4 Arrays containing:
  # - missing_deps: dependencies for which we don't have a package
  # - unknown_deps: dependencies for which we don't have a class (so we don't know how to build them)
  # - existing_deps: dependencies for which we already have a package
  # - third_party_deps: dependencies which are not hosted on upstream buckets (meaning upstream doesn't build them either)
  def dependencies(base_stack, package_statuses)
    @dependencies = {} if @dependencies.nil?
    return @dependencies[base_stack] if @dependencies[base_stack]

    filter_dependencies

    missing_deps = []
    unknown_deps = []
    existing_deps = []
    third_party_deps = []

    dependencies_for_stack(base_stack).each do |dep_hash|
      print "Checking #{dep_hash["name"]}-#{dep_hash["version"]}..."
      if dep_hash["uri"].include?("buildpacks.cloudfoundry.org")
        dep = dependency_for(dep_hash)
        if dep
          # Check in the list of all the packages in package_statuses
          if !dep.obs_package.exists_in_status?(package_statuses)
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

    @dependencies[base_stack] = [existing_deps, missing_deps, unknown_deps.uniq, third_party_deps]
  end

  # This method combines the information from 3 different sources to return
  # one combined status for the whole manifest.
  # package_statuses: the information from OBS regarding packages
  # stack_mappings: the information from the user on which stacks she wants to add
  # dependencies (method): the information from the manifest itself
  def dependencies_status(package_statuses, stack_mappings)
    stack_mappings.each do |stack, base_stack|
      existing, missing, unknown, third_party = dependencies(base_stack, package_statuses)

      if missing.any? || unknown.any?
        missing_deps = missing.map(&:package_name).join(", ")
        unknown_deps = unknown.join(", ")
        raise("Missing or unknown dependencies encountered.\nMissing: #{missing_deps}\nUnknown: #{unknown_deps}")
      end

      existing.each do |dependency|
        print "#{dependency.package_name}: "
        build_status = dependency.obs_package.build_status_in_package_statuses(stack, package_statuses)

        case build_status
        when :failed
          puts "failed"
          return :failed
        when :in_process
          puts "in process"
          return :in_process
        when :signing
          puts "signing"
          return :in_process
        when :finished
          puts "finished"
          return :in_process
        when :succeeded
          puts "available"
        else
          raise "Unknown build status: #{build_status}"
        end
      end
    end

    :succeeded
  end

  # This method takes a hash of mappings like the one below, and makes sure that the hash
  # of this manifest, includes dependencies for the stacks in the stack_mappings keys.
  # All other stacks in the manifest stays untouched.
  # E.g. Given a manifest with cflinuxfs3 and cflinuxfs2 and the stack_mapppings below,
  # the final manifest should have cflinuxfs2 and cflinuxfs3 deps untouched and the same deps as cflinuxfs2 for
  # sle12 and opensuse42 and the same deps as cflinuxfs3 for sle15 (sle15).
  # Example stack_mappings:
  #{
  #  "sle12": "cflinuxfs2",
  #  "opensuse42": "cflinxufs2",
  #  "sle15": "cflinuxfs3"
  #}
  # The s3_bucket is the bucket that hosts the dependencies built in OBS and is
  # needed in order to construct the urls for the deps.
  # Before calling this method, the `dependencies_status` method has to be called
  # to make sure all the dependencies are available.
  # This method assumes all dependencies exist on OBS and they build successfully
  # for their respective stacks.
  def populate!(stack_mappings, package_statuses, s3_bucket)
    stack_mappings.each do |stack, base_stack|
      existing, missing, unknown, third_party = dependencies(base_stack, package_statuses)

      existing.each do |dependency|
        add_dependency(dependency, stack, s3_bucket)
      end

      third_party.each do |dependency|
        original = hash["dependencies"].find { |d| d["name"] == dependency }
        original["cf_stacks"] = original["cf_stacks"] | [stack]
      end
    end
  end

  def write(path)
    File.write(path, hash.to_yaml)
  end

  private

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

  def add_dependency(dependency, stack, s3_bucket)
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

  def dependencies_for_stack(stack)
    puts "==== Checking dependencies for stack #{stack} ===="
    hash["dependencies"].select{ |d| d["cf_stacks"].include?(stack) }
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
