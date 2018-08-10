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
    
    
    func chatPartnerId() -> String? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return ""
        }
        
        guard let unWrapedFromId = fromId else {
            return ""
        }
        return (unWrapedFromId == userId ? toId : fromId)!
    }
}
