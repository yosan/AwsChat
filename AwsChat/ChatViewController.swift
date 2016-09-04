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

/// Chat room view. This view is created by JSQMessagesViewController.
class ChatViewController: JSQMessagesViewController {

    /// Main user
    var user: AWSChatUser! {
        didSet {
            senderId = user.UserId as String
            senderDisplayName = user.UserName as String
        }
    }
    
    /// Room
    var room: AWSChatRoom!

    /// Messages
    private var messages = [AWSChatMessage]()
    
    /// Chatting users
    private var chattingUsers = [AWSChatUser]()
    
    /// Chatting user icons dictionary
    private var iconDictionary = [String : JSQMessagesAvatarImage]()
    
    /// Bubble for not main users
    private var incomingBubble: JSQMessagesBubbleImage!
    
    /// Bubble (plate of messages) for main user
    private var outgoingBuggle: JSQMessagesBubbleImage!
    
    /// Default avator for not main users
    private var incomingAvator: JSQMessagesAvatarImage!
    
    /// Main user's avator
    private var outgoingAvator: JSQMessagesAvatarImage!
    
    /// Service for message
    private let messagesService = ChatMessagesService()
    
    // MARK: - ViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize bubbles
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        incomingBubble = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        outgoingBuggle = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
        
        // Initialize avator
        incomingAvator = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "IncomingAvatar"), diameter: 64)
        
        // Fetch messages from server
        reloadMessages()
        
        // Start observation MessageUpdated event
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.onPushNotificationReceived(_:)), name: "MessageUpdated", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop observation
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - JSQMessagesViewController
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
    
    // MARK: - Event Listener
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
}

// MARK: - Privates
private extension ChatViewController {
    
    /**
     Get new messages and reload view
     */
    func reloadMessages() {
        // TODO: Need mutex
        
        let lastMessageId = messages.last?.MessageId as String?
        
        messagesService.getMessages(room: room, lastMessageId: lastMessageId, completion: { (newMessages, error) in
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
    
    /**
     Get new users' IDs
     
     - parameter messages:   new message
     - parameter knownUsers: already known user
     
     - returns: user IDs
     */
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
    
    /**
     Called when push notification is received
     
     - parameter notification: notification
     */
    @objc
    func onPushNotificationReceived(notification: NSNotification?) {
        reloadMessages()
    }
}
