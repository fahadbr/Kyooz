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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testOldNormalizationMethod() {
        // This is an example of a performance test case.
        let numberOfIterations = 100000
        let testString = "Bitch Don't Kill My Vibe - å∂ç√ß"
        self.measureBlock {
            for _ in 0...numberOfIterations {
                self.normalizeStringOld(testString)
            }
        }
        XCTAssert(true)
    }
    
    func testCurrentNormalizationMethod() {
        // This is an example of a performance test case.
        let numberOfIterations = 100000
        let testString = "Bitch Don't Kill My Vibe - å∂ç√ß"
        self.measureBlock {
            for _ in 0...numberOfIterations {
                testString.normalizedString
            }
        }
        XCTAssert(true)
    }
    
    func testCountPerformance() {
        let index = 4
        
        self.measureBlock() {
            for _ in 0...10000 {
                let string = "123456"
                XCTAssertTrue(index < string.characters.count)
            }
        }
    }
    
    func testCountPerformanceByUsingIndex() {
        let index = 4
        
        self.measureBlock() {
            for _ in 0...10000 {
                let string = "123456"
                XCTAssertTrue(string.startIndex.advancedBy(index, limit: string.endIndex.predecessor()) < string.endIndex)
            }
        }
    }
    
    func testEmptyString() {
        XCTAssertEqual("", "".normalizedString)
    }
    
    private func normalizeStringOld(s:String) -> String {
        var stringToNormalize = s
        if stringToNormalize.characters.count > 1 {
            let charsToRemove = NSCharacterSet.punctuationCharacterSet()
            stringToNormalize = stringToNormalize.componentsSeparatedByCharactersInSet(charsToRemove).joinWithSeparator("")
        }
        stringToNormalize = stringToNormalize.lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return stringToNormalize.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale())
    }
    
}
