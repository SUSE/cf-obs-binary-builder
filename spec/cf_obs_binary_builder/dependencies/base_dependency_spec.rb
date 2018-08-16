require_relative "../../spec_helper"

describe CfObsBinaryBuilder::BaseDependency do
  let(:dependency) { CfObsBinaryBuilder::BaseDependency.new('bundler', '1.2.3', 'http://example.com/file.tgz') }

  describe "#validate_checksum" do
    it "raises an exception if the checksum does not match" do
      expect(Digest::SHA256).to receive_message_chain(:file, :hexdigest).and_return("wrongchecksum!!!!!!!!!!!!!!!!!!!!!!!11111!!!!!1!!!!!!!!!!!111111")
      expect{ dependency.validate_checksum("correctchecksum!!!!!!!!!!!!!!!!!!!!!11111!!!!!1!!!!!!!!!!!111111") }.to raise_error(/mismatch/)
    end

    it "doesn't raise if the checksum matches" do
      expect(Digest::SHA256).to receive_message_chain(:file, :hexdigest).and_return("correctchecksum!!!!!!!!!!!!!!!!!!!!!11111!!!!!1!!!!!!!!!!!111111")
      expect{ dependency.validate_checksum("correctchecksum!!!!!!!!!!!!!!!!!!!!!11111!!!!!1!!!!!!!!!!!111111") }.to_not raise_error
    end
  end

  describe "#write_sources_yaml" do
    it "fails if validate_checksum has not been called" do
      expect { dependency.write_sources_yaml }.to raise_error(/not validated/)
    end

    it "succeeds if validate_checksum has been called successfully" do
      expect(Digest::SHA256).to receive_message_chain(:file, :hexdigest).and_return("correctchecksum!!!!!!!!!!!!!!!!!!!!!11111!!!!!1!!!!!!!!!!!111111")
      expect(File).to receive(:write) # Avoid writting the sources.yaml file
      dependency.validate_checksum("correctchecksum!!!!!!!!!!!!!!!!!!!!!11111!!!!!1!!!!!!!!!!!111111")
      expect { dependency.write_sources_yaml }.to_not raise_error
    end
  end
end
