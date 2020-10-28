class CfObsBinaryBuilder::Dotnetsdk < CfObsBinaryBuilder::BinaryDotnetDependency
  def initialize(version, checksum)
    super(
      'dotnet-sdk',
      version,
      "https://buildpacks.cloudfoundry.org/dependencies/dotnet-sdk/dotnet-sdk_#{version}_linux_x64_any-stack_#{checksum[0..7]}.tar.xz",
      "MIT",
      "https://dotnet.microsoft.com/"
    )
  end
end