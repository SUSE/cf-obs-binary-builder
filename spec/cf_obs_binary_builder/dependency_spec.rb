describe CfObsBinaryBuilder::Dependency, '#obs_project' do
  let(:dependency) { CfObsBinaryBuilder::Dependency.new }

  context "when OBS_PROJECT env variable is not set" do
    it "exits with error" do
      expect{ dependency.obs_project }.to raise_error(RuntimeError, "no OBS_PROJECT environment variable set")
    end
  end

  context "when OBS_PROJECT env variable is not set" do
    before do
      ENV["OBS_PROJECT"] = "home:ObsUser"
    end
    it "returns the correct value" do
      expect(dependency.obs_project).to eq("home:ObsUser")
    end
  end
end
