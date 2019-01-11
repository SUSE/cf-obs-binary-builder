# s3 dependencies are simple dependencies where the source artifact is
# simply copied from an s3 bucked without transformation steps.

class CfObsBinaryBuilder::S3Dependency
  attr_reader :version, :subdir, :dependency, :package_name, :source, :url,
              :license, :obs_package, :generate_checksum, :s3_bucket,
              :ignore_missing

  def initialize(dependency, subdir, version, regex_filter)
    @ignore_missing = true
    @s3_bucket = ENV['STAGING_BUILDPACKS_BUCKET'] ||
                 raise('no STAGING_BUILDPACKS_BUCKET environment variable set')
    @license = license
    @url = url
    @subdir = subdir
    @dependency = dependency
    @version = version
    @source = "#{dependency}.#{version}"
    @generate_checksum = true
    @package_name = @source
    @regex_filter = regex_filter
    @obs_package = FakeObsPackage.new(version,
                                      @source,
                                      subdir)
  end

  def needs_to_be_filtered(hash)
    @regex_filter.to_a.each do |regexp|
      hash['dependencies'].each do |dependency|
        if dependency['version'].match(regexp) &&
           dependency['name'] == @dependency &&
           dependency['version'] == @version
          return true
        end
      end
    end
    false
  end
end
