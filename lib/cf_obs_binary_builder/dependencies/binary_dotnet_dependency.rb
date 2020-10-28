# non-build dependencies are simple dependencies where the source artifact is
# simply copied without any compilation or transformation steps.
class CfObsBinaryBuilder::BinaryDotnetDependency < CfObsBinaryBuilder::BaseDependency
  attr_reader :license, :url

  def initialize(dependency, version, source, license, url)
    @license = license
    @url = url

    super(dependency, version, source)
  end

  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/../templates/binary-dotnet-dependency.spec.erb"))
    ERB.new(spec_template).result(binding)
  end
end
