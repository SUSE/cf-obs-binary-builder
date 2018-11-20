class CfObsBinaryBuilder::Syncer
  attr_reader :manifest

  def initialize(manifest_path)
    @manifest = CfObsBinaryBuilder::Manifest.new(manifest_path)
  end

  # Returns a list of unknown dependencies (for which a class should be created)
  def sync
    existing, missing, unknown = manifest.dependencies

    # Regenerate existing packages to make sure that they got all the new spec
    # changes and extensions
    # Our OBS project is setup that old buildpacks are not rebuild when their
    # dependencies change (rebuild="local")
    existing.each do |dep|
      puts "Syncing dependency #{dep.package_name}"
      begin
        checksum = CfObsBinaryBuilder::Checksum.for(dep.dependency, dep.version)
      rescue JSON::ParserError
        puts "Depwatcher does not support this dependency anymore, it will not be regenerated."
      else
        dep.regenerate(checksum)
      end
    end

    missing.each do |dep|
      puts "Creating package for #{dep.package_name}"
      checksum = CfObsBinaryBuilder::Checksum.for(dep.dependency, dep.version)
      dep.run(checksum)
    end

    return unknown
  end

  # Re-generates the spec files for all (existing) dependencies on OBS.
  # Should be only used when it is sure that nothing but the spec has
  # changed in any of the dependencies
  def regenerate_specs
    existing_deps, _, _ = manifest.dependencies

    existing_deps.each do |dep|
      dep.regenerate_spec
    end
  end
end
