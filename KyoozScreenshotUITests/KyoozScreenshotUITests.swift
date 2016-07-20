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
		
        
        let app = XCUIApplication()
		
        app.launchEnvironment[MockDataConstants.Key.numberOfAlbums.rawValue] = "\(3)"
        setupSnapshot(app)
        app.launch()

	}
    
    
    func testNowPlayingScreen() {
		
		let app = XCUIApplication()
		let tablesQuery = app.tables
		tablesQuery.staticTexts["Antonio Agostini"].tap()
		tablesQuery.staticTexts["Detrimental Comet Antonio Agostini"].tap()
		tablesQuery.staticTexts["Hazing Pestered Keener Detrimental Comet Antonio Agostini Antonio Agostini"].tap()
		app.toolbars.buttons["ADD TO PLAYLIST"].tap()
		app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other).elementBoundByIndex(2).childrenMatchingType(.Other).elementBoundByIndex(3).childrenMatchingType(.Other).element.childrenMatchingType(.Button).elementBoundByIndex(2).tap()
		app.sliders["3%"].tap()
//		snapshot("nowPlayingScreen")
		
    }
    
}
