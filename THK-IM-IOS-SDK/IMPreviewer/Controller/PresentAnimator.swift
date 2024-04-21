//
//  PresentTransitionAnimated.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/29.
//

import UIKit

public class PresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    public var duration = 0.25
    public var origin: CGPoint?
    public var size: CGSize?
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        guard let animationView = toVC.view.subviews.first else {
            return
        }
        let containerView = transitionContext.containerView
        
        let x = (origin?.x ?? 0)
        let y = (origin?.y ?? 0)
        
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        let translationX = x - screenWidth / 2
        let translationY = y - screenHeight / 2
        
        var scale = 0.2
        if (self.size != nil) {
            scale = self.size!.width / UIScreen.main.bounds.width
        }
        
        // 定义平移和放大变换
        let translationTransform = CGAffineTransform(translationX: translationX/scale, y: translationY/scale)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        // 组合平移和放大变换
        let combinedTransform = translationTransform.concatenating(scaleTransform)
        // 设置转场前的初始状态
        animationView.transform = combinedTransform
        
        toVC.view.alpha = 1
        containerView.addSubview(toVC.view)
        // 执行转场动画
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            // 定义平移和放大变换
            let translationTransform = CGAffineTransform(translationX: 0, y: 0)
            let scaleTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            // 组合平移和放大变换
            let combinedTransform = translationTransform.concatenating(scaleTransform)
            animationView.transform = combinedTransform
            toVC.view.alpha = 1.0
        }) { (finished) in
            // 完成转场
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
