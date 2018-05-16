describe CfObsBinaryBuilder::Dependency, '#obs_project' do
  let(:dependency) { CfObsBinaryBuilder::Dependency.new('bundler', '1.2.3', 'http://example.com/file.tgz', '12345') }

  context "when OBS_PROJECT env variable is not set" do
    before(:each) do
      ENV.delete "OBS_PROJECT"
    end

    it "exits with error" do
      expect{ dependency.obs_project }.to raise_error(RuntimeError, "no OBS_PROJECT environment variable set")
    end
  end

  context "when OBS_PROJECT env variable is not set" do
    before(:each) do
      ENV["OBS_PROJECT"] = "home:ObsUser"
    end

    it "returns the correct value" do
      expect(dependency.obs_project).to eq("home:ObsUser")
    end
  end

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
