class CfObsBinaryBuilder::Libgdiplus < CfObsBinaryBuilder::BaseDependency
    attr_reader :patches

    def initialize(version)
      super(
        "libgdiplus",
        version,
        "https://github.com/mono/libgdiplus/archive/#{version}.tar.gz"
      )
    end

    # Keep patches already in the obs package for libgdiplus
    def regenerate(verification_data)
      obs_package.checkout(reset: true) do
        generate_package(verification_data)
      end
    end

    def run(verification_data)
        basepath = FileUtils.pwd
        obs_package.create
        obs_package.checkout do
          generate_package(verification_data)
        end
    end
end
