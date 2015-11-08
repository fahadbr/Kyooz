//
//  LibraryGroupings.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/4/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class LibraryGrouping {
    
    static let Songs = LibraryGrouping(name: "Songs",
        baseQuery: MPMediaQuery.songsQuery(),
        groupingType:MPMediaGrouping.Title)
    static let Albums = LibraryGrouping(name: "Albums",
        baseQuery: MPMediaQuery.albumsQuery(),
        groupingType:MPMediaGrouping.Album,
        nextGroupLevel:Songs)
    static let Composers = LibraryGrouping(name: "Composers",
        baseQuery: MPMediaQuery.composersQuery(),
        groupingType:MPMediaGrouping.Composer,
        nextGroupLevel:Albums)
    static let Compilations = LibraryGrouping(name: "Compilations",
        baseQuery: MPMediaQuery.compilationsQuery(),
        groupingType:MPMediaGrouping.Album,
        nextGroupLevel:Songs)
    static let Playlists = LibraryGrouping(name: "Playlists",
        baseQuery: MPMediaQuery.playlistsQuery(),
        groupingType:MPMediaGrouping.Playlist,
        nextGroupLevel:Songs,
        filtersByTitle:false)
    static let Artists = LibraryGrouping(name: "Artists",
        baseQuery: MPMediaQuery.albumArtistsQuery(),
        groupingType: MPMediaGrouping.AlbumArtist,
        nextGroupLevel:Albums,
        filtersByTitle:false)
    static let Genres = LibraryGrouping(name: "Genres",
        baseQuery: MPMediaQuery.genresQuery(),
        groupingType:MPMediaGrouping.Genre,
        nextGroupLevel:Artists)


    static let values = [Artists, Albums, Composers, Compilations, Genres, Playlists, Songs]
    
    let name:String
    let baseQuery:MPMediaQuery
    let groupingType:MPMediaGrouping
    let nextGroupLevel:LibraryGrouping?
    let filtersByTitle:Bool

    
    private init(name:String, baseQuery:MPMediaQuery, groupingType:MPMediaGrouping, nextGroupLevel:LibraryGrouping? = nil, filtersByTitle:Bool = false) {
        self.name = name
        self.baseQuery = baseQuery
        self.groupingType = groupingType
        self.nextGroupLevel = nextGroupLevel
        self.filtersByTitle = filtersByTitle
    }
    

}