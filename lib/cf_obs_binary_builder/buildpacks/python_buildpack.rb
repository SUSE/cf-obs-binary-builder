class CfObsBinaryBuilder::PythonBuildpack < CfObsBinaryBuilder::BaseBuildpack
  def initialize(upstream_version, revision)
    super("python", upstream_version, revision)
  end
end
