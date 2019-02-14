#!/usr/bin/env ruby

require 'tempfile'
require 'erb'
require 'open-uri'
require 'digest'
require 'yaml'
require 'json'
require 'open3'

# Define the parent module before requiring the namespaced classes
module CfObsBinaryBuilder end

require_relative 'cf_obs_binary_builder/rpm_spec_helpers'
require_relative 'cf_obs_binary_builder/buildpacks/base_buildpack'
require_relative 'cf_obs_binary_builder/dependencies/base_dependency'
require_relative 'cf_obs_binary_builder/dependencies/non_build_dependency'
require_relative 'cf_obs_binary_builder/dependencies/s3_dependency'
require_relative 'cf_obs_binary_builder/dependencies/go_dependency'
require_relative 'cf_obs_binary_builder/dependencies/scm_dependency'
require_relative 'cf_obs_binary_builder/dependencies/pypi_dependency'
require_relative 'cf_obs_binary_builder/dependencies/npm_dependency'
require_relative 'cf_obs_binary_builder/fake_obs_package'
require_relative 'cf_obs_binary_builder/obs_package'
require_relative 'cf_obs_binary_builder/syncer'
require_relative 'cf_obs_binary_builder/checksum'
require_relative 'cf_obs_binary_builder/manifest'

[
  File.join(File.dirname(__FILE__), "cf_obs_binary_builder/dependencies/*"),
  File.join(File.dirname(__FILE__), "cf_obs_binary_builder/buildpacks/*")
].each do |glob|
  Dir.glob(glob).each do |f|
    require_relative f
  end
end
LOG_LEVELS = {
  "error" => 0,
  "warning" => 1,
  "info" => 2,
  "debug" => 3,
}

# This method is used to print message based on the log level set by the
# VERBOSITY env variable. When a message is targeted for log level "info",
# than means it will be displayed only when VERBOSITY is either info or debug.
def log(message, level="info")
  user_setting = LOG_LEVELS[ENV["VERBOSITY"]] || LOG_LEVELS["info"]
  if user_setting && user_setting >= LOG_LEVELS[level]
    puts message
  end
end

module CfObsBinaryBuilder
  # If set, it will download the buildpack sources in cache directory and
  # use that if it exists. This prevents multiple downloads when, for example,
  # we are polling for dependencies which are currently building on OBS.
  CACHE_SOURCES = ENV["CACHE_SOURCES"]
  TMP_DIR_SUFFIX = "cf_obs_binary_builder"

  def self.run(*args)
    type = args.shift
    case type
    when "dependency"
      build_dependency(args)
    when "buildpack"
      build_buildpack(args)
    when "sync"
      sync(args)
    when "regenerate-specs"
      regenerate_specs(args)
    else
      print_usage
    end
  end

  def self.build_dependency(args)
    if args.length < 2
      abort "Wrong number of arguments, please specify: dependency, version and checksum"
    end
    dependency = get_build_target(args[0].capitalize.tr("-", ""))
    abort "Dependency #{args[0]} not supported!" unless dependency

    Dir.mktmpdir(TMP_DIR_SUFFIX) do |tmpdir|
      Dir.chdir tmpdir do
        dependency.new(args[1]).run(args[2])
      end
    end
  end

  def self.build_buildpack(args)
    stack_mappings = parse_stack_mappings!(require_env_var("STACK_MAPPINGS"))
    s3_bucket = require_env_var("STAGING_BUILDPACKS_BUCKET")

    if args.length != 3
      abort "Wrong number of arguments, please specify: buildpack, upstream-version and revision"
    end
    buildpack = get_build_target(args[0].capitalize.tr('-', '') + 'Buildpack')
    abort "Buildpack #{args[0]} not supported!" unless buildpack

    Dir.mktmpdir(TMP_DIR_SUFFIX) do |tmpdir|
      Dir.chdir tmpdir do
        result = buildpack.new(args[1], args[2]).run(stack_mappings, s3_bucket)

        case result
        when :failed
          puts 'At least one dependency is in "failed" state. Fix it and retry.'
          exit 1
        when :in_process
          puts 'Not all dependencies are in "succeeded" state. Retry later.'
          exit 2
        end
      end
    end
  end

  def self.sync(args)
    obs_project = require_env_var("OBS_DEPENDENCY_PROJECT")

    base_stacks = parse_stack_mappings!(ENV['STACK_MAPPINGS']).values
    if args.length != 1
      abort "Wrong number of arguments, please specify: manifest_path"
    end

    manifest_path = args.shift
    package_statuses = CfObsBinaryBuilder::ObsPackage.project_package_statuses(obs_project)
    unknown = Syncer.new(manifest_path).sync(base_stacks, package_statuses)
    if !unknown.empty?
      puts "Encountered unknown dependencies: #{unknown.join(",")}"
      exit 1
    end
  end

  def self.regenerate_specs(args)
    obs_project = require_env_var("OBS_DEPENDENCY_PROJECT")

    base_stacks = parse_stack_mappings!(ENV['STACK_MAPPINGS']).values
    if args.length != 1
      abort "Wrong number of arguments, please specify: manifest_path"
    end

    manifest_path = args.shift
    package_statuses = CfObsBinaryBuilder::ObsPackage.project_package_statuses(obs_project)
    Syncer.new(manifest_path).regenerate_specs(base_stacks, package_statuses)
  end

  def self.get_build_target(dependency)
    const_get(dependency)
  rescue NameError
    nil
  end

  def self.print_usage
    puts <<EOF
USAGE:
  #{File.basename($0)} dependency <dependency> <version> <checksum>
    Create a new package on OBS.

  #{File.basename($0)} buildpack <buildpack> <upstream-version> <revision>
    Create a new buildpack on OBS.

  #{File.basename($0)} sync <manifest_path>
    Create missing OBS packages for all dependencies in the given manifest.

  #{File.basename($0)} regenerate-specs <manifest_path>
    Regenerate the spec files for all (existing) dependencies on OBS.
EOF
  end

  private

  def self.require_env_var(env_var_name)
    return ENV[env_var_name] || raise("no #{env_var_name} environment variable set")
  end

  def self.parse_stack_mappings!(mapping_json)
    raise("no STACK_MAPPINGS environment variable set") if mapping_json.strip.empty?

    JSON.parse(mapping_json.strip)
  end
end
