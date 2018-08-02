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
    "yarn" => {
      "type" => "github_releases",
      "params" => {
        "repo" => 'yarnpkg/yarn',
        "extension" => ".tar.gz"
      }
    },
    "bundler" => {
      "type" => "rubygems"
    }
  }

  def self.for(name, version)
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
    begin
      result = JSON.parse(output.lines.last)
    rescue Exception
      puts "Could not parse json. Tried the last line of this output:\n#{output}"
      raise
    end

    result["sha256"]
  end
end
