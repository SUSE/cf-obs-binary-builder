class CfObsBinaryBuilder::Dotnetaspnetcore < CfObsBinaryBuilder::BinaryDotnetDependency
  def initialize(version, checksum)
    super(
      'dotnet-aspnetcore',
      version,
      "https://buildpacks.cloudfoundry.org/dependencies/dotnet-aspnetcore/dotnet-aspnetcore_#{version}_linux_x64_any-stack_#{checksum[0..7]}.tar.xz",
      "MIT",
      "https://dotnet.microsoft.com/"
    )
  end
end