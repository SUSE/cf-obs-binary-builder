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
        url: "http://apache.mirrors.tds.net/apr/apr-1.6.3.tar.gz",
        checksum: "8fdabcc0004216c3588b7dca0f23d104dfe012a47e2bb6f13827534a6ee73aa7"
      },
      {
        url: "http://apache.mirrors.tds.net/apr/apr-iconv-1.2.2.tar.gz",
        checksum: "ce94c7722ede927ce1e5a368675ace17d96d60ff9b8918df216ee5c1298c6a5e"
      },
      {
        url: "http://apache.mirrors.tds.net/apr/apr-util-1.6.1.tar.gz",
        checksum: "b65e40713da57d004123b6319828be7f1273fbc6490e145874ee1177e112c459"
      }
    ]

    additional_sources.each do |additional_source|
      download_source(additional_source[:url])
      verify_checksum(additional_source[:url], additional_source[:checksum])
    end

    super
  end
end
