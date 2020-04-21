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
        let transition = CustomTransition()
        transition.operation = operation
        return transition
    }

}

class CustomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var operation: UINavigationController.Operation!
    var duration: Double = 1
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if operation == .push {
            animatePush(using: transitionContext)
        } else if operation == .pop {
            animatePop(using: transitionContext)
        }
    }
    
    func animatePush(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) else { return }
        
        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.alpha = 0
        
        UIView.animate(withDuration: duration, animations: {
            toVC.view.alpha = 1
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func animatePop(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else { return }

        transitionContext.containerView.insertSubview(toVC.view, belowSubview: fromVC.view)

        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            fromVC.view.alpha = 0
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

}
