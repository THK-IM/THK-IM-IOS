//
//  PresentTransitionAnimated.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/29.
//

import UIKit

class PresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration = 0.4
    var origin: CGPoint?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        let containerView = transitionContext.containerView
        
        let x = (origin?.x ?? 0)
        let y = (origin?.y ?? 0)
        
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        let translationX = x - screenWidth / 2
        let translationY = y - screenHeight / 2
        let scale = 0.1
        
        // 定义平移和放大变换
        let translationTransform = CGAffineTransform(translationX: translationX/scale, y: translationY/scale)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        // 组合平移和放大变换
        let combinedTransform = translationTransform.concatenating(scaleTransform)
        // 设置转场前的初始状态
        toVC.view.transform = combinedTransform
        toVC.view.alpha = 0.1
        containerView.addSubview(toVC.view)
        // 执行转场动画
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            // 定义平移和放大变换
            let translationTransform = CGAffineTransform(translationX: 0, y: 0)
            let scaleTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            // 组合平移和放大变换
            let combinedTransform = translationTransform.concatenating(scaleTransform)
            toVC.view.transform = combinedTransform
            toVC.view.alpha = 1.0
        }) { (finished) in
            // 完成转场
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
