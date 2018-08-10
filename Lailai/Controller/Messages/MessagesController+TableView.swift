//
//  MessagesController+TableView.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 8/1/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import UIKit
import Firebase

extension MessagesController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else { return }
        
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:AnyObject] else { return }
            
            let user = User()
            user.setValuesForKeys(dictionary)
            user.id = chatPartnerId
            self.showChatControllerForUser(user: user)
            
        }
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! UserCell
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
    }
    
}
