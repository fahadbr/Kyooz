//
//  MenuOptionsDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit


final class MenuOptionsDelegate : KyoozOptionsViewControllerDelegate {
    
    private typealias This = MenuOptionsDelegate
    private static let absoluteMax:CGFloat = UIScreen.mainScreen().bounds.width * 95
    
    private static var sizeConstraint : SizeConstraint {
        return SizeConstraint(maxHeight: UIScreen.mainScreen().bounds.height * 0.9,
                              maxWidth: min(375 * 0.70, This.absoluteMax),
                              minHeight: 0,
                              minWidth: min(UIScreen.mainScreen().bounds.width * 0.55 * ThemeHelper.contentSizeRatio, This.absoluteMax))
    }
    
    private let title: String?
    private let details: String?
    private let originatingCenter: CGPoint?
    
    let sizeConstraint: SizeConstraint = This.sizeConstraint
    
    var headerView: UIView {
        let maxWidth = sizeConstraint.maxWidth
        let minWidth = sizeConstraint.minWidth
        
        func createLabel(text text:String?, font:UIFont!) -> UILabel{
            let label = UILabel()
            label.textAlignment = .Center
            label.numberOfLines = 0
            label.lineBreakMode = .ByWordWrapping
            label.textColor = ThemeHelper.defaultVividColor
            label.text = text
            label.font = font ?? ThemeHelper.defaultFont
            
            let rect = label.textRectForBounds(
                CGRect(x: 0, y: 0,
                    width: maxWidth,
                    height: UIScreen.mainScreen().bounds.height),
                limitedToNumberOfLines: 0)
            
            label.frame.size = CGSize(
                width: KyoozUtils.cap(rect.size.width,
                    min: maxWidth,
                    max: minWidth),
                height: rect.size.height)
            
            
            return label
        }
        
        
        let titleLabel = createLabel(text: title, font:ThemeHelper.defaultFont?.fontWithSize(ThemeHelper.defaultFontSize + 1))
        
        let detailsLabel = createLabel(text: details, font:ThemeHelper.smallFontForStyle(.Normal))
        
        let titleSize = titleLabel.frame.size
        let detailsSize = detailsLabel.frame.size
        let assumedLabelHeight = titleSize.height + detailsSize.height
        let assumedLabelWidth = max(titleSize.width, detailsSize.width).cap(min: minWidth, max: maxWidth)
        let estimatedLabelContainerSize = CGSize(width: assumedLabelWidth, height: assumedLabelHeight)
        
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailsLabel])
        stackView.axis = UILayoutConstraintAxis.Vertical
        stackView.frame.size = estimatedLabelContainerSize
        
        let offset:CGFloat = 16
        let containerSize = CGSize(width: estimatedLabelContainerSize.width + offset,
                                   height: estimatedLabelContainerSize.height + offset)
        
        let labelContainerView = UIView()
        labelContainerView.frame.size = containerSize
        
        stackView.center = labelContainerView.center
        labelContainerView.addSubview(stackView)
        return labelContainerView
        
    }
    
    init(title: String?, details: String?, originatingCenter: CGPoint?) {
        self.title = title
        self.details = details
        self.originatingCenter = originatingCenter
    }
    
    func animation(forView view: UIView) -> CAAnimation {
        //animate the menu from the originating center to the screens center
        let transformAnimation = CABasicAnimation(keyPath: "transform")
        let center = originatingCenter ?? view.center
        let scaleTransform = CATransform3DMakeScale(0.1, 0.1, 0)
        let translationTransform = CATransform3DMakeTranslation(abs(center.x) - view.center.x, abs(center.y) - view.center.y, 0)
        
        transformAnimation.fromValue = NSValue(CATransform3D: CATransform3DConcat(scaleTransform, translationTransform))
        transformAnimation.toValue = NSValue(CATransform3D: CATransform3DIdentity)
        transformAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        transformAnimation.duration = 0.2
        transformAnimation.fillMode = kCAFillModeBackwards
        return transformAnimation
    }
    
    
}
