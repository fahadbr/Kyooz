//
//  StringExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

extension String {
    
    var md5:String! {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CC_MD5(str!, strLen, result)
        var hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.dealloc(digestLen)
        
        return String(format:hash as String)
    }
    
    var urlEncodedString:String! {
        var encodedString = CFURLCreateStringByAddingPercentEscapes(nil,
            self as CFString,
            nil,
            "!*'();:@&=+$,/?%#[]" as CFString,
            CFStringBuiltInEncodings.UTF8.rawValue)
        return encodedString as String
    }
    
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
    }
    
    func containsIgnoreCase(stringToCheck:String) -> (doesContain:Bool, rangeOfString:Range<String.Index>?) {
        if let range = self.rangeOfString(stringToCheck, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) {
            return (true, range)
        }
        return (false, nil)
    }
}