# FakeObsPackage - fakes an obs package for interaction between obs and s3
class FakeObsPackage
  attr_reader :version, :dependency, :source, :subdir, :depdir

  def initialize(version, dependency, subdir)
    @depdir = ENV['DEPDIR'] || raise('no DEPDIR environment variable set')
    @version = version
    @dependency = dependency
    @subdir = subdir
  end

  def exists?
    available?
  end

  def build_status
    return :succeeded if available?

    :failed
  end

  def resolve_dep(stack)
    File.basename(Dir[File.join(@depdir, "#{@dependency}*")].grep(/#{stack}/).uniq.max.to_s)
  end

  def available?
    !File.basename(Dir[File.join(@depdir, "#{@dependency}*")].uniq.max.to_s).empty?
  end

  def satisfies_stack(stack)
    # Stack is satisfied if we resolved a dep for the stack (thus not empty)
    return true unless resolve_dep(stack).empty?
  end

  def artifact(stack, s3_bucket)
    buildpack = resolve_dep(stack)
    artifacts = {}
    artifacts[:uri] = "https://s3.amazonaws.com/#{s3_bucket}/dependencies/#{@subdir}/#{buildpack}"
    sha = Digest::SHA256.hexdigest(File.open("#{depdir}/#{buildpack}").read)
    artifacts[:checksum] = sha
    artifacts
  end
end
