class CfObsBinaryBuilder::Node < CfObsBinaryBuilder::BaseDependency
  def initialize(version, checksum)
    super(
      "node",
      version,
      "https://nodejs.org/dist/v#{version}/node-v#{version}.tar.gz",
      checksum
    )
  end
end
