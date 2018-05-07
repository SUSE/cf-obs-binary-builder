class CfObsBinaryBuilder::Yarn < CfObsBinaryBuilder::Dependency
  def initialize(version, checksum)
    @dependency = "yarn"
    super(version, checksum)
  end

  def prepare_files
    write_service_file
    File.write("#{dependency}.spec", render_spec_template)
  end

  private

  def write_service_file
    File.write("_service", <<EOF
<services>
  <service name="tar_scm" mode="disabled">
    <param name="scm">git</param>
    <param name="url">https://github.com/yarnpkg/yarn</param>
    <param name="exclude">.git</param>
    <param name="filename">yarn</param>
    <param name="versionformat">1.3.2</param>
    <param name="revision">v1.3.2</param>
    <param name="changesgenerate">enable</param>
  </service>
  <service name="recompress" mode="disabled">
    <param name="file">*.tar</param>
    <param name="compression">xz</param>
  </service>
  <service mode="disabled" name="set_version"/>
</services>
EOF
    )
  end
end
