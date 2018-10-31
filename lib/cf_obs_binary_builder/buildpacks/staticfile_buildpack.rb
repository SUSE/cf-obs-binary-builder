class CfObsBinaryBuilder::StaticfileBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(upstream_version, revision)
    super("staticfile", upstream_version, revision)
  end
end
