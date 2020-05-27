//
//  SelectorButton.swift
//  Tompero
//
//  Created by Vinícius Binder on 27/05/20.
//  Copyright © 2020 Tompero. All rights reserved.
//

import UIKit

class SelectorButton: UIButton {
    
    var image: UIImageView?
    
    let selectedFont = UIFont(name: "TitilliumWeb-Bold", size: 26)
    let defaultFont = UIFont(name: "TitilliumWeb-Light", size: 19)

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                let alpha: CGFloat = 0.5
                titleLabel!.alpha = alpha
                image!.alpha = alpha
            } else {
                titleLabel!.alpha = 1
                image!.alpha = 1
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                titleLabel!.font = defaultFont
                image!.image = UIImage(named: "Settings_selectionButtonOFF")
            } else {
                titleLabel!.font = selectedFont
                image!.image = UIImage(named: "Settings_selectionButtonON")
            }
        }
    }

}
