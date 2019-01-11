# Dotnetruntime is a specific S3Dependency for Dotnet buildpack.
class CfObsBinaryBuilder::Dotnetruntime < CfObsBinaryBuilder::S3Dependency
  def initialize(version)
    super(
      'dotnet-runtime',
      'dotnet',
      version,
      [/^1.*/]
    )
  end
end
