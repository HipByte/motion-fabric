# motion-fabric

Easily integrate [Fabric](https://fabric.io) in your [RubyMotion](http://www.rubymotion.com) application.

Supported [Fabric kits](https://fabric.io/kits):

- Crashlytics: Crash reporting.

## Installation

Add this line to your application's Gemfile:

    gem 'motion-fabric'

And then execute:

    $ bundle
    
To install the required Pods execute:

    $ rake pod:install
    
## Configuration

NOTE: If you already have a Fabric team with an API KEY and BUILD SECRET, skip to step 5.

1. Sign up for a Fabric account [here](https://fabric.io/sign_up)
2. You will receive a confirmation email. Enter your team's name and download the Xcode plugin (Dont worry, this is a separate app called Fabric.app. You wont need to open Xcode).
3. Open Fabric.app and log in with your account (Important! You must keep Fabric.app open and logged in throughout the configuration process).
4. Go to [this page](https://fabric.io/kits/ios/crashlytics/install) and retrieve your API KEY and BUILD SECRET for your organization in the step two. They will appear in a box in this form:

    ```bash
    "${PODS_ROOT}/Fabric/run" {api_key} {build_secret}
    ```
5. Configure your `Rakefile` with the API KEY and BUILD SECRET:

    ```ruby
    app.fabric do |config|
      config.api_key = "api_key"
      config.build_secret = "build_secret"
      config.kit 'Crashlytics'
    end
    ```
6. Add the following line in your AppDelegate:

    ```ruby
    Fabric.with([Crashlytics.sharedInstance])
    ``` 
7. Register your app with Fabric (this will run your app in the simulator):

    ```
    $ rake fabric:setup
    ```
8. Go to [fabric.io](https://fabric.io) and verify that your app has been created


## Crash reporting

To process your crash reports, Crashlytics needs a special file that contains the debug information of your app. This is needed to add method name, file name and line number annotations to the crash reports.

This file is called the `dSYM` file and is generated every time you build the application.

By default `motion-fabric` does NOT upload any `dSYM` file.

Usually, you only want crash reporting for your distribution and Crashlytics 
Beta builds:

```ruby
if RUBYMOTION_ENV == 'release' || CRASHLYTICS_BETA == true
  Fabric.with([Crashlytics.sharedInstance]) 
end
```

You can automate the upload of the dSYM file after you run certain rake commands:

```ruby
# Upload the dSYM after creating a release build
Rake::Task["archive:distribution"].enhance do
  Rake::Task["fabric:dsym:device"].invoke
end

# Upload the dSYM after every simulator build
Rake::Task["build:simulator"].enhance do
  Rake::Task["fabric:dsym:simulator"].invoke
end

# Upload the dSYM after every device build
Rake::Task["build:device"].enhance do
  Rake::Task["fabric:dsym:device"].invoke
end

# Upload the dSYM after uploading a beta build to Crashlytics
Rake::Task["fabric:upload"].enhance do
  Rake::Task["fabric:dsym:device"].invoke
end
```

## Beta distribution

Fabric offers another service under the name Crashlytics Beta which helps you
distribute beta builds of your app to your testers.

You can customize the configuration for your beta distribution. You should use
this to configure your AdHoc provisioninig profile.

```ruby
app.fabric do |config|
  config.beta do
    app.identifier = "my_identifier"
    app.codesign_certificate = "my_certificate"
    app.provisioning_profile = "my_ad_hoc_provisioning_file"
  end
end
```

The only difference between your development builds and your Crashlytics Beta
builds is the presence of the `CRASHLYTICS_BETA` constant which is only present
for beta builds:

```ruby
if Module.const_defined?(:CRASHLYTICS_BETA)
  puts 'This code will only run in builds distributed via Crashlytics Beta'
end
```

To create a beta build and upload it to Crashlytics Beta:

```bash
$ rake fabric:upload notes="my release notes" emails="foo@example.com,bar@example.com" groups="group1,group2" notifications=YES
```

The notes, emails, groups and notifications options are optional.

Go to the Crashlytics Beta section of your Fabric dashboard and check that your
build was successfully uploaded.
