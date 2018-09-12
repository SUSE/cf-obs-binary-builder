class CfObsBinaryBuilder::Composer < CfObsBinaryBuilder::NonBuildDependency
  def initialize(version)
    super(
      "composer",
      version,
      "https://getcomposer.org/download/1.7.2/composer.phar",
      "MIT",
      "https://getcomposer.org"
    )
  end
end
