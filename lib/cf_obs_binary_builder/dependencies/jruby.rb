class CfObsBinaryBuilder::Jruby < CfObsBinaryBuilder::BaseDependency
  attr_reader :jruby_version, :ruby_version

  def initialize(version)
    raise "Invalid version" unless version.match(/ruby-(.*)-jruby-(.*)/)

    @jruby_version = version.match(/jruby-(.*)/)[1]
    @ruby_version = version.match(/ruby-([^-]*)-/)[1]

    super(
      "jruby",
      "#{jruby_version}_ruby#{ruby_version}",
      "https://s3.amazonaws.com/jruby.org/downloads/#{jruby_version}/jruby-src-#{jruby_version}.tar.gz"
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
