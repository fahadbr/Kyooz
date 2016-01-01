//
//  MediaPlayerAPIHelper.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/2/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class MediaPlayerAPIHelper {
    
    private let objCUtils = ObjCUtils()
    
    private let sel1 = ["number",""]
    private let sel2 = ["of",""]
    private let sel3 = ["items",""]
    
    private let selector:String
    
    init() {
        selector = sel1[0] + sel2[0].capitalizedString + sel3[0].capitalizedString
    }
    
    
    
    func getCurrentQueue(musicPlayer:MPMusicPlayerController) -> [AudioTrack]? {
        if !musicPlayer.respondsToSelector(NSSelectorFromString(selector)) {
            Logger.debug("music player doesnt respond to selector to get no of items")
            return nil
        }
        
        guard let numberOfItems = musicPlayer.valueForKey(selector) as? Int else {
            Logger.debug("didnt get a value for number of items")
            return nil
        }
        
        var items = [AudioTrack]()
        items.reserveCapacity(numberOfItems)
        KyoozUtils.performWithMetrics(blockDescription: "read system queue") {
            for i in 0..<numberOfItems {
                if let item = self.objCUtils.getItemForPlayer(musicPlayer, forIndex: i) {
                    items.append(item)
                } else {
                    Logger.error("was not able to retrieve media item for index \(i)")
                }
            }
        }
        
        return items
    }
    
}
