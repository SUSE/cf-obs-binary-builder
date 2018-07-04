class CfObsBinaryBuilder::Buildpack
  attr_reader :path, :obs_package

  def initialize(name, version, path)
    @name = name
    @path = path

    package_name = "#{name}-#{version}"
    @obs_package = CfObsBinaryBuilder::ObsPackage.new(package_name)
  end

  def run
  end

  def manifest_dependencies
    parsed_manifest["dependencies"]
      .select { |dep| dep["cf_stacks"].include?("cflinuxfs2") }
      .map { |dep| dep["name"] + "-" + dep["version"] }
  end

  private

  def parsed_manifest
    YAML.load_file(File.join(@path, "manifest.yml"))
  end
end
