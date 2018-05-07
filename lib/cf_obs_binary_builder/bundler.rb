require 'tempfile'
require 'erb'

class CfObsBinaryBuilder::Bundler
  attr_reader :version, :checksum, :binary

  def initialize(version, checksum)
    @binary = "bundler"
    @version = version
    @checksum = checksum
  end

  def run
    spec_file_contents = render_spec_template(binary, version)

    Dir.mktmpdir("cf_binary_build") do |tmpdir|
      Dir.chdir tmpdir

      puts 'Create the package on OBS using "osc"'
      create_obs_package("#{binary}-#{version}")

      puts 'Checkout the package with osc'
      checkout_obs_package("#{binary}-#{version}")

      puts 'Change working directory'
      Dir.chdir("#{obs_project}/#{binary}-#{version}")

      puts 'Download the source and put them in the package dir'
      fetch_sources(binary, version)

      puts 'Render the spec template and put it in the package dir'
      File.write("#{binary}.spec", spec_file_contents)

      puts 'Commit the changes on OBS'
      commit_obs_package(binary, version)

      puts 'Done!'
    end
  end

  def fetch_sources(binary, version)
    `curl http://rubygems.org/gems/#{binary}-#{version}.gem -o #{binary}-#{version}.gem`
  end

  def create_obs_package(package_name)
    package_meta_template = <<EOF
<package project="#{obs_project}" name="#{package_name}">
  <title>#{package_name}</title>
  <description>
    Automatic build of #{package_name} binary for the use in buildpacks in SCF.
  </description>
</package>
EOF

    Tempfile.open("package_meta_template") do |file|
      file.write(package_meta_template)
      file.close

      `osc meta pkg #{obs_project} #{package_name} -F #{file.path}`
    end
  end

  def checkout_obs_package(package_name)
    `osc checkout #{obs_project}/#{package_name}`
  end

  def render_spec_template(binary, version)
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/templates/#{binary}.spec.erb"))
    ERB.new(spec_template).result(binding)
  end

  def commit_obs_package(binary, version)
    puts `osc addremove`
    puts `osc commit -m "Commiting files"`
  end

  def obs_project
    ENV["OBS_PROJECT"] || raise("no OBS_PROJECT environment variable set")
  end
end
