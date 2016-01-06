//
//  MediaPlayerAPIHelper.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/2/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

final class MediaPlayerAPIHelper {
    
    private static let objCUtils = ObjCUtils()
    
    private static let sel1 = ["number",""]
    private static let sel2 = ["of",""]
    private static let sel3 = ["items",""]
    
    private static let selector:String = {
        return sel1[0] + sel2[0].capitalizedString + sel3[0].capitalizedString
    }()
    
    
    static func getQueueCount(musicPlayer:MPMusicPlayerController) -> Int {
        if !musicPlayer.respondsToSelector(NSSelectorFromString(selector)) {
            Logger.debug("music player doesnt respond to selector to get no of items")
            return 0
        }
        
        guard let numberOfItems = musicPlayer.valueForKey(selector) as? Int else {
            Logger.debug("didnt get a value for number of items")
            return 0
        }
        
        return numberOfItems
    }
    
    static func getMediaItemForIndex(musicPlayer:MPMusicPlayerController ,index:Int) -> AudioTrack? {
        return objCUtils.getItemForPlayer(musicPlayer, forIndex: index)
    }
    
}
