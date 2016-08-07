//
//  MockDataUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation


var numberOfAlbumsToUse: Int? {
	if let value = NSProcessInfo.processInfo()[.numberOfAlbums] {
		return Int(value)
	}
	return nil
//    return 2
}