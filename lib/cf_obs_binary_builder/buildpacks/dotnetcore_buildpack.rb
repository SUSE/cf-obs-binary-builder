# DotnetcoreBuildpack represent a specific case of a Golang based Buildpack.
class CfObsBinaryBuilder::DotnetcoreBuildpack < CfObsBinaryBuilder::BaseBuildpack

  def initialize(upstream_version, revision)
    super('dotnet-core', upstream_version, revision)
  end
end
