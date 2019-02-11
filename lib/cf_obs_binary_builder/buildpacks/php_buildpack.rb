class CfObsBinaryBuilder::PhpBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(upstream_version, revision)
    super("php", upstream_version, revision)
  end

  def render_spec_template(dependencies)
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/../templates/buildpack-ruby-based.spec.erb"))
    ERB.new(spec_template).result(binding)
  end
end
