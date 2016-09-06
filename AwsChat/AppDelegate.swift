//
//  AppDelegate.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/07/09.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import UIKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }
    
    /**
     Called when user allows push notification
     
     - parameter application:          application
     - parameter notificationSettings: notificationSettings
     */
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    /**
     Called when device token is provided
     
     - parameter application: application
     - parameter deviceToken: deviceToken
     */
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let deviceTokenString = "\(deviceToken)"
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString:"<>"))
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        let notification = NSNotification(name: "DeviceTokenUpdated", object: self, userInfo: ["token" : deviceTokenString])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    /**
     Called when token registration is failed
     
     - parameter application: application
     - parameter error:       error
     */
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("error: \(error.code), \(error.description)")
        
        // Simulate device token is received for iOS Simulator.
        if TARGET_OS_SIMULATOR != 0 {
            let dummy = "0000000000000000000000000000000000000000000000000000000000000000"
            let notification = NSNotification(name: "DeviceTokenUpdated", object: self, userInfo: ["token" : dummy])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
    /**
     Called when remote notification is received. (DynamoDB's message table is updated in this case)
     
     - parameter application: application
     - parameter userInfo:    userInfo
     */
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print(userInfo)
        let notification = NSNotification(name: "MessageUpdated", object: self, userInfo: userInfo)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }

    /**
     Call FBSDKAppEvents.activateApp() for Facebool login.
     
     - parameter application: application
     */
    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }

    /**
     Call FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) for Facebook login.
     
     - parameter application:       application
     - parameter url:               url
     - parameter sourceApplication: sourceApplication
     - parameter annotation:        annotation
     
     - returns: return value
     */
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

}

