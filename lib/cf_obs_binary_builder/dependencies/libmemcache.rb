class CfObsBinaryBuilder::Libmemcache < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "libmemcache",
      version,
      "https://launchpad.net/libmemcached/1.0/#{version}/+download/libmemcached-#{version}.tar.gz"
    )
  end
end
