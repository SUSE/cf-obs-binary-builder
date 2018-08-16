require_relative "../spec_helper"

describe CfObsBinaryBuilder::Checksum do
  let(:sha512sum_path) { File.expand_path("../fixtures/libffi-sha512.sum", __dir__) }

  describe ".for" do
    it "uses depwatcher for dependencies it knows" do
      expect(Open3).to receive(:capture3).and_return([nil, {sha256: "abcdefg"}.to_json])

      expect(described_class.for("ruby", "2.5.1")).to eq("abcdefg")
    end

    it "returns libffi checksums" do
      expect(described_class).to receive_message_chain(:open, :read).and_return(File.read(sha512sum_path))
      expect(described_class.for("libffi", "3.2.1")).to eq("980ca30a8d76f963fca722432b1fe5af77d7a4e4d2eac5144fbc5374d4c596609a293440573f4294207e1bdd9fda80ad1e1cafb2ffb543df5a275bc3bd546483")
    end
  end
end
