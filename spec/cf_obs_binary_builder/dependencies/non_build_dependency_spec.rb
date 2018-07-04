describe CfObsBinaryBuilder::NonBuildDependency do
  let(:dependency) {
    CfObsBinaryBuilder::NonBuildDependency.new(
      "bundler",
      "1.2.3",
      "http://rubygems.org/gems/bundler-1.2.3.gem",
      1234,
      "MIT",
      "https://bundler.io"
    )
  }

  describe "#render_spec_template" do
    it "contains the proper steps" do
      script = dependency.render_spec_template

      expect(script).to include("MIT")
      expect(script).to include("cp %{SOURCE0} /home/abuild/rpmbuild/OTHER/")
      expect(script).to match(/Name:\s*bundler/)
      expect(script).to match(/Version:\s*1.2.3/)
      expect(script).to match(/License:\s*MIT/)
      expect(script).to match(/Url:\s*https:\/\/bundler.io/)
    end
  end
end
