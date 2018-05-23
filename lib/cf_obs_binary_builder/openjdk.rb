class CfObsBinaryBuilder::Openjdk < CfObsBinaryBuilder::Dependency
  attr_reader :minor_version, :update_version, :build_number

  def initialize(version, checksum)
    @minor_version, @update_version, @build_number = version.match(/jdk(\d)u(\d+)-b(\d+)/).captures
    super(
      "openjdk",
      version
    )
  end

  def fetch_sources
    # noop - the sources are fetched from the hg repository
  end

  def write_sources_yaml
    # noop - the sources are fetched from the hg repository
  end

  def validate_checksum
    # noop - the sources are fetched from the hg repository
  end

  def prepare_files
    super

    log "Cloning the openjdk repository..."
    `hg clone http://hg.openjdk.java.net/jdk8u/jdk8u`

    Dir.chdir "jdk8u" do
      `chmod +x common/bin/hgforest.sh configure get_source.sh`
      `./get_source.sh`
      `./common/bin/hgforest.sh checkout #{version}`
    end

    `tar cfJ #{version}.tar.xz jdk8u --exclude=\.hg`
  end
end
