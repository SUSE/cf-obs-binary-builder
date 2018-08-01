class CfObsBinaryBuilder::RubyBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(upstream_version, revision)
    super("ruby", upstream_version, revision)
  end
end
