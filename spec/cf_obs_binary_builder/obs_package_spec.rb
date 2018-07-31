require_relative "../spec_helper"

describe CfObsBinaryBuilder::ObsPackage do
  subject { described_class.new("bundler-1.16.2", "home:ObsUser") }

  describe "#obs_project" do
    it "returns the correct value" do
      expect(subject.obs_project).to eq("home:ObsUser")
    end
  end

  describe "#build_succeeded?" do
    let(:failed_output) { <<EOF }
bundler-1.16.2;failed;succeeded
EOF
    let(:succeeded_output) { <<EOF }
bundler-1.16.2;succeeded;succeeded
EOF

    it "returns true" do
      expect(Open3).to receive(:capture2e).and_return([succeeded_output, double(exitstatus: 0)])

      expect(subject.build_succeeded?).to be(true)
    end

    it "returns false" do
      expect(Open3).to receive(:capture2e).and_return([failed_output, double(exitstatus: 0)])

      expect(subject.build_succeeded?).to be(false)
    end
  end
end
