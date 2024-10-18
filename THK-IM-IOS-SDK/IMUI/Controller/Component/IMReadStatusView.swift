//
//  IMReadStatusView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/3/2.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

public class IMReadStatusView: UIView {

    private var color = UIColor.clear
    private var progress: CGFloat = 0
    private var lineWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateStatus(_ color: UIColor, _ lineWidth: CGFloat, _ progress: CGFloat) {
        self.color = color
        self.lineWidth = lineWidth
        self.progress = progress
        self.setNeedsDisplay()
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.drawCircle(rect)
        if self.progress >= 1.0 {
            self.drawReady(rect)
        } else if self.progress > 0.0 {
            self.drawNotReady(rect)
        }
    }

    private func drawCircle(_ rect: CGRect) {
        let path = UIBezierPath()
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        let radius = maxRadius - lineWidth / 2
        path.addArc(
            withCenter: centerPoint, radius: radius, startAngle: 0, endAngle: 2 * .pi,
            clockwise: true)
        path.lineWidth = CGFloat(lineWidth / 2)
        color.setStroke()
        path.close()
        path.stroke()
    }

    private func drawNotReady(_ rect: CGRect) {
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        let radius = maxRadius - lineWidth / 2 - maxRadius / 3
        let startAngle = -0.5 * .pi
        let endAngle = startAngle + 2.0 * .pi * min(progress, 1.0)
        let path = UIBezierPath(
            arcCenter: centerPoint, radius: radius, startAngle: startAngle, endAngle: endAngle,
            clockwise: true)
        path.addLine(to: centerPoint)
        path.close()
        path.lineWidth = CGFloat(lineWidth / 2)
        color.setStroke()
        color.setFill()
        path.stroke()
        path.fill()
    }

    private func drawReady(_ rect: CGRect) {
        let checkmarkPath = UIBezierPath()
        checkmarkPath.lineWidth = lineWidth / 2
        let startPoint = CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.5)
        let kneePoint = CGPoint(x: rect.minX + rect.width * 0.5, y: rect.minY + rect.height * 0.75)
        let endPoint = CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.25)
        checkmarkPath.move(to: startPoint)
        checkmarkPath.addLine(to: kneePoint)
        checkmarkPath.addLine(to: endPoint)
        color.setStroke()
        checkmarkPath.stroke()
    }

}
