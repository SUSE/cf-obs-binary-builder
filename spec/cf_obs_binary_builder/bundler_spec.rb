describe CfObsBinaryBuilder::Bundler, '.initialize' do
  it "sets instance variables" do
    builder = CfObsBinaryBuilder::Bundler.new "1.2.3", "1234asdf"
    expect(builder.binary).to eq("bundler")
    expect(builder.version).to eq("1.2.3")
    expect(builder.checksum).to eq("1234asdf")
  end
end
