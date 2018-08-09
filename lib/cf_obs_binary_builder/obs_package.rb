class CfObsBinaryBuilder::ObsPackage
  attr_reader :name, :obs_project

  ARTIFACT_EXTENSION_REGEXP=".tgz|.tar.gz|.tbz|tar.bz|.zip"

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
      Dir.chdir(tmpdir) do
        `osc checkout #{obs_project}/#{name} -o #{name}`
        Dir.chdir(name) do
          block.call
        end
      end
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

  def build_status
    output, status = Open3.capture2e("osc prjresults #{obs_project} -c | grep #{name}\\;")
    raise "Error getting project results: #{output}" unless status.exitstatus == 0
    results = output.split(";")[1..-1]

    return :failed if results.any? { |r| r.strip == "failed" }
    return :succeeded if results.all? { |r| r.strip == "succeeded" }
    # Might include states like "broken", "scheduled" etc. In this case we want
    # to recheck after some time.
    return :in_process
  end

  def artifact(stack)
    obs_repository = repository_for_stack(stack)
    checksum_file, artifact_file = artifact_filenames(stack)

    artifact_uri = "https://download.opensuse.org/repositories/#{obs_project.gsub(":", ":/")}/#{obs_repository}/#{artifact_file}"

    checksum = nil
    Dir.mktmpdir do |tmpdir|
      output, status = Open3.capture2e("osc getbinaries -d #{tmpdir} #{obs_project} #{name} #{obs_repository} x86_64 #{checksum_file}")
      raise "Could not get checksum file #{checksum_file}:\n#{output}" unless status.exitstatus == 0

      content = File.read(File.join(tmpdir, checksum_file))
      checksum = content[/(\w{64}) .+/, 1]
      raise "Error extracting checksum. File content:\n#{content}" unless checksum
    end

    {
      checksum: checksum,
      uri: artifact_uri
    }
  end

  private

  def repository_for_stack(stack)
    obs_repository = case stack
    when "sle12"
      "SLE_12_SP3"
    when "opensuse42"
      "openSUSE_Leap_42.3"
    else
      raise "unknown stack: #{stack}"
    end
  end

  def artifact_filenames(stack)
    obs_repository = repository_for_stack(stack)
    ls_output, status = Open3.capture2e("osc ls -b #{obs_project} #{name} #{obs_repository} x86_64")
    raise "Error getting checksum filename: #{checksum_file}" unless status.exitstatus == 0
    checksum_file = ls_output[/#{name}.+\.sha256$/].strip
    artifact_file = ls_output[/#{name}.+[#{ARTIFACT_EXTENSION_REGEXP}]$/].strip

    [checksum_file, artifact_file]
  end

end
