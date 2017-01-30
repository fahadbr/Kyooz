//
//  KyoozTableFooterView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/28/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class KyoozTableFooterView: UIView {
	
	private static let font = UIFont(name:ThemeHelper.defaultFontName, size: ThemeHelper.defaultFontSize)
	
	var text:String? {
		get {
			return label.text
		} set {
			label.text = newValue
			label.frame.size = label.intrinsicContentSize
			frame.size = CGSize(width: label.frame.width, height: label.frame.height + 25)
			layoutSubviews()
		}
	}
	
	private let label = UILabel()
	
	init() {
		super.init(frame: CGRect.zero)
		addSubview(label)
		label.textColor = UIColor.darkGray
		label.textAlignment = .center
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		label.font = type(of: self).font
		
	}
	
	override func layoutSubviews() {
        super.layoutSubviews()
		label.center = CGPoint(x:bounds.midX, y: bounds.midY)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
