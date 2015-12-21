//
//  LibraryGroupCollectionViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/15/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

class LibraryGroupCollectionViewCell: UICollectionViewCell {
    
    private var label:UILabel!
    
    var text:String! {
        didSet {
            label.text = text
            sizeToFit()
        }
    }
    
    override var selected:Bool {
        didSet {
            if selected {
                label.textColor = ThemeHelper.defaultTableCellColor
                backgroundColor = ThemeHelper.defaultFontColor
            } else {
                label.textColor = ThemeHelper.defaultFontColor
                backgroundColor = UIColor.clearColor()

            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    
    private func setUpView() {
        backgroundColor = UIColor.clearColor()
        
        label = UILabel()

        label.backgroundColor = UIColor.clearColor()
        label.textAlignment = .Center
        label.font = UIFont(name: ThemeHelper.defaultFontName, size: ThemeHelper.defaultFontSize - 4)
        label.textColor = ThemeHelper.defaultFontColor
        
        layer.cornerRadius = frame.height/3
        layer.borderColor = ThemeHelper.defaultFontColor.CGColor
        layer.borderWidth = 1
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraintEqualToAnchor(contentView.topAnchor).active = true
        label.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor).active = true
        label.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
        label.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
    }
    
    
    
}
