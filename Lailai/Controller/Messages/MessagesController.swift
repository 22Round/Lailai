//
//  MessagesController.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 7/11/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {
    
    //MARK: - Vars
    
    var ref:DatabaseReference?
    var messages = [Message] ()
    var messagesDictionary = [String:Message]()
    var timer:Timer?
    
    //MARK: - Constantas
    
    let cellId:String = "cellID"
    
    //MARK: - Code LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        checkIfUserIsLoggedIn()
//        observeMessages()
//        observeUserMessages()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Methods
    
    //MARK: Handlers
    
    @objc fileprivate func handleLogout(){
        
        do {
            try Auth.auth().signOut()
        }catch let sighOutErr {
            print("Sign Out Error:", sighOutErr)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true)
    }
    
    @objc fileprivate func handleNewMessage() {
        
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            guard let m1 = message1.timestamp?.intValue, let m2 = message2.timestamp?.intValue else { return false }
            return m1 > m2
        })
        
        let newMessageController = NewMessageViewController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        self.present(navController, animated: true)
        
    }
    
    //MARK: functions
    
    fileprivate func observeUserMessages(){
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("user-messages").child(uid)
        
        ref.observe(.childAdded) { (snapshot) in
            
            let userId = snapshot.key
            
            Database.database().reference().child("user-messages").child(uid).child(userId).queryLimited(toLast: 1).observeSingleEvent(of: .childAdded, with: { (snapShot) in
                let messageId = snapShot.key
                self.fetchMessageWith(messageId: messageId)
            })
        }
    }
    
    fileprivate func fetchMessageWith(messageId:String) {
        let messagesRef = Database.database().reference().child("messages").child(messageId)
        
        messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String:AnyObject] {
                
                let message = Message(dictionary: dictionary)
//                message.setValuesForKeys(dictionary)
                self.messages.append(message)
                
                if let chatPartnerId = message.chatPartnerId() {
                    self.messagesDictionary[chatPartnerId] = message
                }
                self.attemtReloadOfTable()
            }
        })
    }
    
    fileprivate func attemtReloadOfTable(){
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (timer) in
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
    /*
    fileprivate func observeMessages() {
        let ref = Database.database().reference().child("messages")
        ref.observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String:Any] {
                
                let message = Message()
                message.setValuesForKeys(dictionary)
                self.messages.append(message)
                
                if let toId = message.toId {
                    self.messagesDictionary[toId] = message
                    self.messages = Array(self.messagesDictionary.values)
                    self.messages.sort(by: { (message1, message2) -> Bool in
                        guard let m1 = message1.timestamp?.intValue, let m2 = message2.timestamp?.intValue else { return false }
                        return m1 > m2
                    })
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
 */
    
    fileprivate func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionary = snapshot.value as? [String:AnyObject] {
                self.navigationItem.title = dictionary["name"] as? String
                
                let user = User()
                user.setValuesForKeys(dictionary)
                self.setupNavBarWithUser(user: user)
            }
        }
    }
    
    func setupNavBarWithUser(user:User) {
        
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        titleView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        self.navigationItem.titleView = titleView
        
        let containerView = UIView()
        //containerView.backgroundColor = .yellow
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.borderColor = UIColor.black.cgColor
        profileImageView.layer.borderWidth = 1
        profileImageView.clipsToBounds = true

        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCashWithURLString(urlString: profileImageUrl)
        }
        
        containerView.addSubview(profileImageView)
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = user.name
        containerView.addSubview(nameLabel)
        
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        titleView.layoutIfNeeded()
        
        containerView.widthAnchor.constraint(equalToConstant: nameLabel.frame.origin.x + nameLabel.frame.width).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
//        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleShowChatLogController)))
        
    }
    
    func showChatControllerForUser(user:User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }

}

