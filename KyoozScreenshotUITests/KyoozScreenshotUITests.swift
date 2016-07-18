//
//  KyoozScreenshotUITests.swift
//  KyoozScreenshotUITests
//
//  Created by FAHAD RIAZ on 7/13/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest

class KyoozScreenshotUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        let environmentEntry = KyoozConstants.screenShotUITestingEntry
        
        let app = XCUIApplication()
        app.launchEnvironment[environmentEntry.key] = environmentEntry.value
        
        setupSnapshot(app)
        app.launch()

    }
    
    
    func testNowPlayingScreen() {
        
        let tablesQuery = XCUIApplication().tables
        tablesQuery.staticTexts["Antonio Agostini"].tap()
        tablesQuery.staticTexts["Detrimental Comet Antonio Agostini"].tap()
        
        
    }
    
}
