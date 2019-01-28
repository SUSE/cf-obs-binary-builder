class CfObsBinaryBuilder::Openresty < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "openresty",
      version,
      "https://openresty.org/download/openresty-#{version}.tar.gz"
    )
  end
end
