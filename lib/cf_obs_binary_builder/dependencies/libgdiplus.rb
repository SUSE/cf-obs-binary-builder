class CfObsBinaryBuilder::Libgdiplus < CfObsBinaryBuilder::BaseDependency
    attr_reader :patches

    def initialize(version)
      super(
        "libgdiplus",
        version,
        "https://github.com/mono/libgdiplus/archive/#{version}.tar.gz"
      )
      @patches = ["libgdiplus_5.6_64bit_comp_issue.patch"]
    end

    def prepare_sources
      # noop - the sources are fetched from the github repository (no checksum to check against)
    end

    def write_sources_yaml
      # noop - the sources are fetched from the github repository (no checksum to check against)
    end

    def validate_checksum(_checksum)
      # noop - the sources are fetched from the github repository (no checksum to check against)
    end

    # Keep patches already in the obs package for libgdiplus
    def regenerate(verification_data)
      obs_package.checkout(reset: true) do
        copy_patches()
        generate_package(verification_data)
      end
    end

    def run(verification_data)
        basepath = FileUtils.pwd
        obs_package.create
        obs_package.checkout do
          copy_patches()
          generate_package(verification_data)
        end
    end

    def validate_checksum(_checksum)
      # noop - the sources are fetched from the github repository (no checksum to check against)
    end

    def copy_patches()
      log 'Copying patches'
      for patch in patches do
        FileUtils.cp(File.dirname(__FILE__) + "/../templates/patches/#{patch}",".")
      end
    end
end