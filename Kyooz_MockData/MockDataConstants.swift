//
//  MockDataConstants.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

struct MockDataConstants {
	
	enum Key : String {
		case numberOfAlbums
	}
	
}

extension ProcessInfo {
	
	subscript(key: MockDataConstants.Key) -> String? {
		return environment[key.rawValue]
	}
	
}
