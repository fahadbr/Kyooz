//
//  TestSearchExecutionController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/24/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation
@testable import Kyooz

class TestSearchExecutionController : SearchExecutionController {
    
    let entities:[AudioEntity]
    
    init(entities:[AudioEntity], libraryGroup:LibraryGrouping, searchKeys:[String]) {
        self.entities = entities
        super.init(libraryGroup: libraryGroup, searchKeys: searchKeys)
    }
    
    override func createIndexBuildingOperation() -> IndexBuildingOperation<AudioEntity>? {
        guard let titleProp = AudioTrackDTO.titlePropertyForGrouping(libraryGroup) else { return nil }
        return IndexBuildingOperation(parentIndexName: libraryGroup.name, valuesToIndex: entities, maxValuesAmount: 2) {[libraryGroup = self.libraryGroup] (entity) -> (String, String) in
            return (titleProp, entity.titleForGrouping(libraryGroup)!.normalizedString)
        }
    }
    
}
