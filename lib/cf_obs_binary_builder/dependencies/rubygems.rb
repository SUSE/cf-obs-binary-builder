class CfObsBinaryBuilder::Rubygems < CfObsBinaryBuilder::NonBuildDependency
  def initialize(version)
    super(
      "rubygems",
      version,
      "https://rubygems.org/rubygems/rubygems-#{version}.tgz",
      "Ruby",
      "https://rubygems.org"
    )
  end
end
