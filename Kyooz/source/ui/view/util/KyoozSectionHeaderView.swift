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
    
    fileprivate let stackView = UIStackView()
    
    let strokeLayer = CAShapeLayer()
    

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = ThemeHelper.defaultTableCellColor
        
        headerTitleLabel.textColor = ThemeHelper.defaultFontColor
        headerTitleLabel.font = ThemeHelper.smallFontForStyle(.medium)
        
        let constraints = add(subView: stackView, with: [.left, .bottom])
        constraints[.left]!.constant = 15
        constraints[.bottom]!.constant = -8
        
        stackView.addArrangedSubview(headerTitleLabel)
        stackView.axis = .horizontal
        stackView.spacing = 8
        
        layer.addSublayer(strokeLayer)
        strokeLayer.lineWidth = 0.5
        strokeLayer.strokeColor = UIColor.lightGray.cgColor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = bounds
        let yPosition = rect.maxY - 5
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + 12, y: yPosition))
        path.addLine(to: CGPoint(x: rect.maxX, y: yPosition))
        
        strokeLayer.frame = bounds
        strokeLayer.path = path.cgPath
    }
}

class RowLimitedSectionHeaderView : KyoozSectionHeaderView {
    
    override class var reuseIdentifier:String {
        return "\(RowLimitedSectionHeaderView.self)"
    }
    
    var expanded: Bool = false {
        didSet {
            let rotation = CGAffineTransform(rotationAngle: expanded ? CGFloat(M_PI_2) : 0)
            let translation = CGAffineTransform(translationX: 0, y: expanded ? 3 : 0)
            self.disclosureView.transform = rotation.concatenating(translation)
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
    
    func setExpanded(expanded:Bool, animated:Bool) {
        if animated {
            KyoozUtils.doInMainQueue() {
                UIView.animate(withDuration: 0.2) {
                    self.expanded = expanded
                }
            }
        } else {
            self.expanded = expanded
        }
    }
    
    func setLabelText(_ mainText:String, subText:String) {
        let mainTextAttributes:[NSAttributedStringKey : Any] = [.foregroundColor : ThemeHelper.defaultFontColor]
        let subTextAttributes:[NSAttributedStringKey : Any] = [.foregroundColor : UIColor.darkGray]
        
        let mainAttributedText = NSMutableAttributedString(string: mainText, attributes: mainTextAttributes)
        mainAttributedText.append(NSAttributedString(string: "   " + subText, attributes: subTextAttributes))
        
        headerTitleLabel.attributedText = mainAttributedText
    }
    
    
}

