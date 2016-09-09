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
    fileprivate var deviceToken: String?
    
    /// Service for login
    fileprivate let loginService = LoginService()
    
    /// Container to show icon.
    @IBOutlet weak var iconContainer: UIView!
    
    /// Start chat button. This button is enabled when user logins.
    @IBOutlet weak var startButton: UIButton!
    
    /// Login Provider to pass FB credentials to AWS SDK.
    class AWSChatLoginProvider: NSObject, AWSIdentityProviderManager {
        /**
         Each entry in logins represents a single login with an identity provider. The key is the domain of the login provider (e.g. 'graph.facebook.com') and the value is the OAuth/OpenId Connect token that results from an authentication with that login provider.
         */
        public func logins() -> AWSTask<NSDictionary> {
            var providers = [String : String]()
            if let fbtoken =  FBSDKAccessToken.current() {
                providers[AWSIdentityProviderFacebook] = fbtoken.tokenString
            }
            return AWSTask<NSDictionary>(result: providers as NSDictionary)
        }
    }
        
    /// User
    fileprivate var user: AWSChatUser?
    
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
        
        startButton.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.onDeviceTokenUpdated(_:)), name: NSNotification.Name(rawValue: "DeviceTokenUpdated"), object: nil)
        
        // Confirm notification permission
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound,], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
    }
    
    /**
     This function is called when login process completed.
     
     - parameter loginButton: button
     - parameter result:      result
     - parameter error:       error
     */
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        login(deviceToken)
    }
    
    /**
     Move to chat rooms view controller.
     
     - parameter sender: sender
     */
    @IBAction func onStartButtonClicked(_ sender: AnyObject) {
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    
    /**
     Called when user logouts.
     
     - parameter loginButton: button
     */
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        DispatchQueue.main.async(execute: {
            self.startButton.isEnabled = false
        })
    }
    
    /**
     Segue
     
     - parameter segue:  segue
     - parameter sender: sender
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier , identifier == segueIdentifier else { return }
        guard let chatRoomsVC = segue.destination as? ChatRoomsViewController else { return }
        guard let user = user else { return }
        chatRoomsVC.user = user
    }
    
    /**
     Called when device token is updated.
     
     - parameter notification: notification
     */
    @objc
    func onDeviceTokenUpdated(_ notification: Notification?) {
        guard let userInfo = (notification as NSNotification?)?.userInfo else { return }
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
    func login(_ deviceToken: String?) {
        // Chack facebook token and device token.
        guard let fbtoken =  FBSDKAccessToken.current(), let deviceToken = self.deviceToken else { return }
        
        // Get icon URL and start login process.
        FBSDKProfile.loadCurrentProfile { (profile, error) in
            guard let name = profile?.name, error == nil else {
                print(error)
                return
            }
            
            let imageUrl = profile?.imageURL(for: FBSDKProfilePictureMode.square, size: CGSize(width: 64, height: 64))
            self.loginService.login(fbtoken.tokenString, name: name, imageUrl: imageUrl, deviceToken: deviceToken) { (user, error) in
                self.user = user
                self.startButton.isEnabled = true
            }
        }
    }
    
}
