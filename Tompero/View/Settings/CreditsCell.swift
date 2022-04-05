//
//  CreditsCell.swift
//  Tompero
//
//  Created by Vinícius Binder on 27/05/20.
//  Copyright © 2020 Tompero. All rights reserved.
//

import UIKit

class CreditsCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var domainImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        domainImageView.tintColor = #colorLiteral(red: 0.719073236, green: 0.1427283287, blue: 0.204641819, alpha: 1)
    }
    
}
