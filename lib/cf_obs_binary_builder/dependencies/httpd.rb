class CfObsBinaryBuilder::Httpd < CfObsBinaryBuilder::BaseDependency
  def initialize(version)
    super(
      "httpd",
      version,
      "https://archive.apache.org/dist/httpd/httpd-#{version}.tar.bz2"
    )
  end

  def prepare_sources
    additional_sources = [
      {
        url: "https://www.apache.org/dist/apr/apr-1.6.5.tar.bz2",
        checksum: "a67ca9fcf9c4ff59bce7f428a323c8b5e18667fdea7b0ebad47d194371b0a105"
      },
      {
        url: "https://www.apache.org/dist/apr/apr-iconv-1.2.2.tar.bz2",
        checksum: "7d454e0fe32f2385f671000e3b755839d16aabd7291e3947c973c90377c35313"
      },
      {
        url: "https://www.apache.org/dist/apr/apr-util-1.6.1.tar.bz2",
        checksum: "d3e12f7b6ad12687572a3a39475545a072608f4ba03a6ce8a3778f607dd0035b"
      }
    ]

    additional_sources.each do |additional_source|
      download_source(additional_source[:url])
      verify_checksum(additional_source[:url], additional_source[:checksum])
    end

    super
  end
end
