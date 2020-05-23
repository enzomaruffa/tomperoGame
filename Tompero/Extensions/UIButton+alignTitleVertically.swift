//
//  UIButton+alignContentVertically.swift
//  Tompero
//
//  Created by Vinícius Binder on 22/05/20.
//  Copyright © 2020 Tompero. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    func alignTitleVertically() {
        guard let titleSize = titleLabel?.frame.size else { return }
        let buttonHeight = frame.size.height
        
        let inset = (buttonHeight - titleSize.height) / 2
        titleEdgeInsets = UIEdgeInsets(
            top: inset,
            left: 0,
            bottom: -inset,
            right: 0
        )
    }
}
