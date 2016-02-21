//
//  AppDelegate.swift
//  Crowdshipping
//
//  Created by Peter Prokop on 13/02/15.
//  Copyright (c) 2015 Whitescape. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var sideMenu: MMDrawerController?
    var leftMenu: SideMenuViewController!
    var welcome: WelcomeViewController!
    internal var mainMapNavigation: UINavigationController!
    var splashScreen : UIImageView!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Fabric.with([Crashlytics()])
        GMSServices.provideAPIKey(Config.Keys.googleAPIs)
        
        // All intercom logic is in AuthManager
//        Intercom.setApiKey(Config.Keys.intercomAPIKey, forAppId: Config.Keys.intercomAppID)
        
        // Google analytics
        GAI.sharedInstance().trackUncaughtExceptions = true;
        GAI.sharedInstance().trackerWithTrackingId(Config.Keys.googleAnalyticsKey)
        
        // Styles
        //UINavigationBar.appearance().setBackgroundImage(UIImage(named: "Navbar")!, forBarMetrics: .Default)
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: false)
        UINavigationBar.appearance().tintColor = Utils.Color(95, 95, 95)
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: Config.Visuals.color_grayText]
        
        
        var backImage = UIImage(named: "BackButtonNav")
        backImage = backImage?.imageWithRenderingMode(.AlwaysOriginal)
        
        
        UINavigationBar.appearance().backIndicatorImage = backImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImage
        
        leftMenu = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SideMenuController") as! SideMenuViewController
        
        mainMapNavigation = self.window?.rootViewController as! UINavigationController
        sideMenu = MMDrawerController(centerViewController: self.window?.rootViewController, leftDrawerViewController: leftMenu) as MMDrawerController
        sideMenu?.openDrawerGestureModeMask = MMOpenDrawerGestureMode.All
        sideMenu?.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.All
        
        self.window?.rootViewController = sideMenu
        self.window?.makeKeyAndVisible()
        
        leftMenu!.drawerController = sideMenu
        
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: 0,vertical: -60), forBarMetrics: .Default);

        self.showSplashScreen()
        
        return true
    }
    
    internal func resetNavigationStack()
    {
        sideMenu?.centerViewController = mainMapNavigation
    }
    
    func showSplashScreen()
    {
        self.splashScreen = UIImageView(image: UIImage(named: "Background"))
//        self.splashScreen.contentMode = UIViewContentMode.ScaleAspectFit
        self.splashScreen.frame = UIScreen.mainScreen().bounds
        sideMenu?.view.addSubview(self.splashScreen)
    }
    
    internal func hideSplasScreen(delay: NSTimeInterval)
    {
        UIView.animateWithDuration(0.6, delay: delay, options: .TransitionNone, animations: { () -> Void in
            self.splashScreen.alpha = 0.0
            }) { (arg) -> Void in
                self.splashScreen.removeFromSuperview()
        }
    }
    
    internal func showWelcome(completion: () -> Void)
    {
        // MARK: Temp solution
        completion()
        return
        
        self.welcome = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("WelcomeViewController") as! WelcomeViewController
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        self.welcome.view.alpha = 0.0
        self.welcome.view.frame = CGRectMake(0.0, 0.0, screenSize.width, screenSize.height)
        self.window?.addSubview(self.welcome.view)
        
        self.welcome.continueButton.addTarget(self, action:Selector("hideWelcome"), forControlEvents:.TouchUpInside)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.welcome.view.alpha = 1.0
            }, completion: { (finished) -> Void in
                completion()
        })
    }
    
    func hideWelcome()
    {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
             self.welcome.view.alpha = 0.0
            }, completion: { (finished) -> Void in
                self.welcome.view.removeFromSuperview()
        })

    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        OrderManager.sharedInstance.appDidClosed()
        self.saveContext()
    }

    // MARK: - APNS
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        APNSManager.sharedInstance.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        APNSManager.sharedInstance.didFailToRegisterForRemoteNotificationsWithError(error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        APNSManager.sharedInstance.handleIncomingNotification(userInfo)
    }
    
    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "Whitescape.Crowdshipping" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Crowdshipping", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Crowdshipping.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as! NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}
