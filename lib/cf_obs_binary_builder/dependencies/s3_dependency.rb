# s3 dependencies are simple dependencies where the source artifact is
# simply copied from an s3 bucked without transformation steps.
class CfObsBinaryBuilder::S3Dependency
  attr_reader :version, :subdir, :dependency, :package_name, :source, :url, :license, :obs_package, :generate_checksum, :s3_bucket, :ignore_missing
  attr_reader :regex_filter
  # FIXME: ignore_missing should be a list of versions that we skip, or either
  # have another attr for versions that we need to delete from the manifest ( e.g. dotnet-sdk-1.x )
  def regenerate
  end

  def initialize(dependency, subdir, version, source, license, url, regex_filter)
    @ignore_missing = true
    @s3_bucket = ENV["STAGING_BUILDPACKS_BUCKET"] || raise("no STAGING_BUILDPACKS_BUCKET environment variable set")
    @license = license
    @url = url
    @subdir = subdir
    @obs_package = CfObsBinaryBuilder::FakeObsPackage.new( version, dependency, source, subdir)
    @dependency = dependency
    @version = version
    @source = source
    @generate_checksum = true
    @package_name = "#{dependency}-#{version}"
    @regex_filter = regex_filter
  end

  # WONTFIX: change the name of this method
  def needs_to_be_filtered(hash)
    regex_filter.to_a.each do |regexp|
      # hash -> 'dependencies' -> [  {} ,  {}  ]
      hash['dependencies'].each do |dependency|
        return true if dependency['version'].match(regexp) && dependency['name'] == @dependency && dependency['version'] == @version
      end
    end
    return false
    # if regexp match, remove from hash
  end

end

class CfObsBinaryBuilder::FakeObsPackage
	attr_reader :version, :dependency, :source, :subdir, :depdir

	def initialize(version, dependency, source, subdir)
    # FIXME: Rename this to something more meaningful maybe?
    @depdir = ENV["DEPDIR"] || raise("no DEPDIR environment variable set")

		@version = version
		@dependency = dependency
    @subdir = subdir


    # TODO: Generate source, comprensive of sha in the name
    # Pipelines later will just copy it, so sha must be included (or rename the file)
		@source = source
	end

	def exists?
		return is_available
	end

	def build_status
		if is_available
			return :succeeded
		end

		return :failed
	end

  def resolve_dep(stack)
    return File.basename(Dir[File.join(@depdir, "#{@source}*")].grep(/#{stack}/).uniq.sort.last.to_s)
  end

	def is_available
    return !File.basename(Dir[File.join(@depdir, "#{@source}*")].uniq.sort.last.to_s).empty?
	end

  def satifies_stack(stack)
    # Stack is satisfied if we resolved a dep for the stack (thus not empty)
    return true if !resolve_dep(stack).empty?
  end

	def artifact(stack, s3_bucket)
    buildpack = resolve_dep(stack)
    artifacts = {}
    artifacts[:uri] = "https://s3.amazonaws.com/#{s3_bucket}/dependencies/#{@subdir}/#{buildpack}"
    sha      = Digest::SHA256.hexdigest(open("#{depdir}/#{buildpack}").read)
    artifacts[:checksum] = sha
    return artifacts
	end
end
