class CfObsBinaryBuilder::Bower < CfObsBinaryBuilder::NpmDependency
  def initialize(version)
    super(
      "bower",
      version,
      "MIT",
      "https://bower.io/"
    )
  end
end
