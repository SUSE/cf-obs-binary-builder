# scm dependencies are dependencies where the sources are not downloaded as a
# tarball but taken from a scm like git or mercurial instead
class CfObsBinaryBuilder::SCMDependency < CfObsBinaryBuilder::BaseDependency
  attr_reader :scm_options

  def initialize(dependency, version, scm_options)
    @scm_options = scm_options
    super(dependency, version)
  end

  def prepare_sources
    # noop - the sources are fetched from the hg repository
  end

  def validate_checksum(_checksum)
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
