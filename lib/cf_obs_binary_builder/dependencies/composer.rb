class CfObsBinaryBuilder::Composer < CfObsBinaryBuilder::NonBuildDependency
  def initialize(version)
    super(
      "composer",
      version,
      "https://getcomposer.org/download/#{version}/composer.phar",
      "MIT",
      "https://getcomposer.org"
    )
  end
end
