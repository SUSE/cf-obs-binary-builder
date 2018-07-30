class CfObsBinaryBuilder::BaseDependency
  attr_reader :version, :dependency, :package_name, :source, :obs_package

  def initialize(dependency, version, source = nil)
    @dependency = dependency
    @version = version
    @source = source
    @package_name = "#{dependency}-#{version}"
    obs_project = ENV["OBS_DEPENDENCY_PROJECT"] || raise("no OBS_DEPENDENCY_PROJECT environment variable set")
    @obs_package = CfObsBinaryBuilder::ObsPackage.new(package_name, obs_project)
  end

  def run(checksum)
    obs_package.create
    obs_package.checkout do
      write_spec_file
      prepare_sources
      validate_checksum(checksum)
      write_sources_yaml
      obs_package.commit
    end
    log 'Done!'
  end

  def write_sources_yaml
    if !@validated_checksum
      raise "Checksum not validated, won't write to yaml"
    end

    File.write("sources.yml", self.to_yaml)
  end

  def write_spec_file
    log 'Render the spec template and put it in the package dir'
    File.write("#{dependency}.spec", render_spec_template)
  end

  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/../templates/#{dependency}.spec.erb"))
    ERB.new(spec_template).result(binding)
  end

  def prepare_sources
    log 'Downloading the sources in the package directory...'
    File.write(File.basename(source), open(source).read)
  end

  def validate_checksum(checksum)
    sha256 = Digest::SHA256.file File.basename(source)
    actual_checksum = sha256.hexdigest

    if actual_checksum != checksum
      raise "Checksum mismatch #{actual_checksum} vs. #{checksum}"
    else
      @validated_checksum = checksum
    end
  end

  def to_yaml
    [
      {
        'url'    => @source,
        'sha256' => @validated_checksum
      }
    ].to_yaml
  end
end
