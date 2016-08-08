//
//  ComparableExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

extension Comparable {
	
	func cap(min:Self, max:Self) -> Self {
		if self < min {
			return min
		} else if self > max {
			return max
		}
		return self
	}
	
}
