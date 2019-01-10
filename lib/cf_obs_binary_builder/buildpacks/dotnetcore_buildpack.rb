class CfObsBinaryBuilder::DotnetcoreBuildpack < CfObsBinaryBuilder::BaseBuildpack

  def initialize(upstream_version, revision)
    super("dotnet-core", upstream_version, revision)
  end

  # Render specific template for dotnet-* which filters the base_dependencies
  # from BuildRequires
  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/../templates/buildpack-dotnet-based.spec.erb"))
    ERB.new(spec_template).result(binding)
  end
  #
  # def run
  #   @manifest = prepare_sources
  #   populate_result = @manifest.populate!(s3_bucket)
  #   return populate_result unless populate_result == :succeeded
  #
  #   @manifest.write("manifest.yml")
  #
  #   update_source_tarball
  #   log 'Done!'
  #   system("mv *.tar.gz /var/tmp/cf_obs_binary_builder/")
  #
  #   :succeeded
  # end
end
