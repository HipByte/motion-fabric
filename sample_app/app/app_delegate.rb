class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    rootViewController = UIViewController.alloc.init
    rootViewController.title = 'example'
    rootViewController.view.backgroundColor = UIColor.whiteColor

    navigationController = UINavigationController.alloc.initWithRootViewController(rootViewController)

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = navigationController
    @window.makeKeyAndVisible

    Fabric.with([
      Crashlytics,
      AWSCognito,
      Answers,
      Appsee,
      Digits,
      GameAnalytics,
      MoPub,
      Optimizely,
      PubNub,
      STPAPIClient,
      Twitter,
    ])

    true
  end
end
