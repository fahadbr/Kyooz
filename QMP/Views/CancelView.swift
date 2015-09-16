//
//  CancelView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/31/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

class CancelView : UIView {
    
    let blurView:UIVisualEffectView
    let cancelLabel:UILabel
    
    override init(frame: CGRect) {
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
        blurView.frame = frame

        cancelLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: 50))
        cancelLabel.text = "Cancel Insert"
        cancelLabel.font = UIFont(name: ThemeHelper.defaultFontName, size: 22)
        cancelLabel.textColor = UIColor.lightGrayColor()
        cancelLabel.textAlignment = NSTextAlignment.Center
        
        super.init(frame: frame)
        
        addSubview(blurView)
        addSubview(cancelLabel)
        blurView.center = center
        cancelLabel.center = center
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("Coder initializer for CancelView is not implemented")
    }
    
}