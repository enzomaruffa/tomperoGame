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
        let fromView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!

        let finalFrame = transitionContext.finalFrame(for: toView)

        let fOff = finalFrame.offsetBy(dx: finalFrame.width, dy: 55)
        toView.view.frame = fOff

        transitionContext.containerView.insertSubview(toView.view, aboveSubview: fromView.view)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                toView.view.frame = finalFrame
        }, completion: {_ in
                transitionContext.completeTransition(true)
        })
    }
    
    func animatePop(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let initialFrame = transitionContext.initialFrame(for: fromView)
        let fOffPop = initialFrame.offsetBy(dx: initialFrame.width, dy: 55)

        transitionContext.containerView.insertSubview(toView.view, belowSubview: fromView.view)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                fromView.view.frame = fOffPop
        }, completion: {_ in
                transitionContext.completeTransition(true)
        })
    }

}
