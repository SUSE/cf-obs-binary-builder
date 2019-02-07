class CfObsBinaryBuilder::Pippop < CfObsBinaryBuilder::BaseDependency

  def initialize(version)
    super(
      "pip-pop",
      version,
      "https://github.com/djoyahoy/pip-pop/archive/v#{version}.tar.gz"
    )
  end
end
