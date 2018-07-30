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

require_relative 'cf_obs_binary_builder/buildpacks/base_buildpack'
require_relative 'cf_obs_binary_builder/dependencies/base_dependency'
require_relative 'cf_obs_binary_builder/dependencies/non_build_dependency'
require_relative 'cf_obs_binary_builder/dependencies/go_dependency'
require_relative 'cf_obs_binary_builder/dependencies/scm_dependency'
require_relative 'cf_obs_binary_builder/obs_package'
require_relative 'cf_obs_binary_builder/syncer'
require_relative 'cf_obs_binary_builder/checksum'

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
  TMP_DIR_SUFFIX = "cf_obs_binary_builder"

  def self.run(*args)
    type = args.shift
    if type == "dependency"
      build_dependency(args)
    elsif type == "buildpack"
      build_buildpack(args)
    elsif type == "sync"
      sync(args)
    else
      print_usage
    end
  end

  def self.build_dependency(args)
    if args.length < 2
      abort "Wrong number of arguments, please specify: dependency, version and checksum"
    end
    dependency = get_build_target(args[0].capitalize)
    abort "Dependency #{args[0]} not supported!" unless dependency

    Dir.mktmpdir(TMP_DIR_SUFFIX) do |tmpdir|
      Dir.chdir tmpdir
      dependency.new(args[1]).run(args[2])
    end
  end

  def self.build_buildpack(args)
    if args.length != 2
      abort "Wrong number of arguments, please specify: buildpack and version"
    end
    buildpack = get_build_target(args[0].capitalize + "Buildpack")
    abort "Buildpack #{args[0]} not supported!" unless buildpack

    Dir.mktmpdir(TMP_DIR_SUFFIX) do |tmpdir|
      Dir.chdir tmpdir
      buildpack.new(args[1]).run
    end
  end

  def self.sync(args)
    if args.length != 1
      abort "Wrong number of arguments, please specify: manifest_path"
    end

    manifest_path = args.shift
    Syncer.new(manifest_path).sync
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

  #{File.basename($0)} buildpack <buildpack> <version>
    Create a new buildpack on OBS.

  #{File.basename($0)} sync <manifest_path>
    Create missing OBS packages for all dependencies in the given manifest.
EOF
  end
end
