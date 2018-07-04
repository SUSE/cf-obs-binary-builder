class CfObsBinaryBuilder::Rubygems < CfObsBinaryBuilder::NonBuildDependency
  def initialize(version, checksum)
    super(
      "rubygems",
      version,
      "https://rubygems.org/rubygems/rubygems-#{version}.tgz",
      checksum,
      "Ruby",
      "https://rubygems.org"
    )
  end
end
