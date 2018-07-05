class CfObsBinaryBuilder::Jruby < CfObsBinaryBuilder::BaseDependency
  attr_reader :jruby_version, :ruby_version

  def initialize(version, checksum)
    @jruby_version = version.match(/(.*)_ruby-\d+\.\d.*/)[1]
    @ruby_version = version.match(/.*_ruby-(\d+\.\d).*/)[1]

    super(
      "jruby",
      version,
      "https://s3.amazonaws.com/jruby.org/downloads/#{jruby_version}/jruby-src-#{jruby_version}.tar.gz",
      checksum
    )
  end

  def prepare_sources
    super

    log "Download ca bundle..."
    system("curl -L https://curl.haxx.se/ca/cacert.pem  > cacerts.pem")

    log "Caching maven dependencies..."
    working_dir = Dir.pwd
    Dir.mktmpdir do |dir|
      log `tetra init jruby "#{working_dir}/jruby-src-#{jruby_version}.tar.gz"`

      Dir.chdir "jruby" do
        log `tetra dry-run -s 'cd src/jruby-#{jruby_version}; mvn -P \!truffle -Djruby.default.ruby.version=2.3'`
        Dir.chdir "src/jruby-#{jruby_version}" do
          log `tetra generate-all`
        end
        FileUtils.cp "packages/#{dependency}-kit/#{dependency}-kit.tar.xz", working_dir
      end
    end
  end
end
