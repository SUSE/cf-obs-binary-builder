#!/usr/bin/env ruby

require 'tempfile'
require 'erb'

# Define the parent module before requiring the namespaced classes
module CfObsBinaryBuilder
end

#CfObsBinaryBuilder.build("bundler", "1.15.4", nil)
require 'cf_obs_binary_builder/bundler'

module CfObsBinaryBuilder
  DEPENDENCIES = {
    "bundler" => Bundler
  }

  def self.run(*args)
    if args.length != 3
      abort "Wrong number of arguments, please specify: dependency, version and checksum"
    end
    abort "Dependency #{args[0]} not supported!" unless DEPENDENCIES[args[0]]

    DEPENDENCIES[args[0]].new(args[1],args[2]).run
  end
end
