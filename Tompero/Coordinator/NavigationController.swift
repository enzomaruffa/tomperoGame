//
//  CustomTransition.swift
//  Tompero
//
//  Created by Vinícius Binder on 20/04/20.
//  Copyright © 2020 Tompero. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension NavigationController: UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = WipeTransition()
        transition.operation = operation
        return transition
    }

}
