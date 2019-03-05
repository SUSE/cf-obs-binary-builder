class CfObsBinaryBuilder::Composer < CfObsBinaryBuilder::NonBuildDependency
  def initialize(version)
    super(
      "composer",
      version,
      "https://github.com/composer/composer/releases/download/#{version}/composer.phar",
      "MIT",
      "https://getcomposer.org"
    )
  end
end
