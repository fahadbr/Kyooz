//
//  LibraryGroupings.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/4/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

final class LibraryGrouping : Hashable {
    
    static let Songs = LibraryGrouping(name: "SONGS",
        groupingType:MPMediaGrouping.Title)
    static let Albums = LibraryGrouping(name: "ALBUMS",
        groupingType:MPMediaGrouping.Album,
        nextGroupLevel:Songs)
    static let Composers = LibraryGrouping(name: "COMPOSERS",
        groupingType:MPMediaGrouping.Composer,
        nextGroupLevel:Albums,
        subGroupsForNextLevel: [Albums, Songs])
    static let Compilations = LibraryGrouping(name: "COMPILATIONS",
        groupingType:MPMediaGrouping.Album,
		isCompilation:true,
        nextGroupLevel:Songs)
    static let Playlists = LibraryGrouping(name: "PLAYLISTS",
        groupingType:MPMediaGrouping.Playlist,
        nextGroupLevel:Songs,
        subGroupsForNextLevel: [Songs, Artists, Albums, Genres, Composers])
    static let Artists = LibraryGrouping(name: "ARTISTS",
        groupingType: MPMediaGrouping.AlbumArtist,
        nextGroupLevel:Albums,
        subGroupsForNextLevel: [Albums, Songs])
    static let Genres = LibraryGrouping(name: "GENRES",
        groupingType:MPMediaGrouping.Genre,
        nextGroupLevel:Artists,
        subGroupsForNextLevel: [Artists, Albums, Songs])


    static let values = [Artists, Albums, Playlists, Songs, Genres, Compilations, Composers]
    
    let name:String
    let baseQuery:MPMediaQuery
    let groupingType:MPMediaGrouping
    let nextGroupLevel:LibraryGrouping?
    let subGroupsForNextLevel:[LibraryGrouping]
    
    var hashValue:Int {
        return name.hashValue
    }
    
    private init(name:String,
        groupingType:MPMediaGrouping,
        nextGroupLevel:LibraryGrouping? = nil,
		isCompilation:Bool = false,
        subGroupsForNextLevel:[LibraryGrouping] = [LibraryGrouping]()) {
            self.name = name
            self.baseQuery = MPMediaQuery.audioQueryForGrouping(groupingType, isCompilation: isCompilation)
            self.groupingType = groupingType
            self.nextGroupLevel = nextGroupLevel
            self.subGroupsForNextLevel = subGroupsForNextLevel
    }
    
    func getAllEntriesForSource(source:AudioTrackSource) -> [NSObject]? {
        switch source {
        case .iPodLibrary:
            let results:[MPMediaEntity]? = self === LibraryGrouping.Songs ? baseQuery.items : baseQuery.collections
            return results
        default:
            return nil
        }
    }

}

func ==(lhs:LibraryGrouping, rhs:LibraryGrouping) -> Bool {
    return lhs === rhs
}
