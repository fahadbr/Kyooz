//
//  MediaLibrarySearchDisplayDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/8/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

class MediaLibrarySearchDisplayDelegate : NSObject, UISearchDisplayDelegate {
    
    var filteredItems = [AudioTrack]()
    
    func filterContentForSearchText(searchText: String?) {
        
    }
    
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String?) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }
    
}
