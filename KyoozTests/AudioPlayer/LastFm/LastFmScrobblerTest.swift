//
//  LastFmScrobblerTest.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/7/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest
import Kyooz

class LastFmScrobblerTest: XCTestCase {
    
    var lastFmScrobbler:LastFmScrobbler = LastFmScrobbler.instance
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let unorderedParams:[String:String] = [
            "sk" : "session",
            "method": "method_getSessionInfo",
            "username": "username_value",
            "api_key":"api_key_value"
        ]
//        lastFmScrobbler.getOrderedParamKeys(
        
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
