//
//  StringExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

private let legalCharacters = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[] ").inverted

extension String {
    
    var md5:String! {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.deallocate(capacity: digestLen)
        
        return String(format:hash as String)
    }
    
    var urlEncodedString:String {
        return addingPercentEncoding(withAllowedCharacters: legalCharacters)!
    }
    
    var normalizedString:String {
        guard startIndex != endIndex else { return self }
        var stringToNormalize = self
        if index(after: startIndex) != endIndex {
            let charsToRemove = CharacterSet.punctuation
            stringToNormalize = stringToNormalize.components(separatedBy: charsToRemove).joined(separator: "")
        }
        stringToNormalize = stringToNormalize.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return stringToNormalize.folding(options: .diacriticInsensitive, locale: Locale.current)
    }
    
    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substring(with: characters.index(startIndex, offsetBy: r.lowerBound) ..< characters.index(startIndex, offsetBy: r.upperBound))
    }
    
    func containsIgnoreCase(_ stringToCheck:String) -> (doesContain:Bool, rangeOfString:Range<String.Index>?) {
        if let range = self.range(of: stringToCheck, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
            return (true, range)
        }
        return (false, nil)
    }
    
    mutating func removeSubstring(_ stringToRemove:String) {
        if let range = range(of: stringToRemove) {
            removeSubrange(range)
        }
    }
	
	func withoutLast() -> String {
		var s = self
		s.remove(at: s.index(before: s.endIndex))
		return s
	}
}
