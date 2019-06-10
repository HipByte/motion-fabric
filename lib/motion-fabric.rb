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
def osx?
  App.template == :osx
end

require 'motion-cocoapods'

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

require 'motion-cocoapods'

Motion::Project::App.setup do |app|
  app.pods do
    use_frameworks!
    pod 'Fabric', '~> 1.10.1'
    pod 'Crashlytics', '~> 3.13.1'
  end

  if osx?
    # staticlly link the frameworks
    app.vendor_project('./vendor/Pods/Fabric/OSX/Fabric.framework', :static, products: ['Fabric'])
    app.vendor_project('./vendor/Pods/Crashlytics/OSX/Crashlytics.framework', :static, products: ['Crashlytics'])

    # make sure they are not copied into the Frameworks folder
    app.embedded_frameworks.delete_if {|item| item.to_s.include?('Fabric.framework')}
    app.embedded_frameworks.delete_if {|item| item.to_s.include?('Crashlytics.framework')}
  else
    # FIXME: TwitterCore and TwitterKit are static ios frameworks, but the .o
    # files inside the archives include the "-framework Fabric" flag in their
    # auto link section information. The linker will look for that framework and
    # fail. As a workaround we include the Fabric framework path as a framework
    # search path. The following warning will be printed, but everything will
    # work fine at runtime:
    # ld: warning: Auto-Linking supplied '/Users/mark/src/motion-fabric/sample_app/vendor/Pods/Fabric/iOS/Fabric.framework/Fabric', framework linker option at /Users/mark/src/motion-fabric/sample_app/vendor/Pods/Fabric/iOS/Fabric.framework/Fabric is not a dylib
    # We will be able to fix this when motion-cocoapods supports the
    # "use_frameworks!" option from Cocoapods.
    app.framework_search_paths << './vendor/Pods/Fabric/iOS'
    app.framework_search_paths << './vendor/Pods/Fabric/tvOS'
    app.framework_search_paths << './vendor/Pods/Fabric/OSX'
  end
end

def fabric_setup(&block)
  pods_root = File.absolute_path(Motion::Project::CocoaPods::PODS_ROOT)
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
    INFOPLIST_PATH: osx? ? 'Contents/Info.plist' : 'Info.plist',
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
  desc 'Create a new app in Fabric'
  task :setup do
    if osx?
      # Build release in case app_name or identifier is overridden for development builds
      Rake::Task["build:release"].execute
    else
      # Build for the simulator so we generate the data needed by the "run" tool
      Rake::Task["build:simulator"].execute
    end
    # Execute the "run" tool so Fabric.app registers our app
    Rake::Task["fabric:dsym:simulator"].execute
    # Do not build again
    ENV["skip_build"] = 'true'
    # Run the app in the simulator so Fabric activates our app
    if osx?
      Rake::Task["run"].execute
    else
      Rake::Task["simulator"].execute
    end
  end

  desc 'Upload a build to Crashlytics'
  task :upload do
    App.config.fabric.beta_block.call if App.config.fabric.beta_block

    # Crashlytics builds do not need this entitlement
    App.config.entitlements['get-task-allow'] = false

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

      args = ""
      args << " -ipaPath \"#{App.config.archive}\""
      args << " -notesPath \"#{notes_path}\""
      args << " -emails \"#{ENV['emails']}\"" if ENV['emails']
      args << " -groupAliases \"#{ENV['groups']}\"" if ENV['groups']
      args << " -notifications \"#{ENV['notifications']}\"" if ENV['notifications']

      sh %Q{#{pods_root}/Crashlytics/submit #{api_key} #{build_secret} #{args}}
    end
  end

  namespace :dsym do
    desc 'Upload the dSYM file for the device executable to Crashlytics'
    task :device do
      fabric_run(App.config_without_setup.deploy_platform)
    end

    desc 'Upload the dSYM file for the simulator executable to Crashlytics'
    task :simulator do
      fabric_run(App.config_without_setup.local_platform)
    end
  end
end
