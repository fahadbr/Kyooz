//
//  PlainHeaderView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/20/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class PlainHeaderView : UIView {
    
    private let gradiantLayer:CAGradientLayer = {
        let gradiant = CAGradientLayer()
        gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradiant.endPoint = CGPoint(x: 0.5, y: 0)
        gradiant.colors = [ThemeHelper.darkAccentColor.CGColor, ThemeHelper.defaultTableCellColor.CGColor]
        return gradiant
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = ThemeHelper.darkAccentColor
        layer.addSublayer(gradiantLayer)
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 0.8
        userInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        gradiantLayer.frame = bounds
    }
    
}