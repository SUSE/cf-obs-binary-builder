class CfObsBinaryBuilder::Libffi < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "libffi",
      version,
      "https://sourceware.org/pub/libffi/libffi-#{version}.tar.gz"
    )
  end

  def prepare_sources
    super

    patch_url = "https://raw.githubusercontent.com/p3ck/restraint/master/third-party/libffi-3.1-toolexeclibdir.patch"
    File.write(File.basename(patch_url), URI.open(patch_url).read)
  end
end
