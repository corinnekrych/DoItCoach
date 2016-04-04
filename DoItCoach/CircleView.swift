//
//  CircleView.swift
//  Pom
//
//  Created by Corinne Krych on 19/03/16.
//  Copyright © 2016 corinne. All rights reserved.
//

import UIKit

public class CircleView: UIView {
    var circleLayer: CAShapeLayer!
    
    func animateCircle(spent: NSTimeInterval, color:UIColor, duration: NSTimeInterval) {
        circleLayer = CAShapeLayer()
        self.backgroundColor = UIColor.clearColor()
        
        // Use UIBezierPath as an easy way to create the CGPath for the layer.
        // The path should be the entire circle.
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: (frame.size.width - 10)/2, startAngle: CGFloat(3*M_PI/2), endAngle: CGFloat(M_PI * 7/2.0), clockwise: true)
        
        // Setup the CAShapeLayer with the path, colors, and line width
        circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.CGPath
        circleLayer.fillColor = UIColor.clearColor().CGColor
        circleLayer.strokeColor = color.CGColor
        circleLayer.lineWidth = 8.0;
        
        // Don't draw the circle initially
        circleLayer.strokeEnd = 0.0
        
        // Add the circleLayer to the view's layer's sublayers
        layer.addSublayer(circleLayer)
        
        // We want to animate the strokeEnd property of the circleLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        // Set the animation duration appropriately
        animation.duration = duration - spent
        

        let from = spent/duration
        print("from \(from) durationn \(duration) spent \(spent)")
        // Animate from 0 (no circle) to 1 (full circle)
        animation.fromValue = from
        animation.toValue = 1
        
        // Do a linear animation (i.e. the speed of the animation stays the same)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        // Set the circleLayer's strokeEnd property to 1.0 now so that it's the
        // right value when the animation ends.
        circleLayer.strokeEnd = 1.0
        
        // Do the actual animation
        circleLayer.addAnimation(animation, forKey: "animateCircle")
    }
}
