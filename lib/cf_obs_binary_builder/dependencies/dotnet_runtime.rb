class CfObsBinaryBuilder::Dotnetruntime < CfObsBinaryBuilder::BinaryDotnetDependency
  def initialize(version, checksum)
    super(
      'dotnet-runtime',
      version,
      "https://buildpacks.cloudfoundry.org/dependencies/dotnet-runtime/dotnet-runtime_#{version}_linux_x64_any-stack_#{checksum[0..7]}.tar.xz",
      "MIT",
      "https://dotnet.microsoft.com/"
    )
  end
end