class CfObsBinaryBuilder::Dotnetsdk < CfObsBinaryBuilder::S3Dependency
  def initialize(version)
    super(
      'dotnet-sdk',
      'dotnet',
      version,
      [/^1.*/]
    )

    # Handle the special case when we consume dependencies from upstream.
    # Drop this when the buildpack doesn't release anymore this specific version
    if version == "2.0.3"
      @obs_package = SDKPackage::new()
    end
  end
end

# FIXME:
# We consume dotnet-sdk-2.0.3 and dotnet-runtime-2.0.7 from Pivotal.
# This is a very special case, and we should be able to drop this in the
# future.

# Drop this as well
class SDKPackage
  def exists?
    true
  end

  def available?
    true
  end

  def build_status(stacks)
    return :succeeded
  end

  def artifact(stack, s3_bucket)
    artifacts = {}
    artifacts[:uri] = "https://buildpacks.cloudfoundry.org/dependencies/dotnet/dotnet.2.0.3.linux-amd64-b56d13fc.tar.xz"
    artifacts[:checksum] = "b56d13fc6830da10fdec4b78da4cf6b5af462c9080282d2c1a4e4a98e50d5dea"
    artifacts
  end

end
