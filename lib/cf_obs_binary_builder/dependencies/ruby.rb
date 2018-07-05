class CfObsBinaryBuilder::Ruby < CfObsBinaryBuilder::BaseDependency
  attr_reader :minor_version

  def initialize(version, checksum)
    @minor_version = version.match(/(\d+\.\d+)\./)[1]

    super(
      "ruby",
      version,
      "https://cache.ruby-lang.org/pub/ruby/#{minor_version}/ruby-#{version}.tar.gz",
      checksum
    )
  end
end
