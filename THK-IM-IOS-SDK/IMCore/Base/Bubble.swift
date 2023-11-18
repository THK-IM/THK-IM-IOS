//
//  Bubble.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/4.
//

import UIKit

open class Bubble {
    
    public func drawRectWithRoundedCorner(
        radius: CGFloat,
        borderWidth: CGFloat,
        backgroundColor: UIColor,
        borderColor: UIColor,
        width: CGFloat,
        height: CGFloat,
        pos: Int = 0
    ) -> UIImage? {
        let sizeToFit = CGSize(width: width, height: height)
        let halfBorderWidth = CGFloat(borderWidth / 2.0)
        UIGraphicsBeginImageContextWithOptions(sizeToFit, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        context.setLineWidth(borderWidth)
        context.setStrokeColor(borderColor.cgColor)
        context.setFillColor(backgroundColor.cgColor)
        
        let width = sizeToFit.width, height = sizeToFit.height
        context.move(to: CGPoint(x: width - halfBorderWidth, y: radius + halfBorderWidth))
        // 右下角
        context.addArc(
            tangent1End: CGPoint(x: width - halfBorderWidth, y: height - halfBorderWidth),
            tangent2End: CGPoint(x: width - radius - halfBorderWidth, y: height - halfBorderWidth),
            radius: pos == 1 ? 0 : radius
        )
        // 左下角
        context.addArc(
            tangent1End: CGPoint(x: halfBorderWidth, y: height - halfBorderWidth),
            tangent2End: CGPoint(x: halfBorderWidth, y: height - radius - halfBorderWidth),
            radius: pos == 2 ? 0 : radius
        )
        // 左上角
        context.addArc(
            tangent1End: CGPoint(x: halfBorderWidth, y: halfBorderWidth),
            tangent2End: CGPoint(x: width - halfBorderWidth, y: halfBorderWidth),
            radius: pos == 3 ? 0 : radius
        )
        // 右上角
        context.addArc(
            tangent1End: CGPoint(x: width - halfBorderWidth, y: halfBorderWidth),
            tangent2End: CGPoint(x: width - halfBorderWidth, y: radius + halfBorderWidth),
            radius: pos == 4 ? 0 : radius
        )
        context.drawPath(using: .fillStroke)
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let insets = UIEdgeInsets(
            top: radius+borderWidth,
            left: radius+borderWidth,
            bottom: height-2*(radius+borderWidth),
            right: width-2*(radius+borderWidth)
        )
        if output == nil {
            return nil
        }
        let resize = output!.resizableImage(withCapInsets: insets, resizingMode: UIImage.ResizingMode.stretch)
        return resize
    }
}
