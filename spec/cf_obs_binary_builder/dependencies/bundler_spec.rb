describe CfObsBinaryBuilder::Bundler, '.initialize' do
  it "sets instance variables" do
    builder = CfObsBinaryBuilder::Bundler.new "1.2.3"
    expect(builder.dependency).to eq("bundler")
    expect(builder.version).to eq("1.2.3")
  end
end
