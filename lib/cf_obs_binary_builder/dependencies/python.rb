class CfObsBinaryBuilder::Python < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "python",
      version,
      "https://www.python.org/ftp/python/#{version}/Python-#{version}.tgz"
    )
  end
end
