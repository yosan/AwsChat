//
//  ChatRoomsService.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/08/12.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import Foundation
import AWSDynamoDB

/// Service of chat rooms
class ChatRoomsService {
    
    /// Object Mapper
    fileprivate lazy var dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
    
    /**
     Get chatrooms which user is entering.
     
     - parameter user:       user
     - parameter completion: callback
     */
    func getChatRooms(_ user: AWSChatUser, completion: (([AWSChatRoom]?, Error?) -> Void)?) {
        let query = AWSDynamoDBQueryExpression()
        query.indexName = "UserId-RoomId-index"
        query.keyConditionExpression = "UserId = :val"
        query.expressionAttributeValues = [":val" : user.UserId]
        dynamoDBObjectMapper.query(AWSChatRoom.self, expression: query)
            .continue(with: AWSExecutor.mainThread(), with: { task -> AnyObject! in
                if let error = task.error {
                    completion?(nil, error)
                    return nil
                }
                
                guard let rooms = task.result?.items as? [AWSChatRoom] else { fatalError() }
                
                completion?(rooms, nil)
                return nil
            })
    }
    
    /**
     Create or enter new chat room.
     
     - parameter roomId:     room ID
     - parameter roomName:   room Name (Not used yet)
     - parameter user:       user who want to enter the room
     - parameter completion: callback
     */
    func createChatRoom(_ roomId: String, roomName: String, user: AWSChatUser, completion: ((AWSChatRoom?, Error?) -> Void)?) {
        let dynamoRoom = AWSChatRoom()
        dynamoRoom?.RoomId = roomId as NSString
        dynamoRoom?.RoomName = roomName as NSString
        dynamoRoom?.UserId = user.UserId
        dynamoDBObjectMapper.save(dynamoRoom!)
            .continue(with: AWSExecutor.mainThread(), with: { (task) -> AnyObject! in
                if let error = task.error {
                    completion?(nil, error)
                    return nil
                }
                
                completion?(dynamoRoom, nil)
                return nil
            })
    }
    
    /**
     Go out from chat room.
     
     - parameter room:       room which uer want to go out
     - parameter completion: callback
     */
    func deleteChatRoom(_ room: AWSChatRoom, completion: ((Error?) -> Void)?) {
        dynamoDBObjectMapper.remove(room)
            .continue(with: AWSExecutor.mainThread(), with: { (task) -> AnyObject! in
                completion?(task.error)
                return nil
            })
    }
}
