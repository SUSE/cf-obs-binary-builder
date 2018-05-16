require 'tempfile'
require 'erb'

class CfObsBinaryBuilder::Bundler < CfObsBinaryBuilder::Dependency
  def initialize(version, checksum)
    super("bundler", version, checksum)
  end

  def prepare_files
    log 'Render the spec template and put it in the package dir'
    File.write("#{dependency}.spec", render_spec_template)
    fetch_sources
  end

  def fetch_sources
    log 'Downloading the sources in the package directory...'
    `curl http://rubygems.org/gems/#{dependency}-#{version}.gem -o #{dependency}-#{version}.gem`
  end
end
