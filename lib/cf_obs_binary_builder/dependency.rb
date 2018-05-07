class CfObsBinaryBuilder::Dependency
  def create_obs_package(package_name)
    log 'Creating the package on OBS using "osc"...'

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
    log 'Checking out the package with osc...'
    `osc checkout #{obs_project}/#{package_name}`
  end

  def commit_obs_package(binary, version)
    log 'Commit the changes on OBS'
    log `osc addremove`
    log `osc commit -m "Commiting files"`
  end

  def obs_project
    ENV["OBS_PROJECT"] || raise("no OBS_PROJECT environment variable set")
  end

  def log(*args)
    CfObsBinaryBuilder::log(*args)
  end
end
