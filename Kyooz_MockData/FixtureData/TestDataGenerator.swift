//
//  File.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/24/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer

class TestDataGenerator {
    
    private static var randomId:UInt64 = 100100
    
    static func generateData() {
		
        let bundle = Bundle(for: TestDataGenerator.self)
		let testDataDict = NSDictionary(contentsOf: bundle.url(forResource: "TestData", withExtension: "plist")!)!
        
        let artistNames = (testDataDict.object(forKey: "ArtistNames")! as! [String]).sorted()
        let albumNames = testDataDict.object(forKey: "AlbumNames")! as! [String]
        let trackNames = testDataDict.object(forKey: "TrackNames")! as! [String]
        
		let trackAssetURL = bundle.url(forResource: "foreword", withExtension: "mp3")!
        
        var images = [UIImage]()
        for i in 1...4 {
            images.append(UIImage(named: "Artwork\(i)", in: bundle, compatibleWith: nil)!)
        }
        let artworks = images.map() { MPMediaItemArtwork(image: $0) }
        

        var tracks = [AudioTrackDTO]()
        var totalNumberOfAlbums = 0
        
        for (k,artistName) in artistNames.enumerated() {
			let noOfAlbums = numberOfAlbumsToUse ?? KyoozUtils.randomNumber(in: 1..<6)
            for j in 1...noOfAlbums {
                let albumName = albumNames[(k + j) % albumNames.count] + " \(artistName)"
                
				let noOfTracksInAlbum = KyoozUtils.randomNumber(in: 5..<17)
				
                for i in 1...noOfTracksInAlbum {
                    let dto = AudioTrackDTO()
                    dto.trackTitle = trackNames[i - 1].capitalized + " \(albumName) \(artistName)"
                    dto.albumArtist = artistName
                    dto.artist = artistName
                    dto.albumTitle = albumName
                    dto.id = getRandomId()
                    dto.albumTrackNumber = i
                    dto.albumId = getRandomId()
                    dto.albumArtistId = getRandomId()
                    dto.artwork = artworks[totalNumberOfAlbums % artworks.count]
                    dto.assetURL = trackAssetURL
					dto.releaseYear = "\(KyoozUtils.randomNumber(in: 1990..<2017))"
					dto.playbackDuration = Double(KyoozUtils.randomNumber(in: 150..<361))
                    tracks.append(dto)
                }
                
                totalNumberOfAlbums += 1
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
	
        
    }
    
    private static func getRandomId() -> UInt64 {
        randomId += 1
        return randomId
    }
    
    
    
}
