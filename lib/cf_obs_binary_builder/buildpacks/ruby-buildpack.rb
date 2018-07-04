class CfObsBinaryBuilder::RubyBuildpack < CfObsBinaryBuilder::Buildpack
  def initialize(version)
    super("ruby", version)
  end
end
