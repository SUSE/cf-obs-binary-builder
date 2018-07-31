class CfObsBinaryBuilder::BaseBuildpack
  attr_reader :name, :version, :obs_package

  BASE_STACK = "cflinuxfs2"

  def initialize(name, version)
    @name = name
    @version = version

    package_name = "#{name}-buildpack-#{version}"
    obs_project = ENV["OBS_BUILDPACK_PROJECT"] || raise("no OBS_BUILDPACK_PROJECT environment variable set")
    @obs_package = CfObsBinaryBuilder::ObsPackage.new(package_name, obs_project)
  end

  def run
    obs_package.create
    obs_package.checkout do
      prepare_sources
      write_spec_file
      obs_package.commit
    end
    log 'Done!'
  end

  def manifest_dependencies
    parsed_manifest["dependencies"]
      .select { |dep| dep["cf_stacks"].include?(BASE_STACK) }
      .map { |dep| parse_dependency(dep) }
  end

  private

  def write_spec_file
    log 'Render the spec template and put it in the package dir'
    File.write("#{name}-buildpack.spec", render_spec_template)
  end

  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/../templates/#{name}-buildpack.spec.erb"))
    ERB.new(spec_template).result(binding)
  end

  def prepare_sources
    system("wget https://github.com/SUSE/cf-#{name}-buildpack/archive/v#{version}.tar.gz -O v#{version}.tar.gz")
    # Extract manifest.yml from the tarball so that its dependencies can be parsed
    system("tar xfv v#{version}.tar.gz cf-#{name}-buildpack-#{version}/manifest.yml --strip-components=1")
  end

  def parsed_manifest
    YAML.load_file("manifest.yml")
  end

  def parse_dependency(dep)
    if dep["name"].start_with?("openjdk")
      {
        name: "openjdk",
        version: dep["uri"].match(/openjdk-([0-9._]+)-/)[1]
      }
    else
      {
        name: dep["name"],
        version: dep["version"]
      }
    end
  end
end
