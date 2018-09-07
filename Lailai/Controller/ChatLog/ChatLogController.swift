//
//  ChatLogController.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 7/25/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout {
    
    //MARK: - Constanst
    
    let reuseIdentifier = "Cell"
    
    //MARK: - Vars
    
    var messages = [Message]()
    var containerViewBottomAnchor:NSLayoutConstraint?
    
    //MARK: - Components Closures
    
    var user:User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
    let containerView:UIView = {
        let cont = UIView()
        cont.backgroundColor = .white
        cont.translatesAutoresizingMaskIntoConstraints = false
        //cont.backgroundColor = .red
        return cont
    }()
    
    lazy var sendButton:UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("send", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return btn
        
    }()
    
    lazy var inputTextField:UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter Message...."
        
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        return tf
    }()
    
    let seperatorLineView:UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var inputContainerView:UIView = {
        
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = .white
        containerView.layoutIfNeeded()
        
        containerView.addSubview(sendButton)
        sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true

        containerView.addSubview(self.inputTextField)
        self.inputTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8).isActive = true
        self.inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        containerView.addSubview(seperatorLineView)
        seperatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        seperatorLineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        seperatorLineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        seperatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        containerView.layoutIfNeeded()
        
        return containerView
    }()
    
    //MARK: - Code Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

//        self.collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
//        self.collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        self.collectionView?.backgroundColor = .white
        self.collectionView!.register(ChatMessageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.keyboardDismissMode = .interactive
        
//        setupInputComponents()
//
//        setupKeyboardObservers()

    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
        self.view.layoutIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    //MARK: - Functions
    
    fileprivate func observeMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else { return }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded) { (snapshot) in
            let messageId = snapshot.key
            let messageRef = Database.database().reference().child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String:AnyObject] else { return }
                
                let message = Message()
                message.setValuesForKeys(dictionary)
                
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
            })
        }
    }
    
    fileprivate func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc fileprivate func handleKeyBoardWillShow(notification: NSNotification) {
        guard let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        guard let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        containerViewBottomAnchor?.constant = -keyboardFrame.height
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc fileprivate func handleKeyBoardWillHide(notification: NSNotification) {
        containerViewBottomAnchor?.constant = 0
        
        guard let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    fileprivate func setupInputComponents() {
        
        view.addSubview(containerView)
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomAnchor?.isActive = true
        
        containerView.addSubview(sendButton)
        sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(inputTextField)
        inputTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8).isActive = true
        inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(seperatorLineView)
        seperatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        seperatorLineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        seperatorLineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        seperatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
    }
    
    func estimateFrameForText(text:String) -> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let attributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)]
        return NSString(string: text).boundingRect(with: size, options: options, attributes: attributes, context: nil)
    }
    
    //MARK: Handlers
    
    @objc func handleSend() {
        
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        guard let text = inputTextField.text, let fromId:String = Auth.auth().currentUser?.uid, let toId = user?.id else { return }
        if text.isEmpty { return }
        let timeStamp:NSNumber = NSNumber(value: Int(Date().timeIntervalSince1970))
        let value = ["text":text, "toId":toId, "fromId":fromId, "timestamp":timeStamp] as [String : Any]
//        childRef.updateChildValues(value)
        childRef.updateChildValues(value) { (error, ref) in
            if error != nil {
                print(error ?? "")
                return
            }
            
            self.inputTextField.text = nil
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            userMessageRef.updateChildValues([messageId:1])
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId:1])
            
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
