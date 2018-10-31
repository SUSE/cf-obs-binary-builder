class CfObsBinaryBuilder::NodejsBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(upstream_version, revision)
    super("nodejs", upstream_version, revision)
  end
end
