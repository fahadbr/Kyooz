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
        cancelLabel.textColor = UIColor.white
        cancelLabel.textAlignment = NSTextAlignment.center
        cancelLabel.frame.size = cancelLabel.textRect(forBounds: boundsRect, limitedToNumberOfLines: 1).size
        
        xLabel = UILabel()
        xLabel.text = "❌"
        xLabel.font = UIFont.boldSystemFont(ofSize: 60)
        xLabel.textAlignment = .center
        xLabel.frame.size = xLabel.textRect(forBounds: boundsRect, limitedToNumberOfLines: 1).size
        
        let stackView = UIStackView(arrangedSubviews: [xLabel, cancelLabel])
        stackView.axis = .vertical
        
        super.init(frame: frame)
        
        ConstraintUtils.applyStandardConstraintsToView(subView: stackView, parentView: self)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Coder initializer for CancelView is not implemented")
    }
    
    
}
