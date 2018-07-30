class CfObsBinaryBuilder::Yarn < CfObsBinaryBuilder::NonBuildDependency
  def initialize(version)
    super(
      "yarn",
      version,
      "https://yarnpkg.com/downloads/#{version}/yarn-v#{version}.tar.gz",
      "BSD-2-Clause",
      "https://yarnpkg.com"
    )
  end
end
