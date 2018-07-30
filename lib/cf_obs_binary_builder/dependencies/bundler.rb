class CfObsBinaryBuilder::Bundler < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "bundler",
      version,
      "http://rubygems.org/gems/bundler-#{version}.gem"
    )
  end
end
