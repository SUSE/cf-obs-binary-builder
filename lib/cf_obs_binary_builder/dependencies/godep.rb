class CfObsBinaryBuilder::Godep < CfObsBinaryBuilder::GoDependency
  def initialize(version, checksum)
    super(
      "godep",
      version,
      "https://github.com/tools/godep/archive/#{version}.tar.gz",
      checksum
    )
  end
end
