//
//  AbstractTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/18/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

class AbstractTableViewCell : UITableViewCell {
    
    let cellBackgroundView:UIView = {
        let grayView = UIView()
        grayView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        return grayView
    }()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
	func initialize() {
        selectedBackgroundView = cellBackgroundView
    }
    
    
    
    
}