class CfObsBinaryBuilder::Libmemcache < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "libmemcache",
      version,
      "https://launchpad.net/libmemcached/1.0/#{version}/+download/libmemcached-#{version}.tar.gz"
    )
  end

  def prepare_sources
    super

    additional_source = "https://www.cyrusimap.org/releases/cyrus-sasl-2.1.26.tar.gz"
    log "Downloading the sources in the package directory... (#{additional_source})"
    File.write(File.basename(additional_source), open(additional_source).read)
    if Digest::SHA256.file(File.basename(additional_source)).hexdigest != "8fbc5136512b59bb793657f36fadda6359cae3b08f01fd16b3d406f1345b7bc3"
      raise("Checksum mismatch after download of #{additional_source}")
    end
  end
end
