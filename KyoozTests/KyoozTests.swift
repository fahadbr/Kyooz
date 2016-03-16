//
//  KyoozTests.swift
//  KyoozTests
//
//  Created by FAHAD RIAZ on 1/23/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest
@testable import Kyooz

class KyoozTests: XCTestCase {
    
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
        let BATCH_SIZE = 25
        let scrobbleCache = Array<Int>(0...130)

        let maxValue = scrobbleCache.count
        for var i=0 ; i < maxValue ;  {
            let nextIndexToUse = min(i + BATCH_SIZE, maxValue)
            let slice = scrobbleCache[i..<(nextIndexToUse)]
            print("\(slice)")
            XCTAssert(slice.count <= BATCH_SIZE)
            i = nextIndexToUse
        }
        
        var i = 0
        while i < maxValue {
            let nextIndexToUse = min(i + BATCH_SIZE, maxValue)
            let slice = scrobbleCache[i..<(nextIndexToUse)]
            print("\(slice)")
            XCTAssert(slice.count <= BATCH_SIZE)
            i = nextIndexToUse
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
