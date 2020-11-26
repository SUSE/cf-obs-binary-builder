class CfObsBinaryBuilder::Libunwind < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    source = "http://download.savannah.gnu.org/releases/libunwind/libunwind-#{version}.tar.gz"
    # fix cases where the version is reported as for example 1.5 while it is 1.5.0
    if version.count('.') == 1
      source = source.gsub(version, "#{version}.0")
    end

    super(
      "libunwind",
      version,
      source
    )
  end
end
