//
//  PresentTransitionAnimated.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/29.
//

import UIKit

public class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration = 0.4
    var origin: CGPoint?
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, animations: { [weak self] in
            let x = (self?.origin?.x ?? 0)
            let y = (self?.origin?.y ?? 0)
            let screenWidth = UIScreen.main.bounds.size.width
            let screenHeight = UIScreen.main.bounds.size.height
            let translationX = x - screenWidth / 2
            let translationY = y - screenHeight / 2
            let scale = 0.1
            // 定义平移和缩小变换
            let translationTransform = CGAffineTransform(translationX: translationX/scale, y: translationY/scale)
            let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            // 组合平移和放大变换
            let combinedTransform = translationTransform.concatenating(scaleTransform)
            
            fromView.transform = combinedTransform
            fromView.alpha = 0.0 // 设置透明度为0，使其逐渐消失
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
