class CfObsBinaryBuilder::Yarn < CfObsBinaryBuilder::NonBuildDependency
  def initialize(version, checksum)
    super(
      "yarn",
      version,
      "https://yarnpkg.com/downloads/#{version}/yarn-v#{version}.tar.gz",
      checksum,
      "BSD-2-Clause"
    )
  end
end
