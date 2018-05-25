class CfObsBinaryBuilder::ObsPackage
  attr_reader :name

  def initialize(name)
    @name = name
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

  def obs_project
    ENV["OBS_PROJECT"] || raise("no OBS_PROJECT environment variable set")
  end
end
