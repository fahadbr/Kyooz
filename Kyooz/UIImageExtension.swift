//
//  UIImageExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/13/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

enum ImageInstance : String, EnumNameDescriptable {
    case AddToPlaylist = "AddToPlaylist"
    case SaveQueue = "SaveQueue"
    case Trash = "Trash"
}

extension UIImage {
    
    convenience init(instance:ImageInstance) {
        self.init(named:instance.rawValue)!
    }
	
	convenience init(highlightedInstance:ImageInstance) {
		self.init(named:highlightedInstance.rawValue + "Highlighted")!
	}
    
}
