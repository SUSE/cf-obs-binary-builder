class CfObsBinaryBuilder::Glide < CfObsBinaryBuilder::GoDependency
  def initialize(version)
    super(
      "glide",
      version,
      "https://github.com/Masterminds/glide/archive/#{version}.tar.gz"
    )
  end
end
