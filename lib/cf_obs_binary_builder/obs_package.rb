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
    Dir.mktmpdir(CfObsBinaryBuilder::TMP_DIR_SUFFIX) do |tmpdir|
      Dir.chdir(tmpdir)
      `osc checkout #{obs_project}/#{name} -o #{name}`
      Dir.chdir(name)
      block.call
    end
  end

  def commit
    log 'Commiting the changes on OBS..'
    log `osc addremove`
    log `osc commit -m "Commiting files"`
  end

  # Checks if this package already exists on OBS under @obs_project
  def exists?
    system("osc search --package #{name} | grep #{obs_project} > /dev/null")
  end

  def build_succeeded?
    output, status = Open3.capture2e("osc prjresults #{obs_project} -c | grep #{name}")
    raise "Error getting project results: #{output}" unless status.exitstatus == 0
    results = output.split(";")[1..-1]
    results.all? { |r| r.strip == "succeeded" }
  end

  def artifact_checksum(stack)
    obs_repository = case stack
    when "sle12"
      "SLE_12_SP3"
    when "opensuse42"
      "openSUSE_Leap_42.3"
    else
      raise "unknown stack: #{stack}"
    end

    checksum_file, status = Open3.capture2e("osc ls -b #{obs_project} #{name} #{obs_repository} x86_64 | grep sha256")
    raise "Error getting checksum filename: #{checksum_file}" unless status.exitstatus == 0

    checksum_file.strip!
    checksum = nil
    Dir.mktmpdir do |tmpdir|
      output, status = Open3.capture2e("osc getbinaries -d #{tmpdir} #{obs_project} #{name} #{obs_repository} x86_64 #{checksum_file}")
      raise "Could not get checksum file #{checksum_file}" unless status.exitstatus == 0

      content = File.read(File.join(tmpdir, checksum_file))
      checksum = content[/(\w{64}) .+/, 1]
      raise "Error extracting checksum. File content:\n#{content}" unless checksum
    end

    checksum
  end
end
