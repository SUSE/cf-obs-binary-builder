class CfObsBinaryBuilder::Bundler < CfObsBinaryBuilder::BaseDependency
  def initialize(version, checksum)
    super(
      "bundler",
      version,
      "http://rubygems.org/gems/bundler-#{version}.gem",
      checksum
    )
  end
end
