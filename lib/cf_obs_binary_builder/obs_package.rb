require "nokogiri"
class CfObsBinaryBuilder::ObsPackage
  attr_reader :name, :obs_project

  ARTIFACT_EXTENSION_REGEXP=".tgz|.tar.gz|.tbz|tar.bz|.zip|.phar"
  STACK_TO_OBS_REPOSITORY = {
    "sle12" => "SLE_12_SP3",
    "cfsle15fs" => "SLE_15",
    "opensuse42" => "openSUSE_Leap_42.3",
  }

  def self.project_package_statuses(obs_project)
    output, status = Open3.capture2e("osc prjresults #{obs_project} --xml")
    raise "Error getting project results: #{output}" unless status.exitstatus == 0

    doc = Nokogiri::XML(output)
    result = {}
    doc.xpath("//result").each do |repository_results|
      repository = repository_results["repository"]
      stack = STACK_TO_OBS_REPOSITORY.invert[repository]
      next unless stack
      result[stack] = {}
      repository_results.xpath("//result[@repository='#{repository}']//status").each do |package_status|
        result[stack][package_status["package"]] = package_status["code"]
      end
    end

    result
  end

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

  def checkout(config = {}, &block)
    log 'Checking out the package with osc...'
    Dir.mktmpdir(CfObsBinaryBuilder::TMP_DIR_SUFFIX) do |tmpdir|
      Dir.chdir(tmpdir) do
        `osc checkout #{obs_project}/#{name} -o #{name}`
        Dir.chdir(name) do
          if config[:reset]
            log 'Resetting package'
            FileUtils.rm Dir.glob("*")
          end
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
    system("osc search --package #{name} | grep '#{obs_project} ' > /dev/null")
  end

  def exists_in_status?(package_statuses)
    package_statuses.values.map(&:keys).flatten.include?("#{name}")
  end

  def build_status_in_package_statuses(stack, package_statuses)
    package_statuses.dig(stack,@name)&.to_sym
  end

  # Checks the build status for the stack we are interested in (and ignores all others).
  def build_status(stack)
    output, status = Open3.capture2e("osc prjresults #{obs_project} --xml")
    raise "Error getting project results: #{output}" unless status.exitstatus == 0

    doc = Nokogiri::XML(output)
    stacks = [stack]
    repositories = stacks.map{|stack| repository_for_stack(stack) }
    xpath = repositories.map do |repository|
      "//result[@repository='#{repository}']/status[@package='#{name}']"
    end.join("|")
    results = doc.xpath(xpath).map{|status| status["code"]}

    return :failed if results.any? { |r| r.strip == "failed" }
    return :succeeded if results.all? { |r| r.strip == "succeeded" }
    # Might include states like "broken", "scheduled" etc. In this case we want
    # to recheck after some time.
    return :in_process
  end

  def artifact(stack, s3_bucket)
    artifacts = {}
    obs_repository = repository_for_stack(stack)
    checksum_file, artifact_file = artifact_filenames(stack)

    subdir = name.sub(/-.*/, "")
    artifacts[:uri] = "https://s3.amazonaws.com/#{s3_bucket}/dependencies/#{subdir}/#{artifact_file}"

    Dir.mktmpdir do |tmpdir|
      output, status = Open3.capture2e("osc getbinaries -d #{tmpdir} #{obs_project} #{name} #{obs_repository} x86_64 #{checksum_file}")
      raise "Could not get checksum file #{checksum_file}:\n#{output}" unless status.exitstatus == 0

      content = File.read(File.join(tmpdir, checksum_file))
      artifacts[:checksum] = content[/(\w{64}) .+/, 1]

      raise "Error extracting checksum. File content:\n#{content}" unless artifacts[:checksum]

      if @name =~ /^php-/
        modules_file = "#{name}-extensions.yaml"
        output, status = Open3.capture2e("osc getbinaries -d #{tmpdir} #{obs_project} #{name} #{obs_repository} x86_64 #{modules_file}")
        raise "Could not get modules file #{modules_file}:\n#{output}" unless status.exitstatus == 0

        artifacts[:modules] = YAML.load_file(File.join(tmpdir, modules_file))
      end
    end

    artifacts
  end

  private

  def repository_for_stack(stack)
    STACK_TO_OBS_REPOSITORY[stack] || raise('unknown stack: #{stack}')
  end

  def artifact_filenames(stack)
    obs_repository = repository_for_stack(stack)
    ls_output, status = Open3.capture2e("osc ls -b #{obs_project} #{name} #{obs_repository} x86_64")
    raise "Error getting checksum filename: #{checksum_file}" unless status.exitstatus == 0
    name_without_version = name.match(/^(.*)-/)[1]
    checksum_file = ls_output[/#{name_without_version}.+\.sha256$/].strip
    artifact_file = ls_output[/#{name_without_version}.+[#{ARTIFACT_EXTENSION_REGEXP}]$/].strip

    [checksum_file, artifact_file]
  end

end
