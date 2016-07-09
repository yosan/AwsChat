//
//  AWChatUser.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/07/23.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import Foundation
import AWSDynamoDB

class AWSChatUser: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var UserId: NSString = ""
    var UserName: NSString = ""
    var ImageUrl: NSString = ""
    var EndpointArn: NSString = ""
    
    static func dynamoDBTableName() -> String {
        return "AWSChatUsers"
    }
    
    static func hashKeyAttribute() -> String {
        return "UserId"
    }
}