//
//  JointMediaQuery.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer

final class JointMediaQuery : MPMediaQuery {
    
    private let query1:MPMediaQuery
    private let query2:MPMediaQuery
    
    override var items: [MPMediaItem]? {
        var returnItems = [MPMediaItem]()
        if let items1 = query1.items {
            returnItems.appendContentsOf(items1)
        }
        if let items2 = query2.items {
            returnItems.appendContentsOf(items2)
        }
        return returnItems
    }
    
    override var collections: [MPMediaItemCollection]? {
        var returnCollections = [MPMediaItemCollection]()
        if let collections1 = query1.collections {
            returnCollections.appendContentsOf(collections1)
        }
        if let collections2 = query2.collections {
            returnCollections.appendContentsOf(collections2)
        }
        return returnCollections
    }
    
    override var itemSections: [MPMediaQuerySection]? {
        return nil
    }
    
    override var collectionSections: [MPMediaQuerySection]? {
        return nil
    }
    
    init(query1:MPMediaQuery, query2:MPMediaQuery) {
        self.query1 = query1
        self.query2 = query2
        super.init(filterPredicates: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
