# encoding: utf-8

# Copyright (c) 2016, HipByte SPRL and contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

class FabricKitConfig
  attr_accessor :name, :info

  def initialize(name)
    @name = name
    @info = {}
  end

  def to_hash
    {
      'KitInfo' => info,
      'KitName' => name
    }
  end
end

class FabricConfig
  attr_accessor :api_key, :build_secret, :kits, :beta_block

  def api_key=(api_key)
    @config.info_plist['Fabric']['APIKey'] = api_key
    @api_key = api_key
  end

  def initialize(config)
    @config = config
    config.info_plist['Fabric'] ||= {}
    config.info_plist['Fabric']['Kits'] ||= []
  end

  def kit(name, &block)
    kit_config = FabricKitConfig.new(name)
    block.call(kit_config.info) if block
    @config.info_plist['Fabric']['Kits'] << kit_config.to_hash
  end

  def beta(&block)
    @beta_block = block if block
  end
end

module Motion::Project
  class Config
    variable :fabric

    def fabric(&block)
      @fabric ||= FabricConfig.new(self)
      block.call(@fabric) if block
      @fabric
    end
  end
end

Motion::Project::App.setup do |app|
  app.pods do
    pod 'Fabric', '~> 1.6'
    pod 'Crashlytics', '~> 3.7'
  end
end

def fabric_setup(&block)
  pods_root = Motion::Project::CocoaPods::PODS_ROOT
  api_key = App.config.fabric.api_key
  build_secret = App.config.fabric.build_secret

  App.fail "Fabric's api_key cannot be empty" unless api_key
  App.fail "Fabric's build_secret cannot be empty" unless build_secret

  block.call(pods_root, api_key, build_secret)
end

def fabric_run(platform)
  dsym_path = App.config.app_bundle_dsym(platform)
  project_dir = File.expand_path(App.config.project_dir)
  env = {
    BUILT_PRODUCTS_DIR: File.expand_path(File.join(App.config.versionized_build_dir(platform), App.config.bundle_filename)),
    INFOPLIST_PATH: 'Info.plist',
    DWARF_DSYM_FILE_NAME: File.basename(dsym_path),
    DWARF_DSYM_FOLDER_PATH: File.expand_path(File.dirname(dsym_path)),
    PROJECT_DIR: project_dir,
    SRCROOT: project_dir,
    PLATFORM_NAME: platform.downcase,
    PROJECT_FILE_PATH: "",
    CONFIGURATION: App.config_mode ==  'development' ? 'debug' : 'release',
  }
  env_string = env.map { |k,v| "#{k}='#{v}'" }.join(' ')
  fabric_setup do |pods_root, api_key, build_secret|
    App.info "Fabric", "Uploading .dSYM file"
    system("env #{env_string} sh #{pods_root}/Fabric/run #{api_key} #{build_secret}")
  end
end

namespace :fabric do
  task :setup do
    # Build for the simulator so we generate the data needed by the "run" tool
    Rake::Task["build:simulator"].execute
    # Execute the "run" tool so Fabric.app registers our app
    Rake::Task["fabric:dsym:simulator"].execute
    # Do not build again
    ENV["skip_build"] = 'true'
    # Run the app in the simulator so Fabric activates our app
    Rake::Task["simulator"].execute
  end

  task :upload do
    App.config.fabric.beta_block.call if App.config.fabric.beta_block

    file = File.join(Dir.tmpdir, 'motion-fabric.rb')
    open(file, 'w') { |io| io.write 'CRASHLYTICS_BETA = true' }
    App.config.files << file
    Rake::Task["archive"].invoke

    # Force a link of the executable on the next build by touching the project
    # file since we dont want motion-fabric.rb to be included for a non-beta build.
    FileUtils.touch App.config.project_file

    fabric_setup do |pods_root, api_key, build_secret|
      App.info "Fabric", "Uploading IPA"
      notes_path = File.join(Dir.tmpdir, 'fabric-notes.txt')
      open(notes_path, 'w') { |io| io.write ENV['notes'] }
      system(%Q{#{pods_root}/Crashlytics/submit #{api_key} #{build_secret} -ipaPath "#{App.config.archive}" -notesPath "#{notes_path}"})
    end
  end

  namespace :dsym do
    task :device do
      fabric_run(App.config_without_setup.deploy_platform)
    end

    task :simulator do
      fabric_run(App.config_without_setup.local_platform)
    end
  end
end
