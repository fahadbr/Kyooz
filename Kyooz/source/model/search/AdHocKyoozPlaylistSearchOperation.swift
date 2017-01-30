//
//  AdHocKyoozPlaylistSearchOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/18/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class AdHocKyoozPlaylistSearchOperation : AbstractResultOperation<[AudioEntity]> {
    
    let searchPredicate:NSPredicate
    let searchString:String
    let primaryKeyName:String
    
    init(primaryKeyName:String, searchPredicate:NSPredicate, searchString:String) {
        self.primaryKeyName = primaryKeyName
        self.searchPredicate = searchPredicate
        self.searchString = searchString
    }
    
    
    override func main() {
        if isCancelled { return }
        var results = [KyoozPlaylist]()
        for element in KyoozPlaylistManager.instance.playlists {
            guard let playlist = element as? KyoozPlaylist else {
                continue
            }
            let primaryKey = playlist.name.normalizedString
            if searchPredicate.evaluate(with: SearchIndexEntry(object: playlist, primaryKeyValue: (primaryKeyName,primaryKey))) {
                results.append(playlist)
            }
            
            if isCancelled { return }
        }
        
        
        inThreadCompletionBlock?(results)
    }
}
