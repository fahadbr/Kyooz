//
//  Playlist.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/23/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

enum PlaylistType : EnumNameDescriptable, CustomStringConvertible {
	
	case kyooz
	case iTunes
	
	var description: String {
		switch self {
		case .kyooz:
			return "KYOOZ PLAYLIST"
		case .iTunes:
			return "ITUNES PLAYLIST"
			
		}
	}
	
}

