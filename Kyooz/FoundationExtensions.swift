//
//  FoundationExtensions.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/25/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

extension NSIndexPath : Comparable {}

public func <(lhs:NSIndexPath, rhs:NSIndexPath) -> Bool {
    return lhs.compare(rhs) == .OrderedAscending
}

public func ==(lhs:NSIndexPath, rhs:NSIndexPath) -> Bool {
    return lhs.compare(rhs) == .OrderedSame
}

extension NSAttributedString {
	
	convenience init(fileName:String, documentType:DocumentType) throws {
		guard let fileURL = NSBundle.mainBundle().URLForResource(fileName, withExtension: documentType.name) else {
			throw KyoozError(errorDescription:"Couldn't locate resource \(fileName).\(documentType.name)")
		}
		
		var d:NSDictionary? = nil
		try self.init(URL:fileURL, options:documentType.attributeDictionary, documentAttributes: &d)
	}
	
}

extension NSError : KyoozErrorProtocol {
	
	var errorDescription:String {
		return localizedDescription
	}
	
}