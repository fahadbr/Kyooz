//
//  GrayUILabel.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 8/8/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

class ColoredUILabel : UILabel {
    
    var labelColor:UIColor {
        return UIColor.whiteColor()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        textColor = labelColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        textColor = labelColor
    }
}


class GrayUILabel: ColoredUILabel {
    
    override var labelColor:UIColor {
        return UIColor.grayColor()
    }
}
