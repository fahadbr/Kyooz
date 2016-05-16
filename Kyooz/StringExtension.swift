//
//  StringExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

private let legalCharacters = NSCharacterSet(charactersInString: "!*'();:@&=+$,/?%#[] ").invertedSet

extension String {
    
    var md5:String! {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.dealloc(digestLen)
        
        return String(format:hash as String)
    }
    
    var urlEncodedString:String! {
        return stringByAddingPercentEncodingWithAllowedCharacters(legalCharacters)
    }
    
    var normalizedString:String {
        guard startIndex != endIndex else { return self }
        var stringToNormalize = self
        if startIndex.successor() != endIndex {
            let charsToRemove = NSCharacterSet.punctuationCharacterSet()
            stringToNormalize = stringToNormalize.componentsSeparatedByCharactersInSet(charsToRemove).joinWithSeparator("")
        }
        stringToNormalize = stringToNormalize.lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return stringToNormalize.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale())
    }
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(startIndex.advancedBy(r.startIndex) ..< startIndex.advancedBy(r.endIndex))
    }
    
    func containsIgnoreCase(stringToCheck:String) -> (doesContain:Bool, rangeOfString:Range<String.Index>?) {
        if let range = self.rangeOfString(stringToCheck, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) {
            return (true, range)
        }
        return (false, nil)
    }
    
    mutating func removeSubstring(stringToRemove:String) {
        if let range = rangeOfString(stringToRemove) {
            removeRange(range)
        }
    }
}