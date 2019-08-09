# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
#
# This file was extracted from the cloudfoundry/build-binary-new repo
# to allow merging of their php extension patch files
#
# Original authors:
# Daniel Thornton <dthornton@pivotal.io>
# Tyler Phelan <tphelan@pivotal.io>
# David Freilich <dfreilich@pivotal.io>
#
# https://github.com/cloudfoundry/buildpacks-ci/blob/2d61d81bb8c154628f5806ff4f9600403bb417a5/tasks/build-binary-new/merge-extensions.rb

require 'yaml'

class BaseExtensions
  attr_accessor :base_path, :base_yml

  def initialize(path)
    yml_validate(path)
    @base_path = path
    @base_yml = YAML::load_file(path)
  end

  def yml_validate(path)
    unless ['.yaml', '.yml'].include? File.extname(path)
      raise 'Base Extesions requires a .yml file'
    end
  end

  def find_ext(ext_name, category = 'extensions')
    index = find_ext_index(ext_name, category)
    @base_yml[category][index] if index != nil
  end

  def find_ext_index(ext_name, category = 'extensions')
    @base_yml[category].index{|ext| ext_name == ext['name']}
  end

  def patch!(patch_file)
    yml_validate(patch_file)
    patch_yml = YAML::load_file(patch_file)
    return false unless patch_yml
    ['extensions', 'native_modules'].each do |category|
      patch_yml.dig(category,'additions')&.each do |ext|
        idx = find_ext_index(ext['name'], category)
        if idx
          @base_yml[category][idx] = ext
        else
          @base_yml[category].push(ext)

        end
      end
      patch_yml.dig(category,'exclusions')&.each do |ext|
        idx = find_ext_index(ext['name'], category)
          @base_yml[category].delete_at(idx) if idx
      end
    end
    return true
  end

  def patch(patch_file) # return a new BaseExtensions object that has been patched
    new_base_extensions = BaseExtensions.new(@base_path)
    new_base_extensions.patch!(patch_file)
    return new_base_extensions
  end

  def write_yml(extension_file)
    File.open(extension_file, 'w') {|f| f.write @base_yml.to_yaml }
  end
end


