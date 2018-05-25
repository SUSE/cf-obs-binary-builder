class CfObsBinaryBuilder::SCMDependency < CfObsBinaryBuilder::Dependency
  attr_reader :scm_options

  def initialize(dependency, version, scm_options)
    @scm_options = scm_options
    super(dependency, version)
  end

  def fetch_sources
    # noop - the sources are fetched from the hg repository
  end

  def write_sources_yaml
    # noop - the sources are fetched from the hg repository
  end

  def validate_checksum
    # noop - the sources are fetched from the hg repository
  end

  def to_yaml
    {
      "scm_type" => scm_options[:scm_type],
      "url" => scm_options[:url],
      "tag" => scm_options[:tag],
    }
  end
end
