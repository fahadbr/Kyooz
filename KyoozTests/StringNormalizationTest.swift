//
//  StringNormalizationTest.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest
@testable import Kyooz

class StringNormalizationTest: XCTestCase {
    
    private let testString = "  Bitch Don't Kill My Vibé - (ft. Jay-Z)  "
    private let expectedString = "bitch dont kill my vibe  ft jayz"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNormaizeString() {
        XCTAssertEqual(expectedString, testString.normalizedString)
        XCTAssertEqual("*", "*".normalizedString)
    }
    
    func testOldNormalizationMethod() {
        // This is an example of a performance test case.
        let numberOfIterations = 100000
        self.measure {
            for _ in 0...numberOfIterations {
                XCTAssertEqual(self.expectedString, self.normalizeStringOld(self.testString))
            }
        }
        XCTAssert(true)
    }
    
    func testCurrentNormalizationMethod() {
        // This is an example of a performance test case.
        let numberOfIterations = 100000
        self.measure {
            for _ in 0...numberOfIterations {
                XCTAssertEqual(self.expectedString, self.testString.normalizedString)
            }
        }
        XCTAssert(true)
    }
    
    func testEmptyString() {
        XCTAssertEqual("", "".normalizedString)
    }
    
    private func normalizeStringOld(_ s:String) -> String {
        var stringToNormalize = s
        if stringToNormalize.characters.count > 1 {
            let charsToRemove = CharacterSet.punctuation
            stringToNormalize = stringToNormalize.components(separatedBy: charsToRemove).joined(separator: "")
        }
        stringToNormalize = stringToNormalize.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return stringToNormalize.folding(options: .diacriticInsensitive, locale: Locale.current)
    }
    
}
