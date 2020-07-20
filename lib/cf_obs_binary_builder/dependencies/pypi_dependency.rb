# pypi dependencies are python dependencies which are hosted on pypi.org
class CfObsBinaryBuilder::PypiDependency < CfObsBinaryBuilder::NonBuildDependency
  def initialize(dependency, version, license, url)
    @dependency = dependency
    @version = version

    super(dependency, version, pypi_source, license, url)
  end

  private

  def pypi_source
    parse_pypi_url(dependency, version)
  end

  def parse_pypi_url(dependency, version)
    html = URI.open("https://pypi.org/project/#{dependency}/#{version}/#files").read
    url = html.scan(/(https:\/\/.*?#{dependency}-#{version}\.(zip|tar.gz))/).flatten.first

    raise "Failed to find download URL for #{dependency} #{version}" unless url
    url
  end
end
