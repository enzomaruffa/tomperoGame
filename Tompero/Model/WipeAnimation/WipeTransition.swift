//
//  WipeTransition.swift
//  Tompero
//
//  Created by Vinícius Binder on 21/04/20.
//  Copyright © 2020 Tompero. All rights reserved.
//

import UIKit

class WipeTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var operation: UINavigationController.Operation!
    var duration: Double = 0.5
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else { return }
        
        let viewBounds = transitionContext.containerView.bounds
        var oldPos = CGPoint(x: 1.5 * viewBounds.size.width, y: 0.5 * viewBounds.size.height)
        var newPos = CGPoint(x: 0.5 * viewBounds.size.width, y: 0.5 * viewBounds.size.height)
        
        let animatingView = (operation == .push ? toVC : fromVC)
        
        if operation == .push {
            transitionContext.containerView.addSubview(toVC.view)
        } else if operation == .pop {
            transitionContext.containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
            swap(&oldPos, &newPos)
        }
        
        let mask = CALayer()
        mask.backgroundColor = UIColor.white.cgColor
        mask.bounds = viewBounds
        mask.position = newPos
        animatingView.view.layer.mask = mask
        
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.position))
        animation.fromValue = NSValue(cgPoint: oldPos)
        animation.toValue = NSValue(cgPoint: newPos)
        animation.duration = duration
        animation.isRemovedOnCompletion = true
        animation.delegate = AnimationDelegate {
            animatingView.view.layer.mask = nil
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            animation.delegate = nil
        }
        
        mask.add(animation, forKey: "revealAnimation")
    }
    
}
