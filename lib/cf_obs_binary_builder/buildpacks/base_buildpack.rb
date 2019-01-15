require 'fileutils'

class CfObsBinaryBuilder::BaseBuildpack
  include RpmSpecHelpers

  attr_reader :name, :version, :upstream_version, :obs_package, :manifest, :s3_bucket

  BUILD_STACKS = ENV["BUILD_STACKS"].to_s.split(',').sort
  SOURCES_CACHE_DIR = File.expand_path("~/.cf-obs-binary-builder")

  def initialize(name, upstream_version, revision = 1)
    if BUILD_STACKS.empty?
      raise "no BUILD_STACKS environment variable set"
    end

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

      update_source_tarball
      write_spec_file
      obs_package.commit
    end
    log 'Done!'

    :succeeded
  end

  private

  def update_source_tarball
    tarball_dir = "cf-#{name}-buildpack-#{upstream_version}"

    system("tar -xf v#{version}.tar.gz")

    if File.file?(File.join(tarball_dir,'go.mod'))

      # Check if we have go >= 1.11, raise error otherwise
      go_version = `go version`
      go_ok=$?.success?

      if !go_ok
        raise "Can't detect go version"
      end

      installed_version = go_version.match /go(\d)\.(\d{1,2})\.(\d)/

      if !installed_version || installed_version[1].to_i < 1 || installed_version[2].to_i < 11
        raise "Found go "+installed_version[1]+"."+installed_version[2]+" . go >=1.11 is required"
      end

      puts "Buildpack contains go.mod, bundling buildpack-packager"

      if !system("cd #{tarball_dir} && wget https://raw.githubusercontent.com/cloudfoundry/libbuildpack/master/packager/buildpack-packager/main.go -O buildpack-packager.go")
        raise "Could not download buildpack-packager"
      end

      Dir.mktmpdir() do |tmpdir|
        ENV['GOPATH'] = tmpdir
        if !system("go get github.com/google/subcommands")
          raise "Could not get github.com/google/subcommands"
        end
        if !system("go get github.com/cloudfoundry/libbuildpack")
          raise "Could not download buildpack-packager"
        end
        if !system("pushd #{tmpdir}/src/github.com/cloudfoundry/libbuildpack/packager/buildpack-packager && go build && chmod +x buildpack-packager && popd && mv #{tmpdir}/src/github.com/cloudfoundry/libbuildpack/packager/buildpack-packager/buildpack-packager #{tarball_dir}/buildpack-packager")
          raise "Could not build buildpack-packager"
        end
      end

      if !File.directory?(File.join(tarball_dir,'vendor'))
        puts "vendor/ folder absent, generating it"
        if !system("cd #{tarball_dir} && go mod vendor")
          raise "Failed while running go mod vendor"
        end
      end

    end

    File.write(File.join(tarball_dir, 'VERSION'), @version)
    FileUtils.mv("manifest.yml", tarball_dir)

    system("tar czf v#{version}.tar.gz #{tarball_dir}")

    FileUtils.rm_r(tarball_dir)
  end

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
    filename = "v#{version}.tar.gz"
    cached_sources = File.join(SOURCES_CACHE_DIR, filename)

    if CfObsBinaryBuilder::CACHE_SOURCES
      FileUtils.mkdir_p(SOURCES_CACHE_DIR)
      if !File.exist?(cached_sources)
        system("wget #{url} -O #{cached_sources}")
      end
      FileUtils.copy(cached_sources, filename)
    else
      system("wget #{url} -O #{filename}")
    end
  end

  def prepare_sources
    # Fetch the latest commit of our branch as a tarball
    download_sources("https://github.com/SUSE/cf-#{name}-buildpack/archive/#{upstream_version}.tar.gz")
    Dir.mktmpdir do |tmpdir|
      # Fetch the upstream manifest.yml so that its dependencies can be parsed.
      # No matter which revision we are building, the upstream manifest file
      # is the one that lists all the dependencies we need and no more.
      File.write(
        File.join(tmpdir, "manifest.yml"),
        open("https://raw.githubusercontent.com/SUSE/cf-#{name}-buildpack/v#{upstream_version}/manifest.yml").read)

      CfObsBinaryBuilder::Manifest.new(File.join(tmpdir, "manifest.yml"))
    end
  end
end
