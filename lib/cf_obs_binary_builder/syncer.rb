class CfObsBinaryBuilder::Syncer
  attr_reader :manifest

  def initialize(manifest_path)
    @manifest = CfObsBinaryBuilder::Manifest.new(manifest_path)
  end

  # Returns a list of unknown dependencies (for which a class should be created)
  def sync
    _, missing, unknown = manifest.dependencies
    missing.each do |dep|
      puts "Creating package for #{dep.package_name}"
      checksum = CfObsBinaryBuilder::Checksum.for(dep.dependency, dep.version)
      dep.run(checksum)
    end

    return unknown
  end

  # Re-generates the spec files for all (existing) dependencies on OBS.
  # Should be used when something is changed on the dependency templates.
  def regenerate_specs
    existing_deps, _, _ = manifest.dependencies

    existing_deps.each do |dep|
      dep.regenerate_spec
    end
  end
end
