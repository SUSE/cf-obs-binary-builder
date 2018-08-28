class CfObsBinaryBuilder::Libmemcache < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "libmemcache",
      version,
      "https://launchpad.net/libmemcached/1.0/#{version}/+download/libmemcached-#{version}.tar.gz"
    )
  end

  def prepare_sources
    additional_source = "https://www.cyrusimap.org/releases/cyrus-sasl-2.1.26.tar.gz"
    download_source(additional_source)
    verify_checksum(additional_source, "8fbc5136512b59bb793657f36fadda6359cae3b08f01fd16b3d406f1345b7bc3")

    super
  end
end
