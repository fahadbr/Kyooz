//
//  TwoAlbumScreenshots.swift
//  TwoAlbumScreenshots
//
//  Created by FAHAD RIAZ on 7/13/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest

class TwoAlbumScreenshots : XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
		
        
        let app = XCUIApplication()
		
        app.launchEnvironment[MockDataConstants.Key.numberOfAlbums.rawValue] = "\(2)"
        setupSnapshot(app)
        app.launch()

	}
    
    
    func testTwoAlbumScreenshots() {
        //now playing screen snapshot
        
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.cells.elementBoundByIndex(1).tap()
        
        tablesQuery.cells.elementBoundByIndex(0).tap()
        let firstTableElement = tablesQuery.cells.elementBoundByIndex(0)
        firstTableElement.tap()
        
        app.buttons["miniPlayerPlayButton"].tap()
        app.buttons["miniPlayerTrackDetails"].tap()
        
        let playbackprogresssliderSlider = app.sliders["playbackProgressSlider"]
        playbackprogresssliderSlider.adjustToNormalizedSliderPosition(0.48)
        
        snapshot("nowPlayingScreen")
        
        
        
        
        //search screen snapshot
        
        app.buttons["HIDE"].tap()
        
        let startCoordinate = firstTableElement.coordinateWithNormalizedOffset(CGVector(dx: 0.3, dy: 0))
        let endCoordinate = firstTableElement.coordinateWithNormalizedOffset(CGVector(dx: 0.8, dy: 0))
        startCoordinate.pressForDuration(0, thenDragToCoordinate: endCoordinate)
        
        app.typeText("carlie")
        
        startCoordinate.pressForDuration(0, thenDragToCoordinate: endCoordinate)
        
        let dragDownCoordinate = firstTableElement.coordinateWithNormalizedOffset(CGVector(dx: 0.3, dy: 1))
        startCoordinate.pressForDuration(0, thenDragToCoordinate: dragDownCoordinate)
        
        snapshot("searchScreen")
        
        
        
        
        
        
        //multiSelect screen snapshot
        
        firstTableElement.coordinateWithNormalizedOffset(CGVector(dx: 1.15, dy: 0)).tap()
        app.buttons["Cornmeal Limelight Carlie Calnan-librarySelectEditButton"].tap()

        app.tables.cells.staticTexts["Hazing Pestered Keener Cornmeal Limelight Carlie Calnan Carlie Calnan"].tap()
        
        snapshot("multiSelectButton")
    }
    
    
    
}
