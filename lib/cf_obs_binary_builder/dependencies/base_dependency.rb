class CfObsBinaryBuilder::BaseDependency
  include RpmSpecHelpers

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

  def regenerate_spec
    obs_package.checkout do
      write_spec_file
      obs_package.commit
    end
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
    download_source(source)
  end

  def validate_checksum(checksum)
    @validated_checksum = verify_checksum(source, checksum)
  end

  def to_yaml
    dependency_hash = { 'url' => @source }
    case @validated_checksum.length
    when 32
      dependency_hash['md5'] = @validated_checksum
    when 40
      dependency_hash['sha1'] = @validated_checksum
    when 64
      dependency_hash['sha256'] = @validated_checksum
    when 128
      dependency_hash['sha512'] = @validated_checksum
    end

    [dependency_hash].to_yaml
  end

  def download_source(source)
    log "Downloading the sources in the package directory... (#{source})"
    File.write(File.basename(source), open(source).read)
  end

  def verify_checksum(source, checksum)
    actual_checksum = case checksum.length
    when 32
      md5 = Digest::MD5.file File.basename(source)
      md5.hexdigest
    when 40
      sha1 = Digest::SHA1.file File.basename(source)
      sha1.hexdigest
    when 64
      sha256 = Digest::SHA256.file File.basename(source)
      sha256.hexdigest
    when 128
      sha512 = Digest::SHA512.file File.basename(source)
      sha512.hexdigest
    end

    if actual_checksum != checksum
      raise "Checksum mismatch #{actual_checksum} vs. #{checksum}"
    end

    checksum
  end
end
