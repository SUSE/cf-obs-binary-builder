# Dotnetruntime is a specific S3Dependency for Dotnet buildpack.
class CfObsBinaryBuilder::Dotnetruntime < CfObsBinaryBuilder::S3Dependency
  def initialize(version)
    super(
      'dotnet-runtime',
      'dotnet',
      version,
      [/^1.*/]
    )

    # Handle the special case when we consume dependencies from upstream.
    # Drop this when the buildpack doesn't release anymore this specific version
    if version == "2.0.7"
      @obs_package = RuntimePackage::new()
    end
  end
end

# FIXME:
# We consume dotnet-sdk-2.0.3 and dotnet-runtime-2.0.7 from Pivotal.
# This is a very special case, and we should be able to drop this in the
# future.

# Drop this as well
class RuntimePackage
  def exists?
    true
  end

  def available?
    true
  end

  def build_status
    return :succeeded
  end

  def artifact(stack, s3_bucket)
    artifacts = {}
    artifacts[:uri] = "https://buildpacks.cloudfoundry.org/dependencies/dotnet-framework/dotnet-framework.2.0.7.linux-amd64-7635e82a.tar.xz"
    artifacts[:checksum] = "7635e82aea1145158a49c84d759507a480fe8b666d99ff6678a82740f51eff9a"
    artifacts
  end

end