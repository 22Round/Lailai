//
//  Message.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 7/31/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import Foundation
import Firebase

class Message:NSObject {
    
    @objc var fromId:String?
    @objc var text: String?
    @objc var timestamp:NSNumber?
    @objc var toId:String?
    
    @objc var imageUrl:String?
    @objc var imageHeight:NSNumber?
    @objc var imageWidth:NSNumber?
    
    
    func chatPartnerId() -> String? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return ""
        }
        
        guard let unWrapedFromId = fromId else {
            return ""
        }
        return (unWrapedFromId == userId ? toId : fromId)!
    }
    
    init(dictionary: [String:AnyObject]) {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        toId = dictionary["toId"] as? String
        
        imageUrl = dictionary["imageUrl"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        
    }
}
