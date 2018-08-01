class CfObsBinaryBuilder::GoBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(version)
    super("go", version)
  end
end
