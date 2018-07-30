class CfObsBinaryBuilder::Node < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "node",
      version,
      "https://nodejs.org/dist/v#{version}/node-v#{version}.tar.gz"
    )
  end
end
