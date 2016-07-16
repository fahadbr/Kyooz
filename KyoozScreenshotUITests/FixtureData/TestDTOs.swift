//
//  AudioTrackDTO.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/23/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer

class AudioTrackDTO : NSObject, AudioTrack {
    
    static func titlePropertyForGrouping(libraryGroup:LibraryGrouping) -> String? {
        switch libraryGroup {
        case LibraryGrouping.Albums:
            return "albumTitle"
        case LibraryGrouping.Artists:
            return "albumArtist"
        case LibraryGrouping.Songs:
            return "trackTitle"
        default:
            return nil
        }
    }
    
    static func supportsSecureCoding() -> Bool {
        return false
    }
    
    var albumArtist:String!
    var albumArtistId:UInt64 = 0
    var albumId:UInt64 = 0
    var albumTitle:String!
    var albumTrackNumber:Int = 0
    var assetURL:NSURL!
    var artist:String!
    var id:UInt64 = 0
    var playbackDuration:NSTimeInterval = 0
    var trackTitle:String!
    var artwork:MPMediaItemArtwork!
    var audioTrackSource:AudioTrackSource = .iPodLibrary
    var isCloudTrack:Bool = false
    var genre:String?
    var releaseYear: String?
    var hasArtwork:Bool { return true }
    
    var count:Int {
        return 1
    }
    var representativeTrack:AudioTrack? {
        return self
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
    }
    
    override func valueForKey(key: String) -> AnyObject? {
        switch key {
        case "albumArtist": return albumArtist
        case "albumTitle": return albumTitle
        case "trackTitle": return trackTitle
        default: return nil
        }
    }
    
    func titleForGrouping(libraryGrouping:LibraryGrouping) -> String? {
        switch libraryGrouping {
        case LibraryGrouping.Albums: return albumTitle
        case LibraryGrouping.Artists: return albumArtist
        case LibraryGrouping.Genres: return genre
        case LibraryGrouping.Songs: return trackTitle
        default: break
        }
        return "Some music name"
    }
    
    func persistentIdForGrouping(libraryGrouping:LibraryGrouping) -> UInt64 {
        switch libraryGrouping {
        case LibraryGrouping.Albums: return albumId
        case LibraryGrouping.Artists: return albumArtistId
        case LibraryGrouping.Songs: return id
        default: break
        }
        return 0
    }
    
    func enumerateValuesForProperties(properties: Set<String>!, usingBlock block: ((String, AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void)) {
        
    }
	
	func artworkImage(forSize size: CGSize) -> UIImage? {
		return artwork?.imageWithSize(size)
	}
    
    func encodeWithCoder(aCoder: NSCoder) {
        
    }
    
}