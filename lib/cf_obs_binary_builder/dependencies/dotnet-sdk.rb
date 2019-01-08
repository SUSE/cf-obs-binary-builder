class CfObsBinaryBuilder::Dotnetsdk < CfObsBinaryBuilder::S3Dependency
  def initialize(version)
	# We would have also the hash in the URL
    super(
      "dotnet-sdk",
      "dotnet",
      version,
      "dotnet-sdk.#{version}",
      "",
      "",
      [ /^1.*/ ]
    )
  end
end
