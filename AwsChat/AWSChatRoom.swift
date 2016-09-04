//
//  AWSChatRoom.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/08/12.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import Foundation
import AWSDynamoDB

/// DynamoDB Object for AWSChatRooms
class AWSChatRoom: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var RoomId: NSString = ""
    var RoomName: NSString = ""
    var UserId: NSString = ""
    
    static func dynamoDBTableName() -> String {
        return "AWSChatRooms"
    }
    
    static func hashKeyAttribute() -> String {
        return "RoomId"
    }
    
    static func rangeKeyAttribute() -> String {
        return "UserId"
    }
}