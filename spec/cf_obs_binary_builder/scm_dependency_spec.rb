describe CfObsBinaryBuilder::SCMDependency do
  let(:dependency) {
    CfObsBinaryBuilder::SCMDependency.new(
      'bundler',
      '1.2.3',
      {
        scm_type: "mercurial",
        url: "http://example.com/repo",
        tag: "1.2.3"
      }
    )
  }

  describe "#to_yaml" do
    it "includes the scm metada" do
      yml = dependency.to_yaml

      expect(yml["scm_type"]).to eq("mercurial")
      expect(yml["url"]).to eq("http://example.com/repo")
      expect(yml["tag"]).to eq("1.2.3")
    end
  end
end
