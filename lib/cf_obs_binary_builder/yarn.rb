class CfObsBinaryBuilder::Yarn < CfObsBinaryBuilder::NonBuildDependency
  def initialize(version, checksum)
    super(
      "yarn",
      version,
      checksum,
      "https://yarnpkg.com/downloads/#{version}/yarn-v#{version}.tar.gz",
      "BSD-2-Clause"
    )
  end
end
