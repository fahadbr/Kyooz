//
//  SearchResultsHeaderView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/20/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class SearchResultsHeaderView: UIView {
    
    static let reuseIdentifier = "searchResultsHeaderView"
    
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var disclosureIndicator: UILabel!
    @IBOutlet weak var disclosureContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = ThemeHelper.defaultTableCellColor
        disclosureContainerView.backgroundColor = ThemeHelper.defaultTableCellColor
        headerTitleLabel.textColor = ThemeHelper.defaultFontColor
        headerTitleLabel.font = ThemeHelper.smallFontForStyle(.Medium)
        disclosureIndicator.textColor = ThemeHelper.defaultVividColor
        disclosureIndicator.font = headerTitleLabel.font
    }
    

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        let yPosition = rect.maxY - 5
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: rect.minX + 12, y: yPosition))
        path.addLineToPoint(CGPoint(x: rect.maxX, y: yPosition))
        path.lineWidth = 0.5

        UIColor.lightGrayColor().setStroke()
		
        path.stroke()
    }
    
    func animateDisclosureIndicator(shouldExpand shouldExpand:Bool) {
        KyoozUtils.doInMainQueue() {
            UIView.animateWithDuration(0.2) {
                self.applyRotation(shouldExpand:shouldExpand)
            }
        }
    }
    
    func applyRotation(shouldExpand shouldExpand:Bool) {
        let rotation = CGAffineTransformMakeRotation(shouldExpand ? CGFloat(M_PI_2) : 0)
        let translation = CGAffineTransformMakeTranslation(0, shouldExpand ? 3 : 0)
        self.disclosureIndicator.transform = CGAffineTransformConcat(rotation, translation)
    }
	
	func setLabelText(mainText:String, subText:String) {
		let mainTextAttributes:[String : AnyObject] = [NSForegroundColorAttributeName : ThemeHelper.defaultFontColor]
		let subTextAttributes:[String : AnyObject] = [NSForegroundColorAttributeName : UIColor.darkGrayColor()]
		
		let mainAttributedText = NSMutableAttributedString(string: mainText, attributes: mainTextAttributes)
		mainAttributedText.appendAttributedString(NSAttributedString(string: "   " + subText, attributes: subTextAttributes))
		
		headerTitleLabel.attributedText = mainAttributedText
	}

}

final class SearchHeaderFooterView : UITableViewHeaderFooterView {
    
	lazy var headerView:SearchResultsHeaderView = {
		guard let view = NSBundle.mainBundle().loadNibNamed("SearchResultsHeaderView", owner: self, options: nil)?.first as? SearchResultsHeaderView else {
			fatalError("could not load nib named SearchResultsHeaderView")
		}
	
		view.frame = self.contentView.frame
		self.contentView.addSubview(view)
		return view
	}()
	
	override func layoutSubviews() {
		super.layoutSubviews()
		headerView.frame = contentView.frame
	}

}
