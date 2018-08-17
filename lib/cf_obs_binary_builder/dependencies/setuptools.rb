class CfObsBinaryBuilder::Setuptools < CfObsBinaryBuilder::PypiDependency
  def initialize(version)
    super(
      "setuptools",
      version,
      "MIT",
      "https://github.com/pypa/setuptools"
    )
  end
end
