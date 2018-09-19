//
//  UserCell.swift
//  Lailai
//
//  Created by Vakhtangi Beridze on 7/17/18.
//  Copyright © 2018 22Round. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell {
    
    
    var message:Message? {
        didSet {
            setupNameAndProfileImage()
            
            self.detailTextLabel?.text = message?.text
            
            if let seconds = message?.timestamp?.doubleValue {
                let timestamps = Date(timeIntervalSince1970: seconds)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm:ss a"
                timelabel.text = dateFormatter.string(from: timestamps)
            }
        }
    }
    
    fileprivate func setupNameAndProfileImage() {

        if let id = message?.chatPartnerId() {
            
            let ref = Database.database().reference().child("users").child(id)
            ref.observeSingleEvent(of: .value, andPreviousSiblingKeyWith: { (snapshot, string) in
                if let dictionary = snapshot.value as? [String:AnyObject] {
                    
                    self.textLabel?.text = dictionary["name"] as? String
                    if let profileImageUrl = dictionary["profileImageUrl"] as? String {
                        
                        self.profileImageView.loadImageUsingCashWithURLString(urlString: profileImageUrl)
                    }
                }
            }, withCancel: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let textField = textLabel else { return }
        guard let detailField = detailTextLabel else { return }
        textLabel?.frame = CGRect(x: 64, y: textField.frame.origin.y - 2, width: textField.frame.width, height: textField.frame.height)
        detailTextLabel?.frame = CGRect(x: 64, y: detailField.frame.origin.y + 2, width: detailField.frame.width, height: detailField.frame.height)
    }
    
    let profileImageView:UIImageView = {
        let piv = UIImageView()
        piv.image = UIImage(named: "bmwm5")
        piv.translatesAutoresizingMaskIntoConstraints = false
        piv.layer.cornerRadius = 24
        piv.layer.masksToBounds = true
        return piv
    }()
    
    let timelabel:UILabel = {
        let label = UILabel()
//        label.text = "HH:MM:SS"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        addSubview(profileImageView)
        addSubview(timelabel)
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        timelabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timelabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timelabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        guard let textHeightAnchor = textLabel?.heightAnchor else { return }
        timelabel.heightAnchor.constraint(equalTo: textHeightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
