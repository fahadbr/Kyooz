//
//  LibraryGroupings.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/4/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

final class LibraryGrouping : NSObject {
    
    static let Songs = LibraryGrouping(name: "SONGS",
                                       groupingType:MPMediaGrouping.title)
    static let Albums = LibraryGrouping(name: "ALBUMS",
                                        groupingType:MPMediaGrouping.album,
                                        nextGroupLevel:Songs,
                                        usesArtwork:true)
    static let Composers = LibraryGrouping(name: "COMPOSERS",
                                           groupingType:MPMediaGrouping.composer,
                                           nextGroupLevel:Albums,
                                           subGroupsForNextLevel: [Albums, Songs])
    static let Compilations = LibraryGrouping(name: "COMPILATIONS",
                                              groupingType:MPMediaGrouping.album,
                                              nextGroupLevel:Songs,
                                              usesArtwork:true)
    static let Playlists = LibraryGrouping(name: "PLAYLISTS",
                                           groupingType:MPMediaGrouping.playlist,
                                           nextGroupLevel:Songs,
                                           usesArtwork:true,
                                           subGroupsForNextLevel: [Songs, Artists, Albums, Genres, Composers])
    static let Artists = LibraryGrouping(name: "ARTISTS",
                                         groupingType: MPMediaGrouping.albumArtist,
                                         nextGroupLevel:Albums,
                                         subGroupsForNextLevel: [Albums, Songs])
    static let Genres = LibraryGrouping(name: "GENRES",
                                        groupingType:MPMediaGrouping.genre,
                                        nextGroupLevel:Artists,
                                        subGroupsForNextLevel: [Artists, Albums, Composers, Songs])
    static let Podcasts = LibraryGrouping(name: "PODCASTS",
                                          groupingType: MPMediaGrouping.podcastTitle,
                                          nextGroupLevel: Songs,
                                          usesArtwork:true)
    static let AudioBooks = LibraryGrouping(name: "AUDIOBOOKS",
                                            groupingType: MPMediaGrouping.title,
                                            usesArtwork:true)


    static let allMusicGroupings = [Artists, Albums, Songs, Genres, Composers]
	static let otherMusicGroupings = [Compilations, Playlists]
    static let otherGroupings = [AudioBooks, Podcasts]
    
    let name:String
    
    let groupingType:MPMediaGrouping
    let nextGroupLevel:LibraryGrouping?
    let subGroupsForNextLevel:[LibraryGrouping]
    let usesArtwork:Bool
    
    lazy var baseQuery:MPMediaQuery = {
        switch self {
        case LibraryGrouping.Songs:
            return MPMediaQuery.songs()
        case LibraryGrouping.Albums:
            return MPMediaQuery.albums()
        case LibraryGrouping.Composers:
            return MPMediaQuery.composers()
        case LibraryGrouping.Compilations:
            return MPMediaQuery.compilations()
        case LibraryGrouping.Playlists:
            return MPMediaQuery.playlists()
        case LibraryGrouping.Artists:
            return MPMediaQuery.albumArtistsQuery()
        case LibraryGrouping.Genres:
            return MPMediaQuery.genres()
        case LibraryGrouping.Songs:
            return MPMediaQuery.songs()
        case LibraryGrouping.Podcasts:
            return MPMediaQuery.podcasts()
        case LibraryGrouping.AudioBooks:
            return MPMediaQuery.audiobooks()
        default:
            return MPMediaQuery()
        }
    }()
    
    
    override var hashValue:Int {
        return name.hashValue
    }
    
    private init(name:String,
        groupingType:MPMediaGrouping,
        nextGroupLevel:LibraryGrouping? = nil,
        usesArtwork:Bool = false,
        subGroupsForNextLevel:[LibraryGrouping] = [LibraryGrouping]()) {
            self.name = name
            self.groupingType = groupingType
            self.nextGroupLevel = nextGroupLevel
            self.usesArtwork = usesArtwork
            self.subGroupsForNextLevel = subGroupsForNextLevel
    }

}

func ==(lhs:LibraryGrouping, rhs:LibraryGrouping) -> Bool {
    return lhs === rhs
}
