//
//  ImageExtention.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 7/20/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import Foundation
import UIKit

let imageCash = NSCache<NSString, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCashWithURLString(urlString:String) {
        
        self.image = nil
        
        if let cashedImage = imageCash.object(forKey: urlString as NSString) as? UIImage {
            self.image = cashedImage
            return
        }
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error ?? "")
                    return
                }
                
                DispatchQueue.main.async {
                    guard let downloadedImageData = data else { return }
                    
                    if let imageData = UIImage(data: downloadedImageData) {
                        imageCash.setObject(imageData, forKey: urlString as NSString)
                        self.image = imageData
                        
                    }
                }
                }.resume()
        }
    }
}
