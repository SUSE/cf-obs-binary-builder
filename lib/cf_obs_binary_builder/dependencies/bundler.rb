class CfObsBinaryBuilder::Bundler < CfObsBinaryBuilder::Dependency
  def initialize(version, checksum)
    super(
      "bundler",
      version,
      "http://rubygems.org/gems/bundler-#{version}.gem",
      checksum,
      "https://bundler.io"
    )
  end
end
