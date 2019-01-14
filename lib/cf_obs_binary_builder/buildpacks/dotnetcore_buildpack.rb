# DotnetcoreBuildpack represent a specific case of a Golang based Buildpack.
class CfObsBinaryBuilder::DotnetcoreBuildpack < CfObsBinaryBuilder::BaseBuildpack

  def initialize(upstream_version, revision)
    super('dotnet-core', upstream_version, revision)
  end

  # Render specific template for dotnet-* which filters the base_dependencies
  # from BuildRequires
  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + '/../templates/buildpack-dotnet-based.spec.erb'))
    ERB.new(spec_template).result(binding)
  end
end
