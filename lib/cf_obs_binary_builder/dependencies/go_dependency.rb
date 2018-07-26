# Go dependencies need an import path like e.g. github.com/golang/dep
class CfObsBinaryBuilder::GoDependency < CfObsBinaryBuilder::BaseDependency
  attr_reader :import_path

  def initialize(dependency, version, source, checksum)
    @import_path = source[/^https:\/\/(.*)\/archive\/v/, 1]

    super(dependency, version, source, checksum)
  end

  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/../templates/go-dependency.spec.erb"))
    ERB.new(spec_template).result(binding)
  end
end
