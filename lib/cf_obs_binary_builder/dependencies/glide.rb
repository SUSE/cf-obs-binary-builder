class CfObsBinaryBuilder::Glide < CfObsBinaryBuilder::GoDependency
  def initialize(version, checksum)
    super(
      "glide",
      version,
      "https://github.com/Masterminds/glide/archive/#{version}.tar.gz",
      checksum
    )
  end
end
