class CfObsBinaryBuilder::Dep < CfObsBinaryBuilder::GoDependency
  def initialize(version, checksum)
    super(
      "dep",
      version,
      "https://github.com/golang/dep/archive/#{version}.tar.gz",
      checksum
    )
  end
end
