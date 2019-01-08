class CfObsBinaryBuilder::Dotnetruntime < CfObsBinaryBuilder::S3Dependency
  # regexp : 1.x, 1.0.x
   def initialize(version)
	# We would have also the hash in the URL
    super(
      "dotnet-runtime",
      "dotnet",
      version,
      "dotnet-runtime.#{version}",
      "",
      "",
      [ /^1.*/ ]
    )
  end
end
