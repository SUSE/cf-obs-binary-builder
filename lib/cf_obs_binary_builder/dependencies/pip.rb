class CfObsBinaryBuilder::Pip < CfObsBinaryBuilder::PypiDependency
  def initialize(version)
    super(
      "pip",
      version,
      "MIT",
      "https://pip.pypa.io/en/stable/"
    )
  end
end
