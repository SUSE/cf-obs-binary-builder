class CfObsBinaryBuilder::Libunwind < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "libunwind",
      version,
      "http://download.savannah.gnu.org/releases/libunwind/libunwind-#{version}.tar.gz"
    )
  end
end
