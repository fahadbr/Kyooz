//
//  TestSourceData.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/24/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class TestSourceData: NSObject, GroupMutableAudioEntitySourceData {
    
    var sections:[SectionDescription] {
        return [SectionDTO(name:libraryGrouping.name, count: entities.count)]
    }
    var entities:[AudioEntity]
    var libraryGrouping:LibraryGrouping {
        didSet {
            if libraryGrouping !== oldValue {
                entities = self.dynamicType.getGroupedEntities(entities, libraryGrouping: libraryGrouping)
            }
        }
    }
	
	var parentGroup: LibraryGrouping?
	var parentCollection: AudioTrackCollection?
    
    init(tracks:[AudioTrack], grouping:LibraryGrouping) {
        self.entities = TestSourceData.getGroupedEntities(tracks, libraryGrouping: grouping)
        self.libraryGrouping = grouping
    }
    
    private static func getGroupedEntities(entities:[AudioEntity], libraryGrouping:LibraryGrouping) -> [AudioEntity] {
        guard let allTracks = (entities as? [AudioTrack]) ?? (entities as? [AudioTrackCollection])?.lazy.flatMap( { return $0.tracks } ) else {
            Logger.error("unexpected audio entity type, couldnt get tracks")
            return [AudioEntity]()
        }
        
        if libraryGrouping == LibraryGrouping.Songs {
            return allTracks.sort({ $0.albumTrackNumber < $1.albumTrackNumber })
        }
        
        
        var dict = [String:AudioTrackCollectionDTO]()
        for track in allTracks {
            guard let title = track.titleForGrouping(libraryGrouping) else {
                Logger.error("wtf no title for grouping \(libraryGrouping)")
                continue
            }
            if dict[title]?.tracks.append(track) == nil {
                let coll = AudioTrackCollectionDTO(tracks:[track])
                dict[title] = coll
            }
        }
        return dict.sort( { $0.0 < $1.0 } ).map({return $1})
        
    }
    
    func reloadSourceData() {
        //no op
    }
    
    func sourceDataForIndex(indexPath:NSIndexPath) -> AudioEntitySourceData? {
        guard let nextGrouping = libraryGrouping.nextGroupLevel else {
            return nil
        }
        let tracks = getTracksAtIndex(indexPath)
        let sourceData = TestSourceData(tracks: tracks, grouping: nextGrouping)
		sourceData.parentCollection = self[indexPath] as? AudioTrackCollection
		sourceData.parentGroup = libraryGrouping
		return sourceData
    }
    

}
