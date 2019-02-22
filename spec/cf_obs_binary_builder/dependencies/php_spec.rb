describe CfObsBinaryBuilder::Php::BaseRecipe do
  it "provides name, version and checksum" do
    object = CfObsBinaryBuilder::Php::BaseRecipe.new(
      "test", "1.0.0", "51d5827651328236ecb7c60517c701c2"
    )
    expect(object.name).to eq("test")
    expect(object.version).to eq("1.0.0")
    expect(object.checksum).to eq("51d5827651328236ecb7c60517c701c2")
  end
end

describe CfObsBinaryBuilder::Php::PeclRecipe do
  it "provides name, version, checksum and url" do
    apcu = CfObsBinaryBuilder::Php::PeclRecipe.new(
      "apcu", "4.0.11", "13c0c0dd676e5a7905d54fa985d0ee62"
    )
    expect(apcu.name).to eq("apcu")
    expect(apcu.version).to eq("4.0.11")
    expect(apcu.checksum).to eq("13c0c0dd676e5a7905d54fa985d0ee62")
    expect(apcu.url).to eq("https://pecl.php.net/get/apcu-4.0.11.tgz")
  end
end
