class CfObsBinaryBuilder::DotnetcoreBuildpack < CfObsBinaryBuilder::BaseBuildpack

  def initialize(upstream_version, revision)
    super("dotnet-core", upstream_version, revision)
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
