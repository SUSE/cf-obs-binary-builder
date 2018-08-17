class CfObsBinaryBuilder::Pippop < CfObsBinaryBuilder::PypiDependency
  def initialize(version)
    super(
      "pip-pop",
      version,
      "MIT",
      "https://github.com/heroku-python/pip-pop"
    )
  end
end
