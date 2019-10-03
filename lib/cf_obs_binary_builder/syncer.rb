class CfObsBinaryBuilder::Syncer
  attr_reader :manifest

  def initialize(manifest_path)
    @manifest = CfObsBinaryBuilder::Manifest.new(manifest_path)
  end

  # Returns a list of unknown dependencies (for which a class should be created)
  def sync(base_stacks, package_statuses)
    existing_dependencies, missing_dependencies, unknown_dependencies = unique_deps_for_stacks(base_stacks, package_statuses)

    # Regenerate existing packages to make sure that they got all the new spec
    # changes and extensions
    # Our OBS project is setup that old buildpacks are not rebuild when their
    # dependencies change (rebuild="local")
    existing_dependencies.each do |dep|
      can_generate_checksum = dep.respond_to?('generate_checksum')
      next if can_generate_checksum

      puts "Syncing dependency #{dep.package_name}"
      begin
        checksum = CfObsBinaryBuilder::Checksum.for(dep.dependency, dep.version)
      rescue JSON::ParserError
        puts 'Depwatcher does not support this dependency anymore, it will not be regenerated.'
      else
        dep.regenerate(checksum)
      end
    end

    missing_dependencies.each do |dep|
      can_generate_checksum = dep.respond_to?('generate_checksum')
      next if can_generate_checksum

      puts "Creating package for #{dep.package_name}"
      begin
        checksum = CfObsBinaryBuilder::Checksum.for(dep.dependency, dep.version)
      rescue JSON::ParserError
        puts "Depwatcher does not support this dependency anymore and we have to checksum to validate. Will continue without validation."
        checksum = nil
      end

      dep.run(checksum)
    end

    return unknown_dependencies
  end

  # Re-generates the spec files for all (existing) dependencies on OBS.
  # Should be only used when it is sure that nothing but the spec has
  # changed in any of the dependencies
  def regenerate_specs(base_stacks, package_statuses)
    existing_deps, _, _ = unique_deps_for_stacks(base_stacks, package_statuses)

    existing_deps.each do |dep|
      dep.regenerate_spec
    end
  end

  private

  def unique_deps_for_stacks(base_stacks, package_statuses)
    existing_dependencies, missing_dependencies, unknown_dependencies = [],[],[]

    base_stacks.each do |base_stack|
      existing, missing, unknown = manifest.dependencies(base_stack, package_statuses)
      existing_dependencies += existing
      missing_dependencies += missing
      unknown_dependencies += unknown
    end

    [existing_dependencies, missing_dependencies, unknown_dependencies].each do |collection|
      collection.uniq!{|dep| "#{dep.dependency}-#{dep.version}"}
    end

    return existing_dependencies, missing_dependencies, unknown_dependencies
  end
end
