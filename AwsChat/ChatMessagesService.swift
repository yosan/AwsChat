//
//  ChatMessagesService.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/08/14.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import Foundation
import AWSDynamoDB

/// Service of chat messages
class ChatMessagesService {
    
    /// Object Mapper
    private lazy var dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    
    /**
     Send message
     
     - parameter text:       message text
     - parameter user:       user who wants to send the message
     - parameter room:       room to post message
     - parameter completion: callback
     */
    func sendMessage(text text: String, user: AWSChatUser, room: AWSChatRoom, completion: ((ErrorType?) -> Void)?) {
        
        let dynamoMessage = AWSChatMessage()
        let date = NSDate()
        let messageId = Int(date.timeIntervalSince1970 * 1000)
        dynamoMessage.MessageId = "\(messageId)"
        dynamoMessage.RoomId = room.RoomId
        dynamoMessage.UserId = user.UserId
        dynamoMessage.Text = text
        dynamoMessage.Time = date.timeIntervalSince1970
        dynamoDBObjectMapper.save(dynamoMessage)
            .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {(task) -> AnyObject? in
                if let error = task.error {
                    print(error)
                    completion?(error)
                }
                if let exception = task.exception {
                    print(exception)
                }
                if let _ = task.result {
                    print("succeeded!")
                }
                completion?(nil)
                return nil
            })
    }
    
    /**
     Get message
     
     - parameter room:          room in which message exits
     - parameter lastMessageId: last message ID which the app already known. If it's nil, latest 10 messages are fetched.
     - parameter completion:    callback
     */
    func getMessages(room room: AWSChatRoom, lastMessageId: String?, completion: (([AWSChatMessage]?, ErrorType?) -> Void)?) {
        let query = AWSDynamoDBQueryExpression()
        
        query.keyConditionExpression = "RoomId = :roomId and MessageId > :messageId"
        
        let lastMessageId: String = lastMessageId ?? "0"
        query.expressionAttributeValues = [":roomId" : room.RoomId, ":messageId" : lastMessageId]
        query.limit = 10
        query.scanIndexForward = false
        
        dynamoDBObjectMapper.query(AWSChatMessage.self, expression: query)
            .continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { task -> AnyObject! in
                if let error = task.error {
                    completion?(nil, error)
                    return nil
                }
                
                guard
                    let paginatedOutput = task.result as? AWSDynamoDBPaginatedOutput,
                    let messages = paginatedOutput.items as? [AWSChatMessage] else { fatalError() }
                
                // Reverse messages
                completion?(messages.reverse(), nil)
                return nil
            })
    }
    
    /**
     Get user data
     
     - parameter userIds:    user IDs to get data
     - parameter completion: callback
     */
    func getUsers(userIds: [String], completion: (([AWSChatUser]?, ErrorType?) -> Void)?) {
        let tasks = userIds.map { userId -> AWSTask in
            return dynamoDBObjectMapper.load(AWSChatUser.self, hashKey: userId, rangeKey: nil)
        }
        AWSTask(forCompletionOfAllTasksWithResults: tasks).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            if let error = task.error {
                completion?(nil, error)
                return nil
            }
            
            guard let users = task.result as? [AWSChatUser] else { fatalError() }
            completion?(users, nil)
            return nil
        })
    }
}
