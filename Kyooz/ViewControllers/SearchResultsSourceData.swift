//
//  SearchResultsSourceData.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/14/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class SearchResultsSourceData : AudioEntitySourceData {
    
    var sectionNamesCanBeUsedAsIndexTitles:Bool {
        return false
    }
    
    var sections:[SectionDescription] {
        return [SectionDTO(name: searchExecutionController.description, count: entities.count)]
    }
    var entities:[AudioEntity] {
        return searchExecutionController.searchResults
    }
    
    var libraryGrouping:LibraryGrouping {
        return searchExecutionController.libraryGroup
    }
	
	var parentCollection: AudioTrackCollection? {
		return nil
	}
	
	var parentGroup: LibraryGrouping? {
		return nil
	}
    
    let searchExecutionController:SearchExecutionController
    
    init(searchExecutionController:SearchExecutionController) {
        self.searchExecutionController = searchExecutionController
    }
    
    func reloadSourceData() {
        searchExecutionController.rebuildSearchIndex()
    }
    
    func sourceDataForIndex(indexPath:NSIndexPath) -> AudioEntitySourceData? {
        let entity = self[indexPath]
        if let playlist = entity as? KyoozPlaylist {
            return KyoozPlaylistSourceData(playlist: playlist)
        }
        return MediaQuerySourceData(filterEntity: entity, parentLibraryGroup: libraryGrouping, baseQuery: nil)
    }
    
    
}