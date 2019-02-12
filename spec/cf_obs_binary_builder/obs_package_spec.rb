require_relative "../spec_helper"

describe CfObsBinaryBuilder::ObsPackage do
  subject { described_class.new("bundler-1.16.2", "home:ObsUser") }

  describe "#obs_project" do
    it "returns the correct value" do
      expect(subject.obs_project).to eq("home:ObsUser")
    end
  end

  describe "#build_status" do

  let(:failed_output) do
<<EOF
  <resultlist state="9ea3fb39ad70e5513e194eba21fb85d4">
    <result  project="Cloud:Platform:buildpacks:dependencies" repository="SLE_15" arch="x86_64" code="published" state="published">
      <status package="bundler-1.16.2" code="failed" />
    </result>
    <result  project="Cloud:Platform:buildpacks:dependencies" repository="SLE_12_SP3" arch="x86_64" code="published" state="published">
      <status package="bundler-1.16.2" code="failed" />
    </result>
    <result  project="Cloud:Platform:buildpacks:dependencies" repository="IRRELEVANT_STACK" arch="x86_64" code="published" state="published">
      <status package="bundler-1.16.2" code="failed" />
    </result>
  </resultlist>
EOF
  end

  let(:succeeded_output) do
<<EOF
  <resultlist state="9ea3fb39ad70e5513e194eba21fb85d4">
    <result  project="Cloud:Platform:buildpacks:dependencies" repository="SLE_15" arch="x86_64" code="published" state="published">
      <status package="bundler-1.16.2" code="succeeded" />
    </result>
    <result  project="Cloud:Platform:buildpacks:dependencies" repository="SLE_12_SP3" arch="x86_64" code="published" state="published">
      <status package="bundler-1.16.2" code="failed" />
    </result>
    <result  project="Cloud:Platform:buildpacks:dependencies" repository="IRRELEVANT_STACK" arch="x86_64" code="published" state="published">
      <status package="bundler-1.16.2" code="failed" />
    </result>
  </resultlist>
EOF
  end

  let(:in_process_output) do
<<EOF
  <resultlist state="9ea3fb39ad70e5513e194eba21fb85d4">
    <result  project="Cloud:Platform:buildpacks:dependencies" repository="SLE_15" arch="x86_64" code="published" state="published">
      <status package="bundler-1.16.2" code="scheduled" />
    </result>
    <result  project="Cloud:Platform:buildpacks:dependencies" repository="SLE_12_SP3" arch="x86_64" code="published" state="published">
      <status package="bundler-1.16.2" code="succeeded" />
    </result>
    <result  project="Cloud:Platform:buildpacks:dependencies" repository="IRRELEVANT_STACK" arch="x86_64" code="published" state="published">
      <status package="bundler-1.16.2" code="failed" />
    </result>
  </resultlist>
EOF
  end

  let(:stack){ "cfsle15fs" }

    it "returns :succeeded if all the statuses are 'succeeded'" do
      expect(Open3).to receive(:capture2e).and_return([succeeded_output, double(exitstatus: 0)])
      expect(subject.build_status(stack)).to eq(:succeeded)
    end

    it "returns :failed if one or more statuses are 'failed'" do
      expect(Open3).to receive(:capture2e).and_return([failed_output, double(exitstatus: 0)])
      expect(subject.build_status(stack)).to eq(:failed)
    end

    it "returns :in_process if it is not :succeeded or :failed" do
      expect(Open3).to receive(:capture2e).and_return([in_process_output, double(exitstatus: 0)])
      expect(subject.build_status(stack)).to eq(:in_process)
    end
  end

  describe "#artifact_checksum" do
    let(:sha256_content) { <<EOF }
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

f49c1def007f7aa1c282606e3e2937ef6f67ea90b48e8c062c1d011402930861 /home/abuild/rpmbuild/OTHER/bundler-1.16.2-f49c1def.tgz
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
      expect(Open3).to receive(:capture2e).with(/osc ls/).and_return(["bundler-1.16.2.tgz.sha256\nbundler-1.16.2-f49c1def.tgz\n", double(exitstatus: 0)])
      expect(Open3).to receive(:capture2e).with(/osc getbinaries/).and_return(["", double(exitstatus: 0)])
      expect(File).to receive(:read).and_return(sha256_content)

      artifact = subject.artifact("sle12", "buildpacks-staging")
      expect(artifact[:checksum]).to eq("f49c1def007f7aa1c282606e3e2937ef6f67ea90b48e8c062c1d011402930861")
      expect(artifact[:uri]).to eq("https://s3.amazonaws.com/buildpacks-staging/dependencies/bundler/bundler-1.16.2-f49c1def.tgz")
    end
  end
end
