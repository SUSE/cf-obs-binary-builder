class CfObsBinaryBuilder::Pippop < CfObsBinaryBuilder::BaseDependency

  def initialize(version)
    super(
      "pip-pop",
      version,
      "https://github.com/djoyahoy/pip-pop/archive/v#{version}.tar.gz"
    )
  end

  def prepare_sources
	  super
	  system("wget https://github.com/docopt/docopt/archive/0.6.2.tar.gz -O 0.6.2.tar.gz")
  end
end
