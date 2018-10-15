//
//  ChatLogController+Firebase.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 10/2/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import Foundation
import Firebase
import AVFoundation
import Photos

extension ChatLogController {
    
    
    fileprivate func thumbnailImageFor(fileUrl:URL) -> UIImage? {
        
        let video = AVURLAsset(url: fileUrl, options: [:])
        let assetImgGenerate = AVAssetImageGenerator(asset: video)
        assetImgGenerate.appliesPreferredTrackTransform = true
        
        let videoDuration:CMTime = video.duration
        //let durationInSeconds:Float64 = CMTimeGetSeconds(videoDuration)
        
        let numerator = Int64(1)
        let denominator = videoDuration.timescale
        let time = CMTimeMake(value: numerator, timescale: denominator)
        
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            return thumbnail
        } catch {
            print(error)
            return nil
        }
    }
    
//    func thumbnailImageFor(fileUrl:URL) -> UIImage? {
//       // let asset:AVURLAsset = AVURLAsset(url: fileUrl)
//        let asset = AVAsset(url: fileUrl)
//        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
//        assetImgGenerate.appliesPreferredTrackTransform = true
//
//        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
//        do {
//            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
//            let thumbnail = UIImage(cgImage: img)
//            return thumbnail
//        } catch {
//            print(error)
//            return nil
//        }
//
//        //        let grabTime = 1.0
//        //        return generateThumnail(url: fileUrl, fromTime: grabTime)
//
//
//    }
    
    
    func generateThumnail(url : URL, fromTime:Float64) -> UIImage? {
        let asset :AVAsset = AVAsset(url: url)
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero;
        let time        : CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale: 60)
        
        do {
            let img         : CGImage = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let frameImg    : UIImage = UIImage(cgImage: img)
            return frameImg
            
        }catch let error {
            print(error)
        }
        return nil
    }
    
    
    func sendMessageWith(properties: [String:AnyObject]) {
        
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        guard let fromId:String = Auth.auth().currentUser?.uid, let toId = user?.id else { return }
        
        let timeStamp:NSNumber = NSNumber(value: Int(Date().timeIntervalSince1970))
        var values:[String:AnyObject] = ["toId":toId, "fromId":fromId, "timestamp":timeStamp] as [String : AnyObject]
        
        properties.forEach { values[$0] = $1 }
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error ?? "")
                return
            }
            
            self.inputTextField.text = nil
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            guard let messageId = childRef.key else { return }
            userMessageRef.updateChildValues([messageId:1])
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId:1])
            
        }
    }
    
    
    
    func observeMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else { return }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded) { (snapshot) in
            let messageId = snapshot.key
            let messageRef = Database.database().reference().child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String:AnyObject] else { return }
                
                //                let message = Message()
                //                message.setValuesForKeys(dictionary)
                
                self.messages.append(Message(dictionary: dictionary))
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    let indexPath = IndexPath(item: self.messages.count-1, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
            })
        }
    }
    
    func uploadToFirebaseStorageUsingImage(image:UIImage, completion: @escaping (String) -> ()) {
        
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("message_images").child(imageName)
        
        guard let uploadData = image.jpegData(compressionQuality: 0.1) else { return }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg";
        
        let uploadTask = storageRef.putData(uploadData, metadata: metadata, completion: { (metadata, error) in
            
            if error != nil {
                print(error ?? "")
                return
            }
            
            storageRef.downloadURL(completion: { (url, error) in
                guard let downloadURL = url else { return }
                completion(downloadURL.absoluteString)
                
            })
        })
        
        uploadTask.observe(.resume) { snapshot in
            print("Upload resumed, also fires when the upload starts")
        }
        
        uploadTask.observe(.pause) { snapshot in
            print("Upload paused")
        }
        
        uploadTask.observe(.success) { snapshot in
            self.navigationItem.title = self.user?.name
        }
        
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUintCode = snapshot.progress?.completedUnitCount{
                self.navigationItem.title = String(completedUintCode)
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as NSError? {
                switch (StorageErrorCode(rawValue: error.code)!) {
                case .objectNotFound:
                    // File doesn't exist
                    print("File doesn't exist")
                    break
                case .unauthorized:
                    // User doesn't have permission to access file
                    print("Doesn't have permission to access file")
                    break
                case .cancelled:
                    // User canceled the upload
                    print("Canceled the upload")
                    break
                    
                case .unknown:
                    // Unknown error occurred, inspect the server response
                    print("Unknown error occurred, inspect the server response")
                    break
                default:
                    // A separate error occurred. This is a good place to retry the upload.
                    print("A separate error occurred. This is a good place to retry the upload.")
                    break
                }
            }
        }
    }

    func handleVideoSelectedFor(url: URL){
        let localUrl = url
        let fileName = NSUUID().uuidString + ".mov"
        let uploadRef = Storage.storage().reference().child("message_movies").child(fileName)
        let uploadTask = uploadRef.putFile(from: url, metadata: nil) { (metadata, error) in
            if error != nil {
                print("Faild upload of video:", error ?? "")
                return
            }
            
            uploadRef.downloadURL(completion: { (url, error) in
                guard let videoUrl = url?.absoluteString else { return }
                if let thumbnailImage = self.generateThumnail(url: localUrl, fromTime: 1.0){
                    
                    self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                        let properties: [String: AnyObject] = ["imageUrl":imageUrl,
                                                               "imageWidth":thumbnailImage.size.width,
                                                               "imageHeight":thumbnailImage.size.height,
                                                               "videoUrl":videoUrl] as [String: AnyObject]
                        
                        self.sendMessageWith(properties: properties)
                    })
                }
            })
        }
        
        
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUintCode = snapshot.progress?.completedUnitCount{
                self.navigationItem.title = String(completedUintCode)
            }
        }
        
        uploadTask.observe(.success) { snapshot in
            self.navigationItem.title = self.user?.name
        }
    }
}
