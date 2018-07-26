class CfObsBinaryBuilder::Go < CfObsBinaryBuilder::BaseDependency
  def initialize(version, checksum)
    super(
      "go",
      version,
      "https://storage.googleapis.com/golang/go#{version}.src.tar.gz",
      checksum
    )
  end
end
