# encoding: utf-8

unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

class FabricConfig
  attr_accessor :api_key, :build_secret

  def api_key=(api_key)
    @config.info_plist['Fabric']['APIKey'] = api_key
    @api_key = api_key
  end

  def initialize(config)
    @config = config
    config.info_plist['Fabric'] = {
      'Kits' => [
        {
          'KitInfo' => {},
          'KitName' => 'Crashlytics'
        }
      ]
    }
  end
end

module Motion::Project
  class Config
    variable :fabric

    def fabric(&block)
      @fabric ||= FabricConfig.new(self)
      block.call(@fabric) unless block.nil?
      @fabric
    end
  end
end

Motion::Project::App.setup do |app|
  app.pods do
    pod 'Crashlytics'
    pod 'Fabric'
  end
end

namespace :fabric do
  task :upload do
    pods_root = Motion::Project::CocoaPods::PODS_ROOT
    api_key = App.config.fabric.api_key
    build_secret = App.config.fabric.build_secret

    App.fail "Fabric's api_key cannot be empty" unless api_key
    App.fail "Fabric's build_secret cannot be empty" unless build_secret

    sh "#{pods_root}/Crashlytics/submit #{api_key} #{build_secret} -ipaPath \"#{App.config.archive}\""
  end
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
    PLATFORM_NAME: platform.downcase
  }
  pods_root = Motion::Project::CocoaPods::PODS_ROOT
  env_string = env.map { |k,v| "#{k}='#{v}'" }.join(' ')
  api_key = App.config.fabric.api_key
  build_secret = App.config.fabric.build_secret

  App.fail "Fabric's api_key cannot be empty" unless api_key
  App.fail "Fabric's build_secret cannot be empty" unless build_secret

  App.info "Fabric", "Uploading .dSYM file"
  system("env #{env_string} sh #{pods_root}/Fabric/run #{api_key} #{build_secret}")
end

Rake::Task["build:device"].enhance do
  fabric_run('iPhoneOS')
end

Rake::Task["build:simulator"].enhance do
  fabric_run('iPhoneSimulator')
end
