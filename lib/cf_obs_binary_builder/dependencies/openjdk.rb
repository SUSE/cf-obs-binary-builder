class CfObsBinaryBuilder::Openjdk < CfObsBinaryBuilder::SCMDependency
  attr_reader :minor_version, :update_version, :build_number

  def initialize(version, checksum)
    @minor_version, @update_version, @build_number = version.match(/jdk(\d)u(\d+)-b(\d+)/).captures
    super(
      "openjdk",
      version,
      {
        scm_type: "mercurial",
        url: "http://hg.openjdk.java.net/jdk8u/jdk8u",
        tag: version
      }
    )
  end

  def prepare_sources
    log "Download ca bundle..."
    system("curl -L https://curl.haxx.se/ca/cacert.pem  > cacerts.pem")

    log "Cloning the openjdk repository..."
    system("hg clone http://hg.openjdk.java.net/jdk8u/jdk8u")
    Dir.chdir "jdk8u" do
      system("chmod +x common/bin/hgforest.sh configure get_source.sh")
      system("./get_source.sh")
      system("./common/bin/hgforest.sh checkout #{version}")
    end

    log "Creating tarball..."
    system("tar cfJ #{version}.tar.xz jdk8u --exclude=\.hg")
  end
end
