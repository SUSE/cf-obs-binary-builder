class CfObsBinaryBuilder::ObsPackage
  attr_reader :name, :obs_project

  def initialize(name, obs_project)
    @name = name
    @obs_project = obs_project
  end

  def create
    log 'Creating the package on OBS using "osc"...'

    package_meta_template = <<EOF
<package project="#{obs_project}" name="#{name}">
  <title>#{name}</title>
  <description>
    Automatic build of #{name} for the use in buildpacks in SCF.
  </description>
</package>
EOF

    Tempfile.open("package_meta_template") do |file|
      file.write(package_meta_template)
      file.close

      `osc meta pkg #{obs_project} #{name} -F #{file.path}`
    end
  end

  def checkout(&block)
    log 'Checking out the package with osc...'
    `osc checkout #{obs_project}/#{name} -o #{name}`
    Dir.chdir(name)
    block.call
  end

  def commit
    log 'Commiting the changes on OBS..'
    log `osc addremove`
    log `osc commit -m "Commiting files"`
  end
end
