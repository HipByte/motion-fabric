class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    rootViewController = UIViewController.alloc.init
    rootViewController.title = 'example'
    rootViewController.view.backgroundColor = UIColor.whiteColor

    navigationController = UINavigationController.alloc.initWithRootViewController(rootViewController)

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = navigationController
    @window.makeKeyAndVisible

    Fabric.with([Crashlytics])
    Fabric.with([AWSCognito])
    Fabric.with([Answers])
    Fabric.with([Appsee])
    Fabric.with([Digits])
    Fabric.with([GameAnalytics])
    Fabric.with([MoPub])
    Fabric.with([Optimizely])
    Optimizely.startOptimizelyWithAPIToken("{api-key}", launchOptions:launchOptions)
    Fabric.with([PubNub])
    Fabric.with([STPAPIClient])
    Fabric.with([Twitter])

    true
  end
end
