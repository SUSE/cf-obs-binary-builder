class CfObsBinaryBuilder::Nginx < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "nginx",
      version,
      "http://nginx.org/download/nginx-#{version}.tar.gz"
    )
  end
end
