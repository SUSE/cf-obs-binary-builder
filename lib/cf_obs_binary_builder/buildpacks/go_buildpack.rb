class CfObsBinaryBuilder::GoBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(upstream_version, revision)
    super("go", upstream_version, revision)
  end
end
