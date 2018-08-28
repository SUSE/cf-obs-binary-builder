class CfObsBinaryBuilder::Pippop < CfObsBinaryBuilder::PypiDependency
  attr_reader :source1

  def initialize(version)
    super(
      "pip-pop",
      version,
      "MIT",
      "https://github.com/heroku-python/pip-pop"
    )
  end

  private

  def pypi_source
    @source1 = parse_pypi_url("docopt", "0.6.2")
    super
  end

  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/../templates/pip-pop.spec.erb"))
    ERB.new(spec_template).result(binding)
  end

  def prepare_sources
    download_source(source1)
    super
  end
end
