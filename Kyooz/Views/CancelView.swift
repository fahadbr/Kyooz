//
//  CancelView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/31/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

final class CancelView : UIView {
    
    let xLabel:UILabel
    let cancelLabel:UILabel
    
    override init(frame: CGRect) {
        let boundsRect = CGRect(origin: CGPoint.zero, size: frame.size)

        cancelLabel = UILabel()
        cancelLabel.text = "CANCEL"
        cancelLabel.font = UIFont(name: ThemeHelper.defaultFontNameBold, size: 20)
        cancelLabel.textColor = UIColor.whiteColor()
        cancelLabel.textAlignment = NSTextAlignment.Center
        cancelLabel.frame.size = cancelLabel.textRectForBounds(boundsRect, limitedToNumberOfLines: 1).size
        
        xLabel = UILabel()
        xLabel.text = "❌"
        xLabel.font = UIFont.boldSystemFontOfSize(60)
        xLabel.textAlignment = .Center
        xLabel.frame.size = xLabel.textRectForBounds(boundsRect, limitedToNumberOfLines: 1).size
        
        let stackView = UIStackView(arrangedSubviews: [xLabel, cancelLabel])
        stackView.axis = .Vertical
        
        super.init(frame: frame)
        
        ConstraintUtils.applyStandardConstraintsToView(subView: stackView, parentView: self)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Coder initializer for CancelView is not implemented")
    }
    
    
}