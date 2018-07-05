require_relative "../spec_helper"

describe CfObsBinaryBuilder::ObsPackage do
  subject { described_class.new("foo", "home:ObsUser") }

  describe "#obs_project" do
    it "returns the correct value" do
      expect(subject.obs_project).to eq("home:ObsUser")
    end
  end
end
