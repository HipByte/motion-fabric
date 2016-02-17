# motion-fabric

Easily integrate [Fabric](https://fabric.io) in your [RubyMotion](http://www.rubymotion.com) application.

[Fabric kits](https://fabric.io/kits) supported right now:

- Crashlytics: Crash reporting

## Installation

Add this line to your application's Gemfile:

    gem 'motion-fabric'

And then execute:

    $ bundle
    
To install the required Pods execute:

    $ rake pod:install
    
## Configuration

1. Sign up for a Fabric account [here](https://fabric.io/sign_up)
2. You will receive a confirmation email. Enter your team's name and download the Xcode plugin (Dont worry, this is a separate app called Fabric.app. You wont need to open Xcode).
3. Open Fabric.app and log in with your account (Important! You must keep Fabric.app open and logged in throughout the configuration process).
4. Go to [this page](https://fabric.io/kits/ios/crashlytics/install) and retrieve your Api Key and Build Secret for your organization in the step two. They will appear in a box in this form:

    ```bash
    "${PODS_ROOT}/Fabric/run" {api_key} {build_secret}
    ```
5. Configure your `Rakefile` with the Api Key and Build Secret:

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

Usually, you only want crash reporting for your distribution builds:

```ruby
Fabric.with([Crashlytics.sharedInstance]) if RUBYMOTION_ENV == 'release'
```

To upload the `dSYM` automatically after `rake archive:distribution`, add the following to your `Rakefile`:

```ruby
Rake::Task["archive:distribution"].enhance do
  Rake::Task["fabric:dsym:device"].execute
end
```
