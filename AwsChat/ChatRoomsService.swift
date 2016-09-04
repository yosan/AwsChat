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
    private lazy var dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    
    /**
     Get chatrooms which user is entering.
     
     - parameter user:       user
     - parameter completion: callback
     */
    func getChatRooms(user: AWSChatUser, completion: (([AWSChatRoom]?, ErrorType?) -> Void)?) {
        let query = AWSDynamoDBQueryExpression()
        query.indexName = "UserId-RoomId-index"
        query.keyConditionExpression = "UserId = :val"
        query.expressionAttributeValues = [":val" : user.UserId]
        dynamoDBObjectMapper.query(AWSChatRoom.self, expression: query)
            .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { task -> AnyObject! in
                if let error = task.error {
                    completion?(nil, error)
                    return nil
                }
                
                guard
                    let paginatedOutput = task.result as? AWSDynamoDBPaginatedOutput,
                    let rooms = paginatedOutput.items as? [AWSChatRoom] else { fatalError() }
                
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
    func createChatRoom(roomId: String, roomName: String, user: AWSChatUser, completion: ((AWSChatRoom?, ErrorType?) -> Void)?) {
        let dynamoRoom = AWSChatRoom()
        dynamoRoom.RoomId = roomId
        dynamoRoom.RoomName = roomName
        dynamoRoom.UserId = user.UserId
        dynamoDBObjectMapper.save(dynamoRoom)
            .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject! in
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
    func deleteChatRoom(room: AWSChatRoom, completion: ((ErrorType?) -> Void)?) {
        dynamoDBObjectMapper.remove(room)
            .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject! in
                completion?(task.error)
                return nil
            })
    }
}
