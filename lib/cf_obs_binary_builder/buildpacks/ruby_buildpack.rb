class CfObsBinaryBuilder::RubyBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(version)
    super("ruby", version)
  end
end
