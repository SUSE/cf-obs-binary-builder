class CfObsBinaryBuilder::Php < CfObsBinaryBuilder::BaseDependency
  attr_reader :major_version, :php_extensions

  def initialize(version)
    @version = version
    @major_version = version[/^(\d).*/,1]
    @php_extensions = extract_extensions

    super(
      "php",
      version,
      "https://php.net/distributions/php-#{version}.tar.gz"
    )
  end

  def render_spec_template
    spec_template = File.read(
      File.expand_path(File.dirname(__FILE__) + "/../templates/php.spec.erb"))
    ERB.new(spec_template).result(binding)
  end

  def prepare_sources
    super

    php_extensions.each do |filename, metadata|
      source = metadata[:url]

      log "Downloading the sources in the package directory... (#{source})"
      File.write(filename, open(source).read)
      verify_checksum(filename, metadata[:md5])
    end

    # Download snmp-mibs-downloader
    additional_source = "http://archive.ubuntu.com/ubuntu/pool/multiverse/s/snmp-mibs-downloader/snmp-mibs-downloader_1.1.tar.gz"
    filename = "extensions-"+ File.basename(additional_source)
    File.write(filename, open(additional_source).read)
    verify_checksum(filename, "3001ef3fad46959084cc13a923c98d30")

    # Download geolite ruby scripts
    File.write("download_geoip_db.rb", open("https://raw.githubusercontent.com/cloudfoundry/binary-builder/master/bin/download_geoip_db.rb").read)
    File.write("geoip_downloader.rb", open("https://raw.githubusercontent.com/cloudfoundry/binary-builder/master/lib/geoip_downloader.rb").read)

    # Download fix for 64 bit issues in unixODBC version 2.3.7 if needed
    if File.exists?("native_modules-unixodbc-2.3.7.tar.gz")
      File.write("fix-unixodbc-64-bit-issues-2.3.7.patch", open("https://github.com/lurcher/unixODBC/commit/ca226e2e94f68ef7eee5ed9b6368f6550e3ecd56.patch").read)
    end
  end

  def extract_extensions
    php_extensions_yml = {}
    Dir.mktmpdir("cf-obs-binary-builder-php") do |tmpdir|
      case @version
      when /^5\./
        filename = "php-extensions.yml"
      when /^7\.[01]\./
        filename = "php7-extensions.yml"
      else
        filename = "php72-extensions.yml"
      end

      source = "https://raw.githubusercontent.com/cloudfoundry/buildpacks-ci/master/tasks/build-binary-new/#{filename}"
      File.write(File.join(tmpdir, File.basename(source)), open(source).read)
      php_extensions_yml = YAML.load_file(File.join(tmpdir, filename))
    end

    extensions = {}
    php_extensions_yml.each do |key, elements|
      elements.each do |metadata|
        url = extract_url(metadata)
        if url
          suffix = url[/(\.[a-zA-Z]{1,4}\.{0,1}[a-zA-Z]{0,3})$/,1]
          filename = key + "-" + metadata["name"] + "-" + metadata["version"] + suffix

          extensions[filename] = {
            md5: metadata["md5"],
            url: url,
          }
        end
      end
    end

    extensions
  end

  def extract_url(metadata)
    if Module.const_defined?("CfObsBinaryBuilder::Php::" + metadata['klass'])
      klass = Module.const_get("CfObsBinaryBuilder::Php::" + metadata['klass'])
      extension = klass.new(metadata["name"], metadata["version"], metadata["md5"])
      extension.url
    end
  end

  class BaseRecipe
    attr_reader :name, :version, :checksum

    def initialize(name, version, checksum)
      @name = name
      @version = version
      @checksum = checksum
    end
  end

  class PeclRecipe < BaseRecipe
    def url
      "http://pecl.php.net/get/#{name}-#{version}.tgz"
    end
  end

  class AmqpPeclRecipe < PeclRecipe
  end

  class GeoipRecipe < PeclRecipe
  end

  class HiredisRecipe < BaseRecipe
    def url
      "https://github.com/redis/hiredis/archive/v#{version}.tar.gz"
    end
  end

  class LibSodiumRecipe < BaseRecipe
    def url
      "https://github.com/jedisct1/libsodium/releases/download/#{version}/libsodium-#{version}.tar.gz"
    end
  end

  class LibmemcachedRecipe < BaseRecipe
    def url
      "https://launchpad.net/libmemcached/1.0/#{version}/+download/libmemcached-#{version}.tar.gz"
    end
  end

  class UnixOdbcRecipe < BaseRecipe
    def url
      "http://www.unixodbc.org/unixODBC-#{version}.tar.gz"
    end
  end

  class LibRdKafkaRecipe < BaseRecipe
    def url
      "https://github.com/edenhill/librdkafka/archive/v#{version}.tar.gz"
    end
  end

  class CassandraCppDriverRecipe < BaseRecipe
    def url
      "https://github.com/datastax/cpp-driver/archive/#{version}.tar.gz"
    end
  end

  class LuaPeclRecipe < PeclRecipe
  end

  class LuaRecipe < BaseRecipe
    def url
      "http://www.lua.org/ftp/lua-#{version}.tar.gz"
    end
  end

  class MemcachedPeclRecipe < PeclRecipe
  end

  class PhalconRecipe < PeclRecipe
    def url
      "https://github.com/phalcon/cphalcon/archive/v#{version}.tar.gz"
    end
  end

  class PHPIRedisRecipe < PeclRecipe
    def url
      "https://github.com/nrk/phpiredis/archive/v#{version}.tar.gz"
    end
  end

  class RedisPeclRecipe < PeclRecipe
  end

  class PHPProtobufPeclRecipe < PeclRecipe
    def url
      "https://github.com/allegro/php-protobuf/archive/v#{version}.tar.gz"
    end
  end

  class TidewaysXhprofRecipe < PeclRecipe
    def url
      "https://github.com/tideways/php-xhprof-extension/archive/v#{version}.tar.gz"
    end
  end

  class RabbitMQRecipe < BaseRecipe
    def url
      "https://github.com/alanxz/rabbitmq-c/archive/v#{version}.tar.gz"
    end
  end

  class SuhosinPeclRecipe < PeclRecipe
    def url
      "https://github.com/sektioneins/suhosin/archive/#{version}.tar.gz"
    end
  end

  class TwigPeclRecipe < PeclRecipe
    def url
      "https://github.com/twigphp/Twig/archive/v#{version}.tar.gz"
    end
  end

  class XcachePeclRecipe < PeclRecipe
    def url
      "http://xcache.lighttpd.net/pub/Releases/#{version}/xcache-#{version}.tar.gz"
    end
  end

  class XhprofPeclRecipe < PeclRecipe
    def url
      "https://github.com/phacility/xhprof/archive/#{version}.tar.gz"
    end
  end
end
