//
//  ChatRoomsViewController.swift
//  AwsChat
//
//  Created by Takahashi Yosuke on 2016/08/12.
//  Copyright © 2016年 Yosan. All rights reserved.
//

import UIKit

class ChatRoomsViewController: UITableViewController {

    var user: AWSChatUser!
    
    var rooms: [AWSChatRoom]?
    
    private let roomsService = ChatRoomsService()
    
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
        if editingStyle == .Delete {
            guard let rooms = rooms else { return }
            deleteChatRoom(rooms[indexPath.row])
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier where identifier == "EnterRoom" else { fatalError() }
        guard let chatVC = segue.destinationViewController as? ChatViewController else { fatalError() }
        guard let selectedRow = tableView.indexPathForSelectedRow?.row else { fatalError() }
        chatVC.user = user
        chatVC.room = rooms![selectedRow]
    }
    
    @IBAction func onNewRoomButtonTapped(sender: AnyObject) {
        let alert = getCreateRoomAlert()
        presentViewController(alert, animated: true, completion: nil)
    }
}

private extension ChatRoomsViewController {
    
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

    func getCreateRoomAlert() -> UIAlertController {
        let alert = UIAlertController(title: "Create Chat Room", message: "Input room ID and Name", preferredStyle: .Alert)
        
        let textFieldNames = [ "Room ID", "Room Name" ]
        textFieldNames.forEach { (textFieldName) in
            alert.addTextFieldWithConfigurationHandler { (textField) in
                textField.placeholder = textFieldName
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Create", style: .Default, handler: { (action) in
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
    
    func deleteChatRoom(room: AWSChatRoom) {
        roomsService.deleteChatRoom(room) { (error) in
            self.reloadRooms()
        }
    }
}