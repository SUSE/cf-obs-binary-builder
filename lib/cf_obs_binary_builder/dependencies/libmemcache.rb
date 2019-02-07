class CfObsBinaryBuilder::Libmemcache < CfObsBinaryBuilder::BaseDependency
  attr_reader :patches
  def initialize(version)
    # NOTE: Those patches are for sle15 only, the template spec applies them only when built against SLE15
    @patches = ["libmemcached-gcc7-build.patch"]
    super(
      "libmemcache",
      version,
      "https://launchpad.net/libmemcached/1.0/#{version}/+download/libmemcached-#{version}.tar.gz"
    )
  end

  def run(verification_data)
    basepath = FileUtils.pwd
    obs_package.create
    obs_package.checkout do
      copy_patches()
      generate_package(verification_data)
    end
  end

  def prepare_sources
    super
    copy_patches()
  end

  def copy_patches()
    log 'Copying patches'
    for patch in patches do
      FileUtils.cp(File.dirname(__FILE__) + "/../templates/patches/#{patch}",".")
    end
  end
end
