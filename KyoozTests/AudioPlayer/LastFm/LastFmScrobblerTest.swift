//
//  LastFmScrobblerTest.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/7/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest
import MediaPlayer
@testable import Kyooz

class LastFmScrobblerTest: XCTestCase {
    
    private var mockTempDataDao:MockTempDataDAO!
    private var mockSimpleWsClient:MockSimpleWsClient!
    private var mockUserDefaults:MockUserDefaults!
    
    private var lastFmScrobbler:LastFmScrobbler!
    
    
    override func setUp() {
        super.setUp()
        lastFmScrobbler = LastFmScrobbler()
        mockTempDataDao = MockTempDataDAO()
        mockSimpleWsClient = MockSimpleWsClient()
        mockUserDefaults = MockUserDefaults()
        
        lastFmScrobbler.tempDataDAO = mockTempDataDao
        lastFmScrobbler.simpleWsClient = mockSimpleWsClient
        lastFmScrobbler.userDefaults = mockUserDefaults
		lastFmScrobbler.internetConnectionAvailable = { true }
        
        mockUserDefaults.set("username", forKey: UserDefaultKeys.LastFmUsernameKey)
        mockUserDefaults.set("session", forKey: UserDefaultKeys.LastFmSessionKey)
		mockTempDataDao.persistentNumberToReturn = CFAbsoluteTimeGetCurrent()
        
        _ = lastFmScrobbler.initialize()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAddToScrobbleCacheAfterInvalidSessionFor24Hours() {
        let scrobbleCacheCountBefore = lastFmScrobbler.scrobbleCache.count
        

        mockTempDataDao.persistentNumberToReturn = CFAbsoluteTimeGetCurrent() - (KyoozConstants.ONE_DAY_IN_SECONDS * 2)
        _ = lastFmScrobbler.initialize()
        
        lastFmScrobbler.addToScrobbleCache(MPMediaItem(), timeStampToScrobble: Date().timeIntervalSince1970)
        
        let scrobbleCacheCountAfter = lastFmScrobbler.scrobbleCache.count
        XCTAssertEqual(scrobbleCacheCountBefore, scrobbleCacheCountAfter)
    }
    
    func testAddToScrobbleCache() {
        let scrobbleCacheCountBefore = lastFmScrobbler.scrobbleCache.count
        
        lastFmScrobbler.addToScrobbleCache(MPMediaItem(), timeStampToScrobble: Date().timeIntervalSince1970)
        
        let scrobbleCacheCountAfter = lastFmScrobbler.scrobbleCache.count
        XCTAssertEqual(scrobbleCacheCountBefore + 1, scrobbleCacheCountAfter)
    }
    
    func testLastSessionValidationTimeUpdated() {
        mockTempDataDao.persistentNumberToReturn = 0
        _ = lastFmScrobbler.initialize()
        
        XCTAssertFalse(lastFmScrobbler.validSessionObtained)
        XCTAssertEqual(0, lastFmScrobbler.lastSessionValidationTime)
        
        let initializedExpectation = expectation(description: "lastFm initialized")
        
        lastFmScrobbler.initializeScrobbler() {
            XCTAssertTrue(self.lastFmScrobbler.validSessionObtained)
            XCTAssertNotEqual(0, self.lastFmScrobbler.lastSessionValidationTime)
            XCTAssertEqual(self.mockTempDataDao.persistentNumberToReturn, self.lastFmScrobbler.lastSessionValidationTime)
            initializedExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { (error) in
            XCTAssertNil(error, "Timed out with unknown error: \(error)")
        }
        
    }
	
	func testURL() {
		mockTempDataDao.persistentNumberToReturn = 0
		_ = lastFmScrobbler.initialize()
		
		let initializedExpectation = expectation(description: "lastFm initialized")
		
		lastFmScrobbler.initializeScrobbler() {
			Logger.debug(self.mockSimpleWsClient.url!)
			Logger.debug(self.mockSimpleWsClient.params!.description)
			XCTAssertEqual(self.mockSimpleWsClient.params!.last!, "api_sig=550a84d40bd73366a3d96f5ef0faba34")
			initializedExpectation.fulfill()
		}
		
		waitForExpectations(timeout: 2) { (error) in
			XCTAssertNil(error, "Timed out with unknown error: \(error)")
		}
		
	}
	
    func testGetOrderedParamKeys() {
        let unorderedParams:[String:String] = [
            "sk" : "session",
            "ab" : "first_param",
            "method": "method_getSessionInfo",
            "username": "username_value",
            "api_key":"api_key_value"
        ]
        let orderedParams:[String] = lastFmScrobbler.getOrderedParamKeys(unorderedParams)
        
        let expectedParams:[String] = ["ab", "api_key", "method", "sk", "username"]
        XCTAssertEqual(orderedParams, expectedParams)
        
    }
    
    func testGetOrderedParamKeysOldMethod() {
        let unorderedParams:[String:String] = [
            "sk" : "session",
            "ab" : "first_param",
            "method": "method_getSessionInfo",
            "username": "username_value",
            "api_key":"api_key_value"
        ]
        let orderedParams:[String] = getOrderedParamKeys(unorderedParams)
        
        let expectedParams:[String] = ["ab", "api_key", "method", "sk", "username"]
        XCTAssertEqual(orderedParams, expectedParams)
        
    }
    
    //old method
    private func getOrderedParamKeys(_ params:[String:String]) -> [String] {
        var orderedParamKeys = [String]()
        for (key, _) in params {
            orderedParamKeys.append(key)
        }
        orderedParamKeys.sort { (val1:String, val2:String) -> Bool in
            return val1.caseInsensitiveCompare(val2) == ComparisonResult.orderedAscending
        }
        return orderedParamKeys
    }
    
    
    //MARK: - Mocked classes
    
    class MockTempDataDAO : TempDataDAO {
        var persistentNumberToReturn:Double!
        
        override func getPersistentNumber(key:String) -> NSNumber? {
			return NSNumber(value: persistentNumberToReturn)
        }
        override func addPersistentValue(key: String, value: Any) {
            if let num = value as? NSNumber {
                persistentNumberToReturn = num.doubleValue
            }
        }
    }
    
    class MockSimpleWsClient : SimpleWSClient {
		var url: String?
		var params: [String]?
        override func executeHTTPSPOSTCall(baseURL: String,
                                           params: [String],
                                           successHandler: @escaping ([String : String]) -> Void,
                                           failureHandler: @escaping () -> ()) {
			
			self.url = baseURL
			self.params = params
            successHandler(["info":"i", "session":"s", "username":"U", "lfm.status":"ok"])
        }
    }
    
    class MockUserDefaults : UserDefaults {
		var values = [String:Any]()
        override func set(_ value: Any?, forKey defaultName: String) {
            if let v = value {
                values[defaultName] = v
            } else {
                values[defaultName] = nil
            }
        }
        
        override func object(forKey defaultName: String) -> Any? {
            return values[defaultName]
        }
    }
    
}



