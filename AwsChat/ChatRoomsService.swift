//
//  ChatRoomsService.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/08/12.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import Foundation
import AWSDynamoDB

class ChatRoomsService {
    
    private lazy var dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    
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
    
    func deleteChatRoom(room: AWSChatRoom, completion: ((ErrorType?) -> Void)?) {
        dynamoDBObjectMapper.remove(room)
            .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject! in
                completion?(task.error)
                return nil
            })
    }
}
