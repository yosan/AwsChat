//
//  ChatViewController.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/07/09.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import AWSDynamoDB

class ChatViewController: JSQMessagesViewController {

    /// main user
    var user: AWSChatUser!
    
    /// room
    var room: AWSChatRoom!

    /// messages
    private var messages = [AWSChatMessage]()
    
    /// chatting users
    private var chattingUsers = [AWSChatUser]()
    
    /// chatting user icons dictionary
    private var iconDictionary = [String : JSQMessagesAvatarImage]()
    
    private let bubbleFactory = JSQMessagesBubbleImageFactory()
    private var incomingBubble: JSQMessagesBubbleImage!
    private var outgoingBuggle: JSQMessagesBubbleImage!
    private var incomingAvator: JSQMessagesAvatarImage!
    private var outgoingAvator: JSQMessagesAvatarImage!
    
    private let messagesService = ChatMessagesService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderId = user.UserId as String
        senderDisplayName = user.UserName as String
        
        incomingBubble = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        outgoingBuggle = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
        incomingAvator = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "IncomingAvatar"), diameter: 64)
        
        reloadMessages()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.onPushNotificationReceived(_:)), name: "MessageUpdated", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        JSQSystemSoundPlayer.jsq_playMessageSentAlert()
        
        messagesService.sendMessage(text: text, user: user, room: room) { (error) in
            if let error = error {
                print(error)
            }
            self.finishSendingMessageAnimated(true)
            self.reloadMessages()
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        let message = messages[indexPath.row]
        
        guard let user = chattingUsers.filter({$0.UserId == message.UserId}).first else { fatalError() }
        return JSQMessage(senderId: message.UserId as String, displayName: user.UserName as String, text: message.Text as String)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.row]
        if message.UserId == senderId {
            return outgoingBuggle
        } else {
            return incomingBubble
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        if message.UserId == senderId {
            return outgoingAvator
        } else {
            
            if let iconImage = iconDictionary[message.UserId as String] {
                return iconImage
            } else {
                return incomingAvator
            }
        }
    }
}

private extension ChatViewController {
    
    func reloadMessages() {
        // TODO: Need mutex
        
        let lastMessageId = messages.last?.MessageId as String?
        
        messagesService.getMessages(user: user, room: room, lastMessageId: lastMessageId, completion: { (newMessages, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let newMessages = newMessages else { fatalError() }
            self.messages.appendContentsOf(newMessages)
            
            let unknownUserIds = self.getUnknownUserIds(messages: newMessages, knownUsers: self.chattingUsers)
            self.messagesService.getUsers(unknownUserIds, completion: { (unknownUsers, error) in
                guard let unknownUsers = unknownUsers else { return }
                
                self.chattingUsers.appendContentsOf(unknownUsers)
                
                unknownUsers.forEach({ (unknownUser) in
                    if let image = NSURL(string: unknownUser.ImageUrl as String).flatMap({NSData(contentsOfURL: $0)}).flatMap({UIImage(data: $0)}) {
                        self.iconDictionary[unknownUser.UserId as String] = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: 64)
                        
                        if unknownUser.UserId == self.user.UserId {
                            self.outgoingAvator = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: 64)
                        } else {
                            
                        }
                    }
                })
                
                self.finishReceivingMessage()
            })
        })
    }
    
    func getUnknownUserIds(messages messages: [AWSChatMessage], knownUsers: [AWSChatUser]) -> [String] {
        let knownUserIds = knownUsers.map { $0.UserId }
        let unknownUserIds = messages.reduce([]) { (acc, message) -> [String] in
            var acc = acc
            let userId = message.UserId as String
            if !knownUserIds.contains(userId) && !acc.contains(userId) {
                acc.append(message.UserId as String)
            }
            return acc
        }
        return unknownUserIds
    }
    
    @objc
    func onPushNotificationReceived(notification: NSNotification?) {
        reloadMessages()
    }
}
