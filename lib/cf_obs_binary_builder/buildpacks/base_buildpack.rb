class CfObsBinaryBuilder::BaseBuildpack
  attr_reader :name, :version, :upstream_version, :obs_package, :manifest

  BUILD_STACKS = [ "cflinuxfs2", "sle12", "opensuse42" ]

  def initialize(name, upstream_version, revision = 1)
    @name = name
    @upstream_version = upstream_version
    @version = "#{@upstream_version}.#{revision}"

    package_name = "#{name}-buildpack-#{version}"
    obs_project = ENV["OBS_BUILDPACK_PROJECT"] || raise("no OBS_BUILDPACK_PROJECT environment variable set")
    @obs_package = CfObsBinaryBuilder::ObsPackage.new(package_name, obs_project)
  end

  def run
    obs_package.create
    obs_package.checkout do
      @manifest = prepare_sources
      populate_result = @manifest.populate!
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
      File.expand_path(File.dirname(__FILE__) + "/../templates/buildpack.spec.erb"))
    ERB.new(spec_template).result(binding)
  end

  def prepare_sources
    system("wget https://github.com/cloudfoundry/#{name}-buildpack/archive/v#{upstream_version}.tar.gz -O v#{upstream_version}.tar.gz")
    Dir.mktmpdir do |tmpdir|
      # Extract manifest.yml from the tarball so that its dependencies can be parsed
      system("tar xfv v#{upstream_version}.tar.gz -C #{tmpdir} #{name}-buildpack-#{upstream_version}/manifest.yml --strip-components=1")

      CfObsBinaryBuilder::Manifest.new(File.join(tmpdir, "manifest.yml"))
    end
  end
end
