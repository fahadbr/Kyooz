//
//  ThreeAlbumScreenshots.swift
//  ThreeAlbumScreenshots
//
//  Created by FAHAD RIAZ on 7/13/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest

class ThreeAlbumScreenshots : XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
		
        
        let app = XCUIApplication()
		
        app.launchEnvironment[MockDataConstants.Key.numberOfAlbums.rawValue] = "\(3)"
        setupSnapshot(app)
        app.launch()

	}
    
    
    func testThreeAlbumScreenshots() {
        
        let app = XCUIApplication()
        let tablesQuery = app.tables
        sleep(1)
        tablesQuery.cells.element(boundBy: 0).buttons["menu button"].tap()
        sleep(1)
        tablesQuery.cells.staticTexts["QUEUE RANDOMLY"].tap()
        //queue select
        
        let swipeStartCoordinate = tablesQuery.cells.element(boundBy: 0).coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        let swipeEndCoordinate = tablesQuery.cells.element(boundBy: 0).coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        swipeStartCoordinate.press(forDuration: 0, thenDragTo: swipeEndCoordinate)
        
        app.navigationBars["QUEUE"].buttons["playQueueSelectButton"].tap()
        
        let selectButtonCoordinate = app.navigationBars["QUEUE"].buttons["playQueueSelectButton"].coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 1.0))
        
        selectButtonCoordinate.withOffset(CGVector(dx: -60, dy: 50)).tap()
        selectButtonCoordinate.withOffset(CGVector(dx: -60, dy: 90)).tap()
        selectButtonCoordinate.withOffset(CGVector(dx: -60, dy: 200)).tap()
        
        snapshot("queueSelect")
        
        
        
        //drag and drop
        tablesQuery.cells.element(boundBy: 1).tap()
        tablesQuery.cells.element(boundBy: 1).tap()
        
        let startCoordinate = tablesQuery.cells.element(boundBy: 0).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoordinate = startCoordinate.withOffset(CGVector(dx: 10, dy: 0))
        startCoordinate.press(forDuration: 1, thenDragTo: endCoordinate)
        snapshot("dragAndDrop")
        
    }
    
}
