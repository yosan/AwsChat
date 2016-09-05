# AwsChat

### Please input these parameters.

* Info.plit - FacebookAppID
* LoginService.swift - platformApplicationArn
* LoginService.swift - identityPoolId

## DynamoDB Tables

#### Table: AWSChatMessages

##### Item
* RoomId: String
* MessageId: String
* Text: String
* Time: Number
* UserId: String

##### Settings
* Primary partition key: RoomId
* Primary sort key: MessageId

#### Table: AWSChatRooms

##### Item
* RoomId: String
* RoomName: String
* UserId: String

##### Settings
* Primary partition key: RoomId
* Primary sort key: UserId
* Secondary Index: Partition key - UserId, Sort key - RoomId

#### Table: AWSChatUsers

##### Item
* UserId: String
* RoomEndpointArnName: String
* ImageUrl: String
* UserName: String

##### Settings
* Primary partition key: UserId
