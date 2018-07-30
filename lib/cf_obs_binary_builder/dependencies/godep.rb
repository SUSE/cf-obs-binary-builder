class CfObsBinaryBuilder::Godep < CfObsBinaryBuilder::GoDependency
  def initialize(version)
    super(
      "godep",
      version,
      "https://github.com/tools/godep/archive/v#{version}.tar.gz"
    )
  end
end
