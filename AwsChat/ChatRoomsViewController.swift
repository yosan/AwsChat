//
//  ChatRoomsViewController.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/08/12.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import UIKit

/// List view of chat rooms. User can create, select, delete them.
class ChatRoomsViewController: UITableViewController {

    /// Logined user
    var user: AWSChatUser!
    
    /// User's chat rooms
    var rooms: [AWSChatRoom]?
    
    /// Service for chat rooms
    private let roomsService = ChatRoomsService()
    
    // MARK: - ViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadRooms()
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RoomCell", forIndexPath: indexPath)
        
        if let roomId = rooms?[indexPath.row].RoomId as? String {
            cell.textLabel?.text = roomId
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Delete button is shown by cell swipe.
        if editingStyle == .Delete {
            guard let rooms = rooms else { return }
            deleteChatRoom(rooms[indexPath.row])
        }
    }

    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier where identifier == "EnterRoom" else { fatalError() }
        guard let chatVC = segue.destinationViewController as? ChatViewController else { fatalError() }
        guard let selectedRow = tableView.indexPathForSelectedRow?.row else { fatalError() }
        chatVC.user = user
        chatVC.room = rooms![selectedRow]
    }
    
    /**
     Called when create new room button clicked
     
     - parameter sender: button
     */
    @IBAction func onNewRoomButtonTapped(sender: AnyObject) {
        let alert = getCreateRoomAlert()
        presentViewController(alert, animated: true, completion: nil)
    }
}

// MARK: - Private
private extension ChatRoomsViewController {
    
    /**
     Get chat rooms from server and reload
     */
    func reloadRooms() {
        roomsService.getChatRooms(user) { (rooms, error) in
            guard error == nil else {
                print(error)
                return
            }
            
            self.rooms = rooms
            self.tableView.reloadData()
        }
    }

    /**
     Create UIAlertController to create chat room
     
     - returns: UIAlertController
     */
    func getCreateRoomAlert() -> UIAlertController {
        let alert = UIAlertController(title: "Create Chat Room", message: "Input room ID and Name", preferredStyle: .Alert)
        
        /// User can input "Room ID" and "Room Name". !!!: "Room Name" is not used yet.
        let textFieldNames = [ "Room ID", "Room Name" ]
        textFieldNames.forEach { (textFieldName) in
            alert.addTextFieldWithConfigurationHandler { (textField) in
                textField.placeholder = textFieldName
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Create", style: .Default, handler: { (action) in
            // If create button is cliced, start process of creating chat room.
            if let textFields =  alert.textFields where textFields.count == textFieldNames.count {
                guard let roomId = textFields[0].text, let roomName = textFields[1].text else { fatalError() }
                self.roomsService.createChatRoom(roomId, roomName: roomName, user: self.user, completion: { (room, error) in
                    guard error == nil else { return }
                    self.reloadRooms()
                })
            }
        }))
        
        return alert
    }
    
    /**
     Delete chat room
     
     - parameter room: the room to deleate
     */
    func deleteChatRoom(room: AWSChatRoom) {
        roomsService.deleteChatRoom(room) { (error) in
            self.reloadRooms()
        }
    }
}