# motion-fabric

Easily integrate [Fabric](https://fabric.io) in your [RubyMotion](http://www.rubymotion.com) application.

**Note:** _In Jan 2017, Google acquired Fabric.  Their current [roadmap](https://get.fabric.io/roadmap) indicates that Fabric will go out of service on March 31, 2020.  By that time, developers would need to migrate to [Google's Firebase](https://get.fabric.io/roadmap#meet-firebase) platform._

_Already, support for [3rd party kits](https://docs.fabric.io/apple/third-party-kits.html) for new applications has been removed:_

> _Fabric has deprecated the third party kits as of August 2, 2018. As of this date, you will not be able to onboard new third party kits via Fabric to your apps_

_We continue to mention the kits below for those that might be currently using them._

Supported [Fabric kits](https://fabric.io/kits):

Kit Name | Description | Supported?
---------|-------------|-----------
[Amazon Cognito Sync](https://fabric.io/kits/ios/amazon) | Develop apps quickly. Scale and run reliably. | ✅
[Answers](https://fabric.io/kits/ios/answers) | Finally, mobile app analytics you don't need to analyze. | ✅
[Appsee](https://fabric.io/kits/ios/appsee) | Analyze user behavior with videos of sessions, heatmaps & analytics. | ✅
[Crashlytics](https://fabric.io/kits/ios/crashlytics) | The most powerful, yet lightest weight crash reporting solution. | ✅
[Digits](https://fabric.io/kits/ios/digits) | No more passwords. Powerful login that grows your mobile graph. | ✅
[GameAnalytics](https://fabric.io/kits/ios/gameanalytics) | To build great games, you need to understand player behavior. | ✅
[Mapbox](https://fabric.io/kits/ios/mapbox) | Build the map your application deserves. | ❌
[MoPub](https://fabric.io/kits/ios/mopub) | Drive More Mobile Ad Revenue. | ✅
[Nuance](https://fabric.io/kits/ios/nuance) | Develop natural, engaging experiences with speech | ❌
[Optimizely](https://fabric.io/kits/ios/optimizely) | Fast, powerful A/B testing for mobile apps. | ✅
[PubNub](https://fabric.io/kits/ios/pubnub) | Realtime apps made simple. | ✅
[Stripe](https://fabric.io/kits/ios/stripe) | Seamlessly integrated mobile payments. | ✅
[Twitter](https://fabric.io/kits/ios/twitterkit) | The easiest way to bring Twitter content into your app. | ✅

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
    Fabric.with([Crashlytics])
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
  Fabric.with([Crashlytics])
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

NOTE: Make sure to use an Ad-Hoc provisioning profile and not a developent one.
You can create an Ad-Hoc provisioning profile in the [provisioning portal](https://developer.apple.com/account/ios/certificate/)

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

NOTE: Be careful to include the group *alias* and not the group *name* in the groups option. You can find the group alias in the Fabric dashboard.

Go to the Crashlytics Beta section of your Fabric dashboard and check that your
build was successfully uploaded.

# Other Kits

## Amazon Cognito Sync

[Click here](https://fabric.io/kits/ios/amazon/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
config.kit 'AWSCognitoIdentity' do |info|
  info[:AWSCognitoIdentityPoolId] = 'MyPoolId'
  info[:AWSCognitoIdentityRegionType] = 'MyRegionType'
end

app.pods do
  pod 'AWSCognito'
end
```

And the following to your application code:

```ruby
Fabric.with([AWSCognito])
```
## Answers

The answers SDK is already included in the Crashlytics SDK, so you simply have
to initialize it by adding the following to your application code:

```ruby
Fabric.with([Answers])
```
## Appsee

[Click here](https://fabric.io/kits/ios/appsee/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
config.kit 'Appsee' do |info|
  info[:apikey] = 'MyApiKey'
end

app.pods do
  pod 'Appsee'
end
```

And the following to your application code:

```ruby
Fabric.with([Appsee])
```
## Crashlytics

See the Configuration section above.

## Digits

[Click here](https://fabric.io/kits/ios/digits/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
config.kit 'Digits' do |info|
  info[:consumerKey] = 'MyKey'
  info[:consumerSecret] = 'MySecret'
end

app.pods do
  pod 'Digits'
end
```

And the following to your application code:

```ruby
Fabric.with([Digits])
```
## GameAnalytics

[Click here](https://fabric.io/kits/ios/gameanalytics/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
config.kit 'GameAnalytics' do |info|
  info['api-key'] = 'MyKey'
  info['api-secret'] = 'MySecret'
end

app.pods do
  pod 'GA-SDK-IOS'
end
```

And the following to your application code:

```ruby
Fabric.with([GameAnalytics])
```
## Mapbox

NOTE: The MapBox SDK is not currently supported

[Click here](https://fabric.io/kits/ios/mapbox/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
config.kit 'MGLAccountManager' do |info|
  info[:accessToken] = 'MyToken'
end

app.pods do
  pod 'Mapbox-iOS-SDK'
end
```

And the following to your application code:

```ruby
Fabric.with([MGLAccountManager])
```
## MoPub
Add the following to your `Rakefile`:

```ruby
app.pods do
  pod 'mopub-ios-sdk'
end
```

And the following to your application code:

```ruby
Fabric.with([MoPub])
```
## Nuance

NOTE: The Nuance SDK is not currently supported

[Click here](https://fabric.io/kits/ios/nuance/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
config.kit 'SKSession' do |info|
  info[:appKey] = 'MyKey'
  info[:url] = 'MyURL'
end

app.pods do
  pod 'SpeechKit'
end
```

And the following to your application code:

```ruby
Fabric.with([SKSession])
```
## Optimizely

[Click here](https://fabric.io/kits/ios/optimizely/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
config.kit 'Optimizely' do |info|
  info[:socket_token] = 'MyToken'
end

app.pods do
  pod 'Optimizely-iOS-SDK'
end
```

And the following to your application code:

```ruby
Fabric.with([Optimizely])
Optimizely.startOptimizelyWithAPIToken("{api-key}", launchOptions:launchOptions)
```
## PubNub

[Click here](https://fabric.io/kits/ios/pubnub/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
config.kit 'PubNub' do |info|
  info['publish-key'] = 'MyPublishKey'
  info['subscribe-key'] = 'MySubscribeKey'
  info['secret-key'] = 'MySecretKey'
end

app.pods do
  pod 'PubNub/Fabric'
end
```

And the following to your application code:

```ruby
Fabric.with([PubNub])
```
## Stripe

[Click here](https://fabric.io/kits/ios/stripe/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
config.kit 'STPAPIClient' do |info|
  info[:publishable] = 'MyPublishableAPIKey'
end

app.pods do
  pod 'Stripe'
end
```

And the following to your application code:

```ruby
Fabric.with([STPAPIClient])
```
## Twitter

[Click here](https://fabric.io/kits/ios/twitter/install) to learn how to get your API keys.

Add the following to your `Rakefile`:

```ruby
app.fabric do |config|
  config.kit 'Twitter' do |info|
    info[:consumerKey] = 'MyKey'
    info[:consumerSecret] = 'MySecret'
  end
end

app.pods do
  pod 'TwitterKit'
end
```

And the following to your application code:

```ruby
Fabric.with([Twitter])
```
