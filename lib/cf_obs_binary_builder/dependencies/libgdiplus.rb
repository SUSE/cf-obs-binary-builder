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

    def copy_patches()
      log 'Copying patches'
      for patch in patches do
        FileUtils.cp(File.dirname(__FILE__) + "/../templates/patches/#{patch}",".")
      end
    end
end
