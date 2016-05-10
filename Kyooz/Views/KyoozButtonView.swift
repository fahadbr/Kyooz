//
//  KyoozButtonView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/10/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class KyoozButtonView : UIButton {
	
	
	@IBInspectable
	var color:UIColor = ThemeHelper.defaultFontColor {
		didSet {
			setNeedsDisplay()
		}
	}
	
	@IBInspectable
	var scale:CGFloat = 0.5 {
		didSet {
			setNeedsDisplay()
		}
	}
	
	override var highlighted:Bool {
		didSet {
			setNeedsDisplay()
		}
	}
	
	override var enabled:Bool {
		didSet {
			setNeedsDisplay()
		}
	}
	
	func setUpColors() {
		let colorToUse:UIColor
		if !enabled {
			colorToUse = UIColor.darkGrayColor()
		} else if highlighted {
			colorToUse = UIColor.redColor()
		} else {
			colorToUse = color
		}
		
		colorToUse.setStroke()
		colorToUse.setFill()
	}
	
}