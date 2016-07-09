//
//  AWSChatMessage.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/07/10.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import Foundation
import AWSDynamoDB

class AWSChatMessage: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var MessageId: NSString = ""
    var RoomId: NSString = ""
    var UserId: NSString = ""
    var Text: NSString = ""
    var Time: NSNumber = 0
    
    static func dynamoDBTableName() -> String {
        return "AWSChatMessages"
    }
    
    static func hashKeyAttribute() -> String {
        return "RoomId"
    }
    
    static func rangeKeyAttribute() -> String {
        return "MessageId"
    }

}