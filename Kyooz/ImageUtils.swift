//
//  ImageUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/31/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

struct ImageUtils {
	
	static func customSnapshotFromView(inputView:UIView) -> UIView {
		//Make an image from the input view
		let image = imageForView(inputView, opaque: false)
		
		//Create an image view
		let snapshot = UIImageView(image: image)
		snapshot.layer.shadowOffset = CGSize.zero
		snapshot.layer.shadowRadius = 5.0
		snapshot.layer.shadowOpacity = 0.6
		
		return snapshot
	}
	
	static func imageForView(inputView:UIView, opaque:Bool = true) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, opaque, 0)
		inputView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}
}