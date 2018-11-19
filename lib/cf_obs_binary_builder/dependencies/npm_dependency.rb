# npm dependencies are nodejs dependencies which are hosted on registry.npmjs.org
class CfObsBinaryBuilder::NpmDependency < CfObsBinaryBuilder::NonBuildDependency
  def initialize(dependency, version, license, url)
    @dependency = dependency
    @version = version

    super(
      dependency,
      version,
      "https://registry.npmjs.org/#{dependency}/-/#{dependency}-#{version}.tgz",
      license,
      url
    )
  end
end
