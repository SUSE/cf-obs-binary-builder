class CfObsBinaryBuilder::NonBuildDependency < CfObsBinaryBuilder::Dependency
  attr_reader :license, :source

  def initialize(dependency, version, checksum, source, license)
    @dependency = dependency
    @source = source
    @license = license

    super(version, checksum)
  end

  def prepare_files
    File.write(File.basename(source), open(source).read)
    File.write("#{dependency}.spec", render_spec_template)
  end

  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/templates/non-build-dependency.spec.erb"))
    ERB.new(spec_template).result(binding)
  end
end
