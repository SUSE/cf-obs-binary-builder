#!/usr/bin/env ruby

require 'tempfile'
require 'erb'

class CfObsBinaryBuilder

  def self.build(binary, version, checksum)
    puts 'Create the package on OBS using "osc"'
    create_obs_package("#{binary}-#{version}")

    puts 'Checkout the package with osc'
    checkout_obs_package("#{binary}-#{version}")

    puts 'Change working directory'
    Dir.chdir("#{obs_project}/#{binary}-#{version}")

    puts 'Download the source and put them in the package dir'
    fetch_sources(binary, version)

    puts 'Render the spec template and put it in the package dir'
    render_spec_template(binary, version)

    puts 'Commit the changes on OBS'
    commit_obs_package(binary, version)

    puts 'Done!'
  end

  def self.fetch_sources(binary, version)
    `curl http://rubygems.org/gems/#{binary}-#{version}.gem -o #{binary}-#{version}.gem`
  end

  def self.create_obs_package(package_name)
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

  def self.checkout_obs_package(package_name)
    `osc checkout #{obs_project}/#{package_name}`
  end

  def self.render_spec_template(binary, version)
    spec_template = File.read("../../templates/#{binary}.spec.erb")
    result = ERB.new(spec_template).result(binding)
    File.write("#{binary}.spec", result)
  end

  def self.commit_obs_package(binary, version)
    `osc addremove`
    `osc commit -m "Commiting files"`
  end

  def self.obs_project
    ENV["OBS_PROJECT"] || raise("no OBS_PROJECT environment variable set")
  end
end

CfObsBinaryBuilder.build("bundler", "1.15.1", nil)
