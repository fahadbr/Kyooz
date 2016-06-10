//
//  File.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/24/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest
import MediaPlayer
@testable import Kyooz

class TestDataGenerator: XCTestCase {
    
    private var randomId:UInt64 = 100100
	private var runTest = true
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSourceData() {
		guard runTest else { return }
		
        let bundle = NSBundle(forClass: self.dynamicType)
        let testDataDict = NSDictionary(contentsOfURL: bundle.URLForResource("TestData", withExtension: "plist")!)!
        
        let artistNames = testDataDict.objectForKey("ArtistNames")! as! [String]
        let albumNames = testDataDict.objectForKey("AlbumNames")! as! [String]
        let trackNames = testDataDict.objectForKey("TrackNames")! as! [String]
        
        let trackAssetURL = bundle.URLForResource("foreword", withExtension: "mp3")!
        
        var images = [UIImage]()
        for i in 1...4 {
            images.append(UIImage(named: "Artwork\(i)", inBundle: bundle, compatibleWithTraitCollection: nil)!)
        }
        let artworks = images.map() { MPMediaItemArtwork(image: $0) }
        

        var tracks = [AudioTrackDTO]()
        
        for (k,artistName) in artistNames.enumerate() {
            let noOfAlbums = KyoozUtils.randomNumberInRange(1...5)
            for j in 1...noOfAlbums {
                let albumName = albumNames[(k + j) % albumNames.count] + " \(artistName)"
                
                let noOfTracksInAlbum = KyoozUtils.randomNumberInRange(5...16)
                
                for i in 1...noOfTracksInAlbum {
                    let dto = AudioTrackDTO()
                    dto.trackTitle = trackNames[i - 1].capitalizedString + " \(albumName) \(artistName)"
                    dto.albumArtist = artistName
                    dto.artist = artistName
                    dto.albumTitle = albumName
                    dto.id = getRandomId()
                    dto.albumTrackNumber = i
                    dto.albumId = getRandomId()
                    dto.albumArtistId = getRandomId()
                    dto.artwork = artworks[j % artworks.count]
                    dto.assetURL = trackAssetURL
                    dto.releaseYear = "\(KyoozUtils.randomNumberInRange(1990...2016))"
                    dto.playbackDuration = Double(KyoozUtils.randomNumberInRange(150...360))
                    tracks.append(dto)
                }
            }
        }
        
        let testSourceData = TestSourceData(tracks: tracks, grouping: LibraryGrouping.Artists)
        
        let artistEntities = testSourceData.entities
        let albumEntities = TestSourceData(tracks: tracks, grouping: LibraryGrouping.Albums).entities
        
        let artistSE = TestSearchExecutionController(entities: artistEntities, libraryGroup: LibraryGrouping.Artists, searchKeys: ["albumArtist"])
        let albumSE = TestSearchExecutionController(entities: albumEntities, libraryGroup: LibraryGrouping.Albums, searchKeys: ["albumTitle","albumArtist"])
        let trackSE = TestSearchExecutionController(entities: tracks, libraryGroup: LibraryGrouping.Songs, searchKeys: ["trackTitle","albumTitle","albumArtist"])
        let searchVC = AudioEntitySearchViewController.instance
        searchVC.searchExecutionControllers = [artistSE, albumSE, trackSE]
        searchVC.applyDatasourceDelegate()
        
        
        
        let rootVC = RootViewController.instance.libraryNavigationController.topViewController as! AudioEntityLibraryViewController
        rootVC.isBaseLevel = true
        rootVC.sourceData = testSourceData
        rootVC.applyDataSourceAndDelegate()
        rootVC.reloadAllData()
        
        expectationForNotification(AudioQueuePlayerUpdate.QueueUpdate.rawValue, object: ApplicationDefaults.audioQueuePlayer) { _ -> Bool in
            return ApplicationDefaults.audioQueuePlayer.nowPlayingItem is AudioTrackDTO
        }
        expectationForNotification(AudioQueuePlayerUpdate.QueueUpdate.rawValue, object: ApplicationDefaults.audioQueuePlayer) { _ -> Bool in
            return ApplicationDefaults.audioQueuePlayer.nowPlayingQueue.isEmpty
        }
        
        waitForExpectationsWithTimeout(6000, handler: nil)
        
    }
    
    private func getRandomId() -> UInt64 {
        randomId += 1
        return randomId
    }
    
    
    
}
