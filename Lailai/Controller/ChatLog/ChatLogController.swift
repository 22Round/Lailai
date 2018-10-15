//
//  ChatLogController.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 7/25/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation
import Photos

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: - Constanst
    
    let reuseIdentifier = "ChatMessageCell"
    
    //MARK: - Vars
    
    var messages = [Message]()
    var containerViewBottomAnchor:NSLayoutConstraint?
    var imageZoomStartImageFrame:CGRect?
    var imageZoomBackground:UIView?
    var imageZoomedFromChat:UIImageView?
    
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
        
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "img_upload")
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        containerView.addSubview(uploadImageView)
        
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 35).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        
        containerView.addSubview(sendButton)
        sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true

        containerView.addSubview(self.inputTextField)
        self.inputTextField.leadingAnchor.constraint(equalTo: uploadImageView.trailingAnchor, constant: 8).isActive = true
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
        setupKeyboardObservers()

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
        
        (0..<collectionView.numberOfSections).indices.forEach { sectionIndex in
            (0..<collectionView.numberOfItems(inSection: sectionIndex)).indices.forEach { itemIndex in
                
                let indexPath = IndexPath(row: itemIndex, section: sectionIndex)
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ChatMessageCell else {return}
                cell.handleRemoveFromStage()
                
            }
        }
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
    
    @objc fileprivate func handleUploadTap() {
        
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
            case .authorized:
                print("Access is granted by user")
                checkPermission()
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({
                    (newStatus) in
                    print("status is \(newStatus)")
                    if newStatus ==  PHAuthorizationStatus.authorized {
                        /* do stuff here */
                        print("success")
                        self.checkPermission()
                    }
                })
                print("It is not determined until now")
            case .restricted:
                // same same
                print("User do not have access to photo album.")
            case .denied:
                // same same
                print("User has denied the permission.")
        }
        
    }
    
    func checkPermission() {
        
        DispatchQueue.main.async(execute: {
            let imagePickerController = UIImagePickerController()
            imagePickerController.allowsEditing = true
            imagePickerController.delegate = self
            imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true)
        })

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        if let videoUrl = info["UIImagePickerControllerMediaURL"] as? URL {
            
            self.handleVideoSelectedFor(url: videoUrl)
        } else {
            
            self.handleImageSelectedFor(info: info)
            
        }
        
        self.dismiss(animated: true)
    }
    
    
    func sendMessageWith(imageUrl:String, image:UIImage) {
        
        let properties = ["imageUrl":imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String : AnyObject]
        sendMessageWith(properties: properties)
    }
    
    fileprivate func setupKeyboardObservers() {
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
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
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
        return NSString(string: text).boundingRect(with: size, options: options, attributes: attributes, context: nil)
    }
    
    //MARK: Handlers
    
    @objc fileprivate func handleKeyDidShow(notification: NSNotification) {
        if messages.count > 0 {
            let indexPath = IndexPath(item: self.messages.count-1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    @objc fileprivate func handleKeyBoardWillShow(notification: NSNotification) {
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        guard let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        containerViewBottomAnchor?.constant = -keyboardFrame.height
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc fileprivate func handleKeyBoardWillHide(notification: NSNotification) {
        containerViewBottomAnchor?.constant = 0
        
        guard let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    deinit {
        print("remove from here")
    }
    
    func handleImageSelectedFor(info: [String : Any] ){
        
        var selectedImageFromPicker:UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            
            self.uploadToFirebaseStorageUsingImage(image: selectedImage) { (imageUrl) in
                self.sendMessageWith(imageUrl: imageUrl, image: selectedImage)
            }
        }
    }
    
    @objc func handleSend() {
        
        guard let text = inputTextField.text else { return }
        if text.isEmpty { return }
        
        let properties = ["text":text] as [String : AnyObject]
        sendMessageWith(properties: properties)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
