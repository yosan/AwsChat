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
    private lazy var dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()

    // SNS Platform Apllication Arn
    private let platformApplicationArn = "arn:aws:sns:<REGION>:<ID>:app/APNS_SANDBOX/AwsChat"
    
    // Cognito Identity Pool ID
    private let identityPoolId = "<REGION>:<ID>"

    /// Login Provider to pass FB credentials to AWS SDK
    class AWSChatLoginProvider: NSObject, AWSIdentityProviderManager {
        
        private let token: String?
        
        init(token: String) {
            self.token = token
        }
        
        func logins() -> AWSTask {
            guard let token = token else { fatalError() }
            let providers = [AWSIdentityProviderFacebook : token]
            return AWSTask(result: providers as AnyObject)
        }
    }
    
    /**
     Login
     
     - parameter token:      FB access token
     - parameter name:       user name
     - parameter imageUrl:   user icon image url
     - parameter completion: callback
     */
    func login(token: String, name: String, imageUrl: NSURL?, deviceToken: String, completion: ((user: AWSChatUser?, error: ErrorType?) -> Void)?) {
        let providerManager = AWSChatLoginProvider(token: token)
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.APNortheast1,
                                                                identityPoolId:identityPoolId,
                                                                identityProviderManager: providerManager)
        let configuration = AWSServiceConfiguration(region:.APNortheast1, credentialsProvider:credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        // Login
        let request = AWSSNSCreatePlatformEndpointInput()
        request.token = deviceToken
        request.platformApplicationArn = platformApplicationArn
        
        var dynamoUser: AWSChatUser?
        AWSSNS.defaultSNS().createPlatformEndpoint(request)
            .continueWithSuccessBlock({ (task: AWSTask!) -> AnyObject! in
                // FIXME: endpointArn unwrapping
                guard let cognitoId = credentialsProvider.identityId, let endpointArn = task.result?.endpointArn! else { fatalError() }
                let user = AWSChatUser()
                user.UserId = cognitoId
                user.UserName = name
                user.ImageUrl = imageUrl?.absoluteString ?? ""
                user.EndpointArn = endpointArn
                dynamoUser = user
                return self.dynamoDBObjectMapper.save(user)
            })
            .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
                if let error = task.error {
                    completion?(user: nil, error: error)
                } else {
                    completion?(user: dynamoUser, error: nil)
                }
                return nil
            })
    }
    
}