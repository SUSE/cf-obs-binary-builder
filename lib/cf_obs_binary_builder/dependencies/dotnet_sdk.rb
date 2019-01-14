class CfObsBinaryBuilder::Dotnetsdk < CfObsBinaryBuilder::S3Dependency
  def initialize(version)
    super(
      'dotnet-sdk',
      'dotnet',
      version,
      [/^1.*/]
    )
  end
end
