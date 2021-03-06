require_relative "../../spec_helper"

describe CfObsBinaryBuilder::BaseDependency do
  let(:dependency) { CfObsBinaryBuilder::BaseDependency.new('bundler', '1.2.3', 'http://example.com/file.tgz') }

  describe "#validate_checksum" do
    it "raises an exception if the checksum does not match" do
      expect(Digest::SHA256).to receive_message_chain(:file, :hexdigest).and_return("wrongchecksum!!!!!!!!!!!!!!!!!!!!!!!11111!!!!!1!!!!!!!!!!!111111")
      expect{ dependency.validate_checksum("correctchecksum!!!!!!!!!!!!!!!!!!!!!11111!!!!!1!!!!!!!!!!!111111") }.to raise_error(/mismatch/)
    end

    it "doesn't raise if the checksum matches" do
      expect(File).to receive(:basename).and_return("spec/fixtures/test_sources.tgz")
      expect{ dependency.validate_checksum("6fba0488278885cb8ac1442d32bc331c4c850c2b8cf12b98b71098df87e061e7") }.to_not raise_error
    end
  end
end
