class CfObsBinaryBuilder::NginxBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(upstream_version, revision)
    super("nginx", upstream_version, revision)
  end
end
