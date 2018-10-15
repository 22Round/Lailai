//
//  ChatLogController+ImageZoomHandling.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 9/24/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import Foundation
import UIKit

extension ChatLogController {
    
    func performZoomInFor(startingImageViwe:UIImageView){
        
        self.imageZoomedFromChat = startingImageViwe
        self.imageZoomedFromChat?.isHidden = true
        imageZoomStartImageFrame = startingImageViwe.superview?.convert(startingImageViwe.frame, to: nil)
        
        guard let startingFrame = imageZoomStartImageFrame else { return }
        let zoomingImageView = UIImageView(frame: startingFrame)
        zoomingImageView.image = startingImageViwe.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
       
        if let keyWindow = UIApplication.shared.keyWindow {
            
            imageZoomBackground = UIView(frame: keyWindow.frame)
            imageZoomBackground?.backgroundColor = .black
            imageZoomBackground?.alpha = 0
            if let bg = imageZoomBackground {
                keyWindow.addSubview(bg)
            }
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.imageZoomBackground?.alpha = 1
                self.inputContainerView.alpha = 0
                
                let height = startingFrame.height/startingFrame.width * keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            })
        }
    }
    
    @objc fileprivate func handleZoomOut(tapGesture:UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                guard let startingFrame = self.imageZoomStartImageFrame else { return }
                zoomOutImageView.frame = startingFrame
                self.imageZoomBackground?.alpha = 0
                self.inputContainerView.alpha = 1
            }) { (true) in
                if let bg  =  self.imageZoomBackground {
                    bg.removeFromSuperview()
                }
                zoomOutImageView.removeFromSuperview()
                self.imageZoomedFromChat?.isHidden = false
            }
        }
    }
}
