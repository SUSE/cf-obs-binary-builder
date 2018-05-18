class CfObsBinaryBuilder::Jruby < CfObsBinaryBuilder::Dependency
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

  def prepare_files
    super

    log "Caching maven dependencies..."
    working_dir = Dir.pwd
    Dir.mktmpdir do |dir|
      `tetra init jruby "#{working_dir}/jruby-src-#{jruby_version}.tar.gz"`

      Dir.chdir "jruby" do
        log `tetra dry-run -c 'cd src/jruby-#{jruby_version}; mvn -P \!truffle -Djruby.default.ruby.version=2.3'`
        Dir.chdir "src/jruby-#{jruby_version}" do
          log `tetra generate-all`
        end
        FileUtils.cp "packages/#{dependency}-kit/#{dependency}-kit.tar.xz", working_dir
      end
    end
  end
end
