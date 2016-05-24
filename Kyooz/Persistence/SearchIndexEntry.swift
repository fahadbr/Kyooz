//
//  SearchIndexEntry.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/14/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class SearchIndexEntry<T:SearchIndexValue> : NSObject {
    
    private var normalizedKeyValues = [String:String]()
    
    let object:T
    let primaryKey:String
    
    override var hashValue:Int {
        return object.hashValue
    }
    
    override var description: String {
        return "primaryKey: \(primaryKey), values:\(normalizedKeyValues.description)\n"
    }
    
    init(object:T, primaryKeyValue:(String, String)) {
        self.object = object
        self.primaryKey = primaryKeyValue.1
        self.normalizedKeyValues[primaryKeyValue.0] = self.primaryKey
    }
    
    override func valueForKey(key: String) -> AnyObject? {
        if let value = normalizedKeyValues[key] {
            return value
        }
        
        if key == "primaryKey" {
            return primaryKey
        }
        
        guard let stringValue = object.valueForKey(key) as? String else {
            return nil
        }
        //lazy load the normalized string and store it
        let normalizedString = stringValue.normalizedString
        normalizedKeyValues[key] = normalizedString
        return normalizedString
    }
    
    override func valueForUndefinedKey(key: String) -> AnyObject? {
        //overriding so it doesnt fail for unknown keys
        return nil
    }
    
}

@objc protocol SearchIndexValue {
	var hashValue:Int { get }
	func valueForKey(key:String) -> AnyObject?
}

