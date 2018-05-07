require 'tempfile'
require 'erb'

class CfObsBinaryBuilder::Bundler < CfObsBinaryBuilder::Dependency
  attr_reader :version, :checksum, :binary

  def initialize(version, checksum)
    @binary = "bundler"
    @version = version
    @checksum = checksum
  end

  def run
    spec_file_contents = render_spec_template(binary, version)

    create_obs_package("#{binary}-#{version}")
    checkout_obs_package("#{binary}-#{version}")
    Dir.chdir("#{obs_project}/#{binary}-#{version}")
    fetch_sources(binary, version)

    log 'Render the spec template and put it in the package dir'
    File.write("#{binary}.spec", spec_file_contents)
    commit_obs_package(binary, version)
    log 'Done!'
  end

  def fetch_sources(binary, version)
    log 'Downloading the sources in the package directory...'
    `curl http://rubygems.org/gems/#{binary}-#{version}.gem -o #{binary}-#{version}.gem`
  end

  def render_spec_template(binary, version)
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/templates/#{binary}.spec.erb"))
    ERB.new(spec_template).result(binding)
  end
end
