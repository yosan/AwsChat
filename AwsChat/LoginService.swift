//
//  LoginService.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/08/12.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import Foundation
import AWSCognito
import AWSDynamoDB
import AWSSNS

/// Service of login
class LoginService {
    
    /// DynamoDB object mapper
    fileprivate lazy var dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()

    // SNS Platform Apllication Arn
    fileprivate let platformApplicationArn = "arn:aws:sns:<REGION>:<ID>:app/APNS_SANDBOX/AwsChat"
    
    // Cognito Identity Pool ID
    fileprivate let identityPoolId = "<REGION>:<ID>"

    /// Login Provider to pass FB credentials to AWS SDK
    class AWSChatLoginProvider: NSObject, AWSIdentityProviderManager {
        
        fileprivate let token: String?
        
        init(token: String) {
            self.token = token
        }
        
        public func logins() -> AWSTask<NSDictionary> {
            guard let token = token else { fatalError() }
            let providers = [AWSIdentityProviderFacebook : token]
            return AWSTask(result: providers as NSDictionary)
        }
    }
    
    /**
     Login
     
     - parameter token:      FB access token
     - parameter name:       user name
     - parameter imageUrl:   user icon image url
     - parameter completion: callback
     */
    func login(_ token: String, name: String, imageUrl: URL?, deviceToken: String, completion: ((_ user: AWSChatUser?, _ error: Error?) -> Void)?) {
        let providerManager = AWSChatLoginProvider(token: token)
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.apNortheast1,
                                                                identityPoolId:identityPoolId,
                                                                identityProviderManager: providerManager)
        let configuration = AWSServiceConfiguration(region:.apNortheast1, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // Login
        let request = AWSSNSCreatePlatformEndpointInput()
        request?.token = deviceToken
        request?.platformApplicationArn = platformApplicationArn
        
        var dynamoUser: AWSChatUser?
        AWSSNS.default().createPlatformEndpoint(request!)
            .continue(successBlock: { (task: AWSTask!) -> AnyObject! in
                // FIXME: endpointArn unwrapping
                guard let cognitoId = credentialsProvider.identityId, let endpointArn = task.result?.endpointArn! else { fatalError() }
                let user = AWSChatUser()
                user?.UserId = cognitoId as NSString
                user?.UserName = name as NSString
                user?.ImageUrl = imageUrl?.absoluteString as NSString? ?? ""
                user?.EndpointArn = endpointArn as NSString
                dynamoUser = user
                return self.dynamoDBObjectMapper.save(user!)
            })
            .continue(with: AWSExecutor.mainThread(), with: { (task: AWSTask!) -> AnyObject! in
                if let error = task.error {
                    completion?(nil, error)
                } else {
                    completion?(dynamoUser, nil)
                }
                return nil
            })
    }
    
}
