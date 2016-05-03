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
                                       groupingType:MPMediaGrouping.Title)
    static let Albums = LibraryGrouping(name: "ALBUMS",
                                        groupingType:MPMediaGrouping.Album,
                                        usesArtwork:true,
                                        nextGroupLevel:Songs)
    static let Composers = LibraryGrouping(name: "COMPOSERS",
                                           groupingType:MPMediaGrouping.Composer,
                                           nextGroupLevel:Albums,
                                           subGroupsForNextLevel: [Albums, Songs])
    static let Compilations = LibraryGrouping(name: "COMPILATIONS",
                                              groupingType:MPMediaGrouping.Album,
                                              usesArtwork:true,
                                              nextGroupLevel:Songs)
    static let Playlists = LibraryGrouping(name: "PLAYLISTS",
                                           groupingType:MPMediaGrouping.Playlist,
                                           nextGroupLevel:Songs,
                                           usesArtwork:true,
                                           subGroupsForNextLevel: [Songs, Artists, Albums, Genres, Composers])
    static let Artists = LibraryGrouping(name: "ARTISTS",
                                         groupingType: MPMediaGrouping.AlbumArtist,
                                         nextGroupLevel:Albums,
                                         subGroupsForNextLevel: [Albums, Songs])
    static let Genres = LibraryGrouping(name: "GENRES",
                                        groupingType:MPMediaGrouping.Genre,
                                        nextGroupLevel:Artists,
                                        subGroupsForNextLevel: [Artists, Albums, Composers, Songs])
    static let Podcasts = LibraryGrouping(name: "PODCASTS",
                                          groupingType: MPMediaGrouping.PodcastTitle,
                                          usesArtwork:true,
                                          nextGroupLevel: Songs)
    static let AudioBooks = LibraryGrouping(name: "AUDIOBOOKS",
                                            groupingType: MPMediaGrouping.Title,
                                            usesArtwork:true)


    static let allMusicGroupings = [Artists, Albums, Songs, Genres, Composers]
    static let otherGroupings = [AudioBooks, Compilations, Playlists, Podcasts]
    
    let name:String
    
    let groupingType:MPMediaGrouping
    let nextGroupLevel:LibraryGrouping?
    let subGroupsForNextLevel:[LibraryGrouping]
    let usesArtwork:Bool
    
    lazy var baseQuery:MPMediaQuery = {
        switch self {
        case LibraryGrouping.Songs:
            return MPMediaQuery.songsQuery()
        case LibraryGrouping.Albums:
            return MPMediaQuery.albumsQuery()
        case LibraryGrouping.Composers:
            return MPMediaQuery.composersQuery()
        case LibraryGrouping.Compilations:
            return MPMediaQuery.compilationsQuery()
        case LibraryGrouping.Playlists:
            return MPMediaQuery.playlistsQuery()
        case LibraryGrouping.Artists:
            return MPMediaQuery.albumArtistsQuery()
        case LibraryGrouping.Genres:
            return MPMediaQuery.genresQuery()
        case LibraryGrouping.Songs:
            return MPMediaQuery.songsQuery()
        case LibraryGrouping.Podcasts:
            return MPMediaQuery.podcastsQuery()
        case LibraryGrouping.AudioBooks:
            return MPMediaQuery.audiobooksQuery()
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
