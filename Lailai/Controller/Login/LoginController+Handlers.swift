//
//  LoginController+Handlers.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 7/19/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Photos

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @objc func handleSelectProfileImageView(tapGestureRecognizer: UITapGestureRecognizer) {
        
        self.authorizeToAlbum { (authorized) in
            if authorized == true {
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.allowsEditing = true
                picker.sourceType = .photoLibrary
                picker.modalPresentationStyle = .overCurrentContext
                
                self.present(picker, animated: true, completion: nil)
            }
        }
    }
    
    func authorizeToAlbum(completion:@escaping (Bool)->Void) {
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            NSLog("Will request authorization")
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == .authorized {
                    DispatchQueue.main.async(execute: {
                        completion(true)
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        completion(false)
                    })
                }
            })
            
        } else {
            DispatchQueue.main.async(execute: {
                completion(true)
            })
        }
    }

    
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        var selectedImageFromPicker:UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        self.dismiss(animated: true)
    }
    
    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
    
    @objc func handleLoginRegisterChange() {
        
        let selectetIndex = loginRegisterSegmentedControl.selectedSegmentIndex
        inputsContainerViewHeightAnchor?.constant = selectetIndex == 0 ? 100 : 150
        
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: selectetIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: selectetIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: selectetIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        
    }
    
    @objc func handleLoginRegister() {
        
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            handleLogin()
        }else {
            handleRegister()
        }
    }
    
    func handleLogin() {
        
        guard let password = passwordTextField.text, let email = emailTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            if error != nil {
                print("sign in error: ", error ?? "")
                return
            }
            
            DispatchQueue.main.async {
                
                self.messagesController?.fetchUserAndSetupNavBarTitle()
                self.dismiss(animated: true)
            }
        }
    }
    
    
    func handleRegister() {
        
        guard let name = nameTextField.text, let password = passwordTextField.text, let email = emailTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
            if err != nil {
                print("Error can't register user ", err ?? "")
                return
            }
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            
            guard let profileImage = self.profileImageView.image, let uploadData = profileImage.jpegData(compressionQuality: 0.1) else { return }
            
            
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print(error ?? "")
                    return
                }
                
                storageRef.downloadURL(completion: { (url, error) in
                    guard let downloadURL = url else { return }
                    let values = ["name": name, "email": email, "profileImageUrl": downloadURL.absoluteString]
                    self.registerUserIntoDatabaseWithUID(uid: uid, values: values as [String : AnyObject])
                })
            })
        }
    }
    
    private func registerUserIntoDatabaseWithUID(uid:String, values: [String: AnyObject]) {
        
        let ref:DatabaseReference = Database.database().reference()
        let usersReferance = ref.child("users").child(uid)
        
        usersReferance.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                return
            }
            
            let user = User()
            user.setValuesForKeys(values)
            self.messagesController?.setupNavBarWithUser(user: user)
            
            self.dismiss(animated: true)
        })
    }
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
