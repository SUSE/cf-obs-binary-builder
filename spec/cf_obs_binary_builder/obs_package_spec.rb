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

  describe "#artifact_checksum" do
    let(:sha256_content) { <<EOF }
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

f49c1def007f7aa1c282606e3e2937ef6f67ea90b48e8c062c1d011402930861 /home/abuild/rpmbuild/OTHER/bundler-1.16.2.tgz
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.0.7 (GNU/Linux)

iQEVAwUBW2ANZJM4vHkp3X2RAQgoDAf/Ui5E9LFV4buRZUqe82usOjhdeAQ6DzIt
YyxRiYvaBun9NAqfysYdNzbXwIYKoWGH868w08V+c9fPnhHuFFJDFOVdk4C+dt2k
ezdpc93YVklL3pcVhVseQy+dhTbzdZFotekmFwKjS0NEU7cr5APn35O2bHEo7ipY
K7WuldULzwJ81+hD/OSqJHd9uGPW72mCRAv6w1hP3k3oIUdylsahkp/McefTvG34
lO6ABAQv+HCzpvEEGYlkdgJi7YGNQBdf5j31RsyHcQyPxeS4pVe90/lfWokgISC8
tgSb7SJYd6OpTsEM408iv7byfjIA+DVu/qGbwwk5rtV2oucA56Ne5w==
=iOMP
-----END PGP SIGNATURE-----
EOF
    it "returns the checksum" do
      expect(Open3).to receive(:capture2e).with(/osc ls/).and_return(["bundler-1.16.2-f49c1def\n", double(exitstatus: 0)])
      expect(Open3).to receive(:capture2e).with(/osc getbinaries/).and_return(["", double(exitstatus: 0)])
      expect(File).to receive(:read).and_return(sha256_content)
      expect(subject.artifact_checksum("sle12")).to eq("f49c1def007f7aa1c282606e3e2937ef6f67ea90b48e8c062c1d011402930861")
    end
  end
end
