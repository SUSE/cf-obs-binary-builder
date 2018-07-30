class CfObsBinaryBuilder::Dep < CfObsBinaryBuilder::GoDependency
  def initialize(version)
    super(
      "dep",
      version,
      "https://github.com/golang/dep/archive/v#{version}.tar.gz"
    )
  end
end
