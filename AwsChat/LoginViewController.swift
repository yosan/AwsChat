//
//  LoginViewController.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/07/09.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import AWSCognito
import AWSDynamoDB

/**
 Login View

 * Handle Facebook login.
 * Handle Cognito login.
 * Pass CognitoID to next view controller.
 */
class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
   
    /// Segue Identifier
    let segueIdentifier = "ChatRooms"
    
    /// Device Token
    private var deviceToken: String?
    
    /// Service for login
    private let loginService = LoginService()
    
    /// Container to show icon.
    @IBOutlet weak var iconContainer: UIView!
    
    /// Start chat button. This button is enabled when user logins.
    @IBOutlet weak var startButton: UIButton!
    
    /// Login Provider to pass FB credentials to AWS SDK.
    class AWSChatLoginProvider: NSObject, AWSIdentityProviderManager {
        func logins() -> AWSTask {
            var providers = [String : String]()
            if let fbtoken =  FBSDKAccessToken.currentAccessToken() {
                providers[AWSIdentityProviderFacebook] = fbtoken.tokenString
            }
            return AWSTask(result: providers as AnyObject)
        }
    }
        
    /// User
    private var user: AWSChatUser?
    
    // MARK: - ViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loginButton = FBSDKLoginButton()
        loginButton.center = view.center
        loginButton.readPermissions = ["public_profile"]
        loginButton.delegate = self
        view.addSubview(loginButton)
        
        let pictureFrame = CGRect(x: 0, y: 0, width: iconContainer.frame.width, height: iconContainer.frame.height)
        let pictureView = FBSDKProfilePictureView(frame: pictureFrame)
        iconContainer.addSubview(pictureView)
        
        startButton.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.onDeviceTokenUpdated(_:)), name: "DeviceTokenUpdated", object: nil)
        
        // Confirm notification permission
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound,], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    /**
     This function is called when login process completed.
     
     - parameter loginButton: button
     - parameter result:      result
     - parameter error:       error
     */
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        login(deviceToken)
    }
    
    /**
     Move to chat rooms view controller.
     
     - parameter sender: sender
     */
    @IBAction func onStartButtonClicked(sender: AnyObject) {
        performSegueWithIdentifier(segueIdentifier, sender: self)
    }
    
    /**
     Called when user logouts.
     
     - parameter loginButton: button
     */
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        dispatch_async(dispatch_get_main_queue(), {
            self.startButton.enabled = false
        })
    }
    
    /**
     Segue
     
     - parameter segue:  segue
     - parameter sender: sender
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier where identifier == segueIdentifier else { return }
        guard let chatRoomsVC = segue.destinationViewController as? ChatRoomsViewController else { return }
        guard let user = user else { return }
        chatRoomsVC.user = user
    }
    
    /**
     Called when device token is updated.
     
     - parameter notification: notification
     */
    @objc
    func onDeviceTokenUpdated(notification: NSNotification?) {
        guard let userInfo = notification?.userInfo else { return }
        if let deviceToken = userInfo["token"] as? String {
            self.deviceToken = deviceToken
        }
        login(self.deviceToken)
    }
}

// MARK: - Private
private extension LoginViewController {
    
    /**
     Try to login.
     
     Login process is started when facebook token and device token is received.
     After login process is end, "Start" button is enabled.
     
     - parameter deviceToken: deviceToken
     */
    func login(deviceToken: String?) {
        // Chack facebook token and device token.
        guard
            let fbtoken =  FBSDKAccessToken.currentAccessToken(),
            let deviceToken = self.deviceToken else { return }
        
        // Get icon URL and start login process.
        FBSDKProfile.loadCurrentProfileWithCompletion { (profile, error) in
            guard error == nil else {
                print(error)
                return
            }
            
            let imageUrl = profile.imageURLForPictureMode(FBSDKProfilePictureMode.Square, size: CGSize(width: 64, height: 64))
            self.loginService.login(fbtoken.tokenString, name: profile.name, imageUrl: imageUrl, deviceToken: deviceToken) { (user, error) in
                self.user = user
                self.startButton.enabled = true
            }
        }
    }
    
}