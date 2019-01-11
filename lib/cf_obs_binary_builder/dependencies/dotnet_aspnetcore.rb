class CfObsBinaryBuilder::Dotnetaspnetcore < CfObsBinaryBuilder::S3Dependency
  def initialize(version)
    super(
      'dotnet-aspnetcore',
      'dotnet',
      version,
      [/^1.*/]
    )
  end
end
