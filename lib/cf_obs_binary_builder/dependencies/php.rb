require_relative "../../build-binary-new/merge-extensions"

class CfObsBinaryBuilder::Php < CfObsBinaryBuilder::BaseDependency
  attr_reader :major_version, :php_extensions, :patches

  def initialize(version)
    @version = version
    @major_version = version[/^(\d).*/,1]
    @php_extensions = extract_extensions
    @patches = ["libmemcached-gcc7-build.patch", "mailparse-php-7.3.patch", "fix-unixodbc-64-bit-issues-2.3.7.patch", "yaf-3.0.7-php73.patch"]

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

    copy_patches()
  end

  def run(verification_data)
    basepath = FileUtils.pwd
    obs_package.create
    obs_package.checkout do
      copy_patches()
      generate_package(verification_data)
    end
  end

  def copy_patches()
    log 'Copying patches'
    for patch in patches do
      FileUtils.cp(File.dirname(__FILE__) + "/../templates/patches/#{patch}",".")
    end
  end

  def extract_extensions
    php_extensions_yml = {}
    url_base = "https://raw.githubusercontent.com/cloudfoundry/buildpacks-ci/master/tasks/build-binary-new/"
    Dir.mktmpdir("cf-obs-binary-builder-php") do |tmpdir|
      case @version
      when /^7\.1\./
        patch_filename = "php71-extensions-patch.yml"
      when /^7\.2\./
        patch_filename = "php72-extensions-patch.yml"
      else
        patch_filename = "php73-extensions-patch.yml"
      end

      base_path = File.join(tmpdir, "php7-base-extensions.yml")
      patch_path = File.join(tmpdir, patch_filename)
      final_path = File.join(tmpdir, "php7-extensions.yml")

      File.write(
        base_path, open(File.join(url_base, "php7-base-extensions.yml")).read
      )
      File.write(
        patch_path, open(File.join(url_base, patch_filename)).read
      )

      base_extensions = BaseExtensions.new(base_path)
      base_extensions.patch(patch_path).write_yml(final_path)

      php_extensions_yml = YAML.load_file(final_path)
    end

    extensions = {}
    php_extensions_yml.each do |key, elements|
      elements.each do |metadata|
        # pdo_sqlsrv 5.3.0 is not compatible with PHP 7.3.x
        if metadata["name"] == "pdo_sqlsrv" && metadata["version"] == "5.3.0"
          metadata["version"] = "5.6.0"
          metadata["md5"] = "8ab9ae9af6d9f9a24bf31bd6058656b2"
        end
        # sqlsrv 5.3.0 is not compatible with PHP 7.3.x
        if metadata["name"] == "sqlsrv" && metadata["version"] == "5.3.0"
          metadata["version"] = "5.6.0"
          metadata["md5"] = "73ea717bd9e3deb72c773f2a82186327"
        end
        # xdebug 2.6.0 is not compatible with PHP 7.3.x
        if metadata["name"] == "xdebug" && metadata["version"] == "2.6.1"
          metadata["version"] = "2.7.0RC2"
          metadata["md5"] = "e8cabe003d6990b157d0d8caee374844"
        end

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
      "https://pecl.php.net/get/#{name}-#{version}.tgz"
    end
  end

  class AmqpPeclRecipe < PeclRecipe
  end

  class MaxMindRecipe < BaseRecipe
    def url
      "https://github.com/maxmind/MaxMind-DB-Reader-php/archive/v#{version}.tar.gz"
    end
  end

  class LibMaxMindRecipe < BaseRecipe
    def url
      "https://github.com/maxmind/libmaxminddb/releases/download/#{version}/libmaxminddb-#{version}.tar.gz"
    end
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
      "https://www.lua.org/ftp/lua-#{version}.tar.gz"
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
      "https://xcache.lighttpd.net/pub/Releases/#{version}/xcache-#{version}.tar.gz"
    end
  end

  class XhprofPeclRecipe < PeclRecipe
    def url
      "https://github.com/phacility/xhprof/archive/#{version}.tar.gz"
    end
  end
end
