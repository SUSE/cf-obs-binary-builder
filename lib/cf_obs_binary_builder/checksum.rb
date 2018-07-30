class CfObsBinaryBuilder::Checksum
  SOURCE_TYPES = {
    "dep" => {
      "type" => "github_releases",
      "params" => {
        "repo" => 'golang/dep',
        "fetch_source" => true
      }
    },
    "glide" => {
      "type" => "github_releases",
      "params" => {
        "repo" => 'Masterminds/glide',
        "fetch_source" => true
      }
    },
    "godep" => {
      "type" => "github_releases",
      "params" => {
        "repo" => 'tools/godep',
        "fetch_source" => true
      }
    },
    "bundler" => {
      "type" => "rubygems"
    }
  }

  def self.for(name, manifest_version)
    version = mapped_version(manifest_version)
    # There are special cases where the type does not match the dependency name.
    # See https://github.com/cloudfoundry/buildpacks-ci/blob/0b54199ecfbe98d085f4e34d224877ee415c5405/pipelines/binary-builder-new.yml#L1 for more information
    data = {
      source: {
        name: name,
        type: SOURCE_TYPES.dig(name, "type") || name
      }.merge(SOURCE_TYPES.dig(name, "params") || {} ),
      version: {
        ref: version
      }
    }.to_json
    _, output, _ = Open3.capture3("depwatcher /tmp", :stdin_data => data)
    result = JSON.parse(output.lines.last)

    result["sha256"]
  end

  private

  # depwatcher expects the pure jruby version, not what we have in the manifest.
  # e.g. ruby-2.3.3-jruby-9.1.17.0 should become 9.1.17.0
  def self.mapped_version(version)
    if version.include?("jruby")
      version[/jruby-(.*)/, 1]
    else
      version
    end
  end
end
