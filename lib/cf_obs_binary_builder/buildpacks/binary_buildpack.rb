class CfObsBinaryBuilder::BinaryBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(upstream_version, revision)
    super("binary", upstream_version, revision)
  end
end
