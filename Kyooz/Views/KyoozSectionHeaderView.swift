//
//  KyoozSectionHeaderView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/26/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class KyoozSectionHeaderView : UITableViewHeaderFooterView {
    
    class var reuseIdentifier:String {
        return "\(KyoozSectionHeaderView.self)"
    }
    
    let headerTitleLabel = UILabel()
    
    private let stackView = UIStackView()
    
    let strokeLayer = CAShapeLayer()
    

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = ThemeHelper.defaultTableCellColor
        
        headerTitleLabel.textColor = ThemeHelper.defaultFontColor
        headerTitleLabel.font = ThemeHelper.smallFontForStyle(.Medium)
        
        let constraints = add(subView: stackView, with: [.Left, .Bottom])
        constraints[.Left]!.constant = 15
        constraints[.Bottom]!.constant = -8
        
        stackView.addArrangedSubview(headerTitleLabel)
        stackView.axis = .Horizontal
        stackView.spacing = 8
        
        layer.addSublayer(strokeLayer)
        strokeLayer.lineWidth = 0.5
        strokeLayer.strokeColor = UIColor.lightGrayColor().CGColor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = bounds
        let yPosition = rect.maxY - 5
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: rect.minX + 12, y: yPosition))
        path.addLineToPoint(CGPoint(x: rect.maxX, y: yPosition))
        
        strokeLayer.frame = bounds
        strokeLayer.path = path.CGPath
    }
}

class RowLimitedSectionHeaderView : KyoozSectionHeaderView {
    
    override class var reuseIdentifier:String {
        return "\(RowLimitedSectionHeaderView.self)"
    }
    
    var expanded: Bool = false {
        didSet {
            let rotation = CGAffineTransformMakeRotation(expanded ? CGFloat(M_PI_2) : 0)
            let translation = CGAffineTransformMakeTranslation(0, expanded ? 3 : 0)
            self.disclosureView.transform = CGAffineTransformConcat(rotation, translation)
        }
    }
    
    let disclosureView = UILabel()
    let activityIndicator = UIActivityIndicatorView()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        disclosureView.text = "❯"
        disclosureView.font = headerTitleLabel.font
        disclosureView.textColor = ThemeHelper.defaultVividColor
        stackView.addArrangedSubview(disclosureView)
        
        activityIndicator.color = ThemeHelper.defaultVividColor
        
        stackView.addArrangedSubview(activityIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setExpanded(expanded expanded:Bool, animated:Bool) {
        if animated {
            KyoozUtils.doInMainQueue() {
                UIView.animateWithDuration(0.2) {
                    self.expanded = expanded
                }
            }
        } else {
            self.expanded = expanded
        }
    }
    
    func setLabelText(mainText:String, subText:String) {
        let mainTextAttributes:[String : AnyObject] = [NSForegroundColorAttributeName : ThemeHelper.defaultFontColor]
        let subTextAttributes:[String : AnyObject] = [NSForegroundColorAttributeName : UIColor.darkGrayColor()]
        
        let mainAttributedText = NSMutableAttributedString(string: mainText, attributes: mainTextAttributes)
        mainAttributedText.appendAttributedString(NSAttributedString(string: "   " + subText, attributes: subTextAttributes))
        
        headerTitleLabel.attributedText = mainAttributedText
    }
    
    
}

