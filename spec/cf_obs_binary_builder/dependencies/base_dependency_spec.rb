require_relative "../../spec_helper"

describe CfObsBinaryBuilder::BaseDependency do
  let(:dependency) { CfObsBinaryBuilder::BaseDependency.new('bundler', '1.2.3', 'http://example.com/file.tgz', '12345') }

  describe "#validate_checksum" do
    it "raises an exception if the checksum does not match" do
      expect(Digest::SHA256).to receive_message_chain(:file, :hexdigest).and_return("wrongchecksum")
      expect{ dependency.validate_checksum }.to raise_error(/mismatch/)
    end

    it "doesn't raise if the checksum matches" do
      expect(Digest::SHA256).to receive_message_chain(:file, :hexdigest).and_return("12345")
      expect{ dependency.validate_checksum }.to_not raise_error
    end
  end
end
