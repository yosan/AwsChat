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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    /**
     Called when user allows push notification
     
     - parameter application:          application
     - parameter notificationSettings: notificationSettings
     */
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    /**
     Called when device token is provided
     
     - parameter application: application
     - parameter deviceToken: deviceToken
     */
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = "\(deviceToken)"
            .trimmingCharacters(in: CharacterSet(charactersIn:"<>"))
            .replacingOccurrences(of: " ", with: "")
        let notification = Notification(name: Notification.Name(rawValue: "DeviceTokenUpdated"), object: self, userInfo: ["token" : deviceTokenString])
        NotificationCenter.default.post(notification)
    }
    
    /**
     Called when token registration is failed
     
     - parameter application: application
     - parameter error:       error
     */
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        let error = error as NSError
        print("error: \(error.code), \(error.description)")
        
        // Simulate device token is received for iOS Simulator.
        if TARGET_OS_SIMULATOR != 0 {
            let dummy = "0000000000000000000000000000000000000000000000000000000000000000"
            let notification = Notification(name: Notification.Name(rawValue: "DeviceTokenUpdated"), object: self, userInfo: ["token" : dummy])
            NotificationCenter.default.post(notification)
        }
    }
    
    /**
     Called when remote notification is received. (DynamoDB's message table is updated in this case)
     
     - parameter application: application
     - parameter userInfo:    userInfo
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print(userInfo)
        let notification = Notification(name: Notification.Name(rawValue: "MessageUpdated"), object: self, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }

    /**
     Call FBSDKAppEvents.activateApp() for Facebool login.
     
     - parameter application: application
     */
    func applicationDidBecomeActive(_ application: UIApplication) {
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
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

}

