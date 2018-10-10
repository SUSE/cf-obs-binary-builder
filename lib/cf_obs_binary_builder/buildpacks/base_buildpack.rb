require 'fileutils'

class CfObsBinaryBuilder::BaseBuildpack
  include RpmSpecHelpers

  attr_reader :name, :version, :upstream_version, :obs_package, :manifest, :s3_bucket

  BUILD_STACKS = [ "cflinuxfs2", "sle12", "opensuse42" ]
  SOURCES_CACHE_DIR = File.expand_path("~/.cf-obs-binary-builder")

  def initialize(name, upstream_version, revision = 1)
    @name = name
    @upstream_version = upstream_version
    @version = "#{@upstream_version}.#{revision}"

    package_name = "#{name}-buildpack-#{version}"
    obs_project = ENV["OBS_BUILDPACK_PROJECT"] || raise("no OBS_BUILDPACK_PROJECT environment variable set")
    @s3_bucket = ENV["STAGING_BUILDPACKS_BUCKET"] || raise("no STAGING_BUILDPACKS_BUCKET environment variable set")
    @obs_package = CfObsBinaryBuilder::ObsPackage.new(package_name, obs_project)
  end

  def run
    obs_package.create
    obs_package.checkout do
      @manifest = prepare_sources
      populate_result = @manifest.populate!(s3_bucket)
      return populate_result unless populate_result == :succeeded

      @manifest.write("manifest.yml")

      write_spec_file
      obs_package.commit
    end
    log 'Done!'

    :succeeded
  end

  private

  def write_spec_file
    log 'Render the spec template and put it in the package dir'
    File.write("#{name}-buildpack.spec", render_spec_template)
  end

  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/../templates/buildpack-go-based.spec.erb"))
    ERB.new(spec_template).result(binding)
  end

  # If CACHE_SOURCES is true it will check if the source tarball is already
  # downloaded and copy from there to the current directory.
  # If CACHE_SOURCE is false, always download the source to the current directory.
  def download_sources(url)
    filename = File.basename(url)
    cached_sources = File.join(SOURCES_CACHE_DIR, filename)

    if CfObsBinaryBuilder::CACHE_SOURCES
      FileUtils.mkdir_p(SOURCES_CACHE_DIR)
      if !File.exist?(cached_sources)
        system("wget https://github.com/cloudfoundry/#{name}-buildpack/archive/#{filename} -O #{cached_sources}")
      end
      FileUtils.copy(cached_sources, filename)
    else
      system("wget https://github.com/cloudfoundry/#{name}-buildpack/archive/#{filename} -O #{filename}")
    end
  end

  def prepare_sources
    download_sources("https://github.com/cloudfoundry/#{name}-buildpack/archive/v#{upstream_version}.tar.gz")
    Dir.mktmpdir do |tmpdir|
      # Extract manifest.yml from the tarball so that its dependencies can be parsed
      system("tar xfv v#{upstream_version}.tar.gz -C #{tmpdir} #{name}-buildpack-#{upstream_version}/manifest.yml --strip-components=1")

      CfObsBinaryBuilder::Manifest.new(File.join(tmpdir, "manifest.yml"))
    end
  end
end
