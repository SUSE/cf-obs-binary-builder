class CfObsBinaryBuilder::Pipenv < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "pipenv",
      version,
      "https://files.pythonhosted.org/packages/source/p/pipenv/pipenv-#{version}.tar.gz"
    )
  end

  def prepare_sources
    `which pip`
    unless $?.success?
      raise("The executable `pip` is required to download these sources...")
    end
    log "Downloading the sources via pip in the package directory...)"
    system("pip download --no-binary :all: pipenv==#{@version}")
    system("pip download --no-binary :all: pytestrunner")
    system("pip download --no-binary :all: setuptools_scm")
  end
end
