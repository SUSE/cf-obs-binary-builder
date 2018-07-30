class CfObsBinaryBuilder::Go < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "go",
      version,
      "https://storage.googleapis.com/golang/go#{version}.src.tar.gz"
    )
  end
end
