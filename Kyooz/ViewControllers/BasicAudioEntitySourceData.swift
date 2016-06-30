//
//  BasicAudioEntitySourceData.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/29/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation
class BasicAudioEntitySourceData: NSObject, GroupMutableAudioEntitySourceData {
    
    
    var sections:[SectionDescription] {
        return [SectionDTO(name:sourceDataName, count: entities.count)]
    }
    
    var entities:[AudioEntity]
    var libraryGrouping:LibraryGrouping {
        didSet {
            if libraryGrouping !== oldValue {
                regroupEntities()
            }
        }
    }
    
    var parentGroup: LibraryGrouping?
    var parentCollection: AudioTrackCollection?
    
    let sourceDataName:String
    
    init(tracks:[AudioTrack], grouping:LibraryGrouping, sourceDataName:String? = nil) {
        self.entities = tracks
        self.libraryGrouping = grouping
        self.sourceDataName = sourceDataName ?? grouping.name
        super.init()
        regroupEntities()
    }
    
    init(collection:AudioTrackCollection, grouping:LibraryGrouping, sourceDataName:String? = nil) {
        self.parentCollection = collection
        self.entities = [collection]
        self.libraryGrouping = grouping
        self.sourceDataName = sourceDataName ?? grouping.name
        super.init()
        regroupEntities()
    }
    
    
    private func regroupEntities() {
        if let collection = parentCollection where libraryGrouping == LibraryGrouping.Playlists {
            entities = [collection]
            return
        }
        
        
        let tracks = self.tracks
        
        guard !tracks.isEmpty else { return }
        
        if libraryGrouping == LibraryGrouping.Songs {
            switch parentGroup {
            case LibraryGrouping.Albums?, LibraryGrouping.Compilations?, LibraryGrouping.Podcasts?:
                entities = tracks.sort { $0.albumTrackNumber < $1.albumTrackNumber }
            default:
                entities = tracks
            }
            return
        }
        
        var dict = [String:AudioTrackCollectionDTO]()
        let unknownTitle = "Unknown \(libraryGrouping.name.capitalizedString.withoutLast())"
        for track in tracks {
            let title = track.titleForGrouping(libraryGrouping) ?? unknownTitle
            if dict[title]?.tracks.append(track) == nil {
                let coll = AudioTrackCollectionDTO(tracks:[track])
                dict[title] = coll
            }
        }
        entities = dict.sort { $0.0 < $1.0 }.map { $1 }
        
    }
    
    func reloadSourceData() {
        //no op
    }
    
    func sourceDataForIndex(indexPath:NSIndexPath) -> AudioEntitySourceData? {
        guard let nextGrouping = libraryGrouping.nextGroupLevel else {
            return nil
        }
        let tracks = getTracksAtIndex(indexPath)
        let sourceData = BasicAudioEntitySourceData(tracks: tracks, grouping: nextGrouping)
        sourceData.parentCollection = self[indexPath] as? AudioTrackCollection
        sourceData.parentGroup = libraryGrouping
        return sourceData
    }
    
    
}