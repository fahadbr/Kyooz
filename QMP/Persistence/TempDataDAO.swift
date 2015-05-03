//
//  TempDataPersistor.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 4/4/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class TempDataDAO : NSObject {
    //MARK: STATIC PROPERTIES
    private static let tempDirectory = NSTemporaryDirectory()
    private static let nowPlayingQueueFileName = tempDirectory.stringByAppendingPathComponent("nowPlayingQueue.txt")
    private static let playbackStateFileName = tempDirectory.stringByAppendingPathComponent("playbackState.txt")
    
    private static let INDEX_OF_NOW_PLAYING_ITEM_KEY = "indexOfNowPlayingItem"
    private static let CURRENT_PLAYBACK_TIME_KEY = "currentPlaybackTime"
    
    
    static let instance:TempDataDAO = TempDataDAO()

    override init() {
        super.init()
        registerForNotifications()
    }
    
    deinit {
        unregisterForNotifications()
    }

    //MARK:CLASS FUNCTIONS
    
    func persistData(notification:NSNotification) {
        let musicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
        persistNowPlayingQueueToTempStorage(musicPlayer.getNowPlayingQueue())
        persistCurrentPlaybackStateToTempStorage(musicPlayer.indexOfNowPlayingItem, currentPlaybackTime: musicPlayer.currentPlaybackTime)
    }
    
    func persistNowPlayingQueueToTempStorage(mediaItems:[MPMediaItem]?) {
        if(mediaItems == nil || mediaItems!.count == 0) {
            return
        }
        
//        let pIds = (mediaItems as NSArray).valueForKey("persistentID") as NSArray
//        pIds.writeToFile(nowPlayingQueueFileName, atomically: true)
        
        var persistentIds = [NSNumber]()
        for mediaItem in mediaItems! {
            Logger.debug("persisting mediaItem with persistentID:\(mediaItem.persistentID)")
            persistentIds.append(NSNumber(unsignedLongLong: mediaItem.persistentID))
        }
        
        let nsPersistentIds = persistentIds as NSArray
        nsPersistentIds.writeToFile(TempDataDAO.nowPlayingQueueFileName, atomically: true)
        
    }
    
    func getNowPlayingQueueFromTempStorage() -> [MPMediaItem]? {
        if(!NSFileManager.defaultManager().fileExistsAtPath(TempDataDAO.nowPlayingQueueFileName)) {
            return nil
        }
        let persistedMediaIds = NSArray(contentsOfFile: TempDataDAO.nowPlayingQueueFileName) as! [AnyObject]
        
        var queriedMediaItems = [AnyObject]()
        

        for mediaId in persistedMediaIds {
            Logger.debug("querying for mediaItem with persistentID:\(mediaId)")
            var query = MPMediaQuery()
            query.addFilterPredicate(MPMediaPropertyPredicate(value: mediaId,
                forProperty: MPMediaItemPropertyPersistentID, comparisonType: MPMediaPredicateComparison.EqualTo))
            let tempQueryItems = query.items
            if(tempQueryItems == nil || tempQueryItems!.isEmpty) {
                Logger.debug("query for mediaItem with persistentID:\(mediaId) did not return anything")
                continue
            }
            queriedMediaItems.extend(tempQueryItems)
        }
        
        return queriedMediaItems as? [MPMediaItem]
    }
    
    func persistCurrentPlaybackStateToTempStorage(indexOfNowPlayingItem:Int, currentPlaybackTime:Float) {
        var currentPlaybackState = [String : NSNumber]()

        currentPlaybackState[TempDataDAO.INDEX_OF_NOW_PLAYING_ITEM_KEY] = NSNumber(integer: indexOfNowPlayingItem)
        currentPlaybackState[TempDataDAO.CURRENT_PLAYBACK_TIME_KEY] = NSNumber(float: currentPlaybackTime)
        
        let nsCurrentPlaybackState = currentPlaybackState as NSDictionary
        Logger.debug("persisting playback state \(currentPlaybackState.description)")
        nsCurrentPlaybackState.writeToFile(TempDataDAO.playbackStateFileName, atomically: true)
    }
    
    func getPlaybackStateFromTempStorage() -> (indexOfNowPlayingItem:Int, currentPlaybackTime:Float)? {
        if(!NSFileManager.defaultManager().fileExistsAtPath(TempDataDAO.playbackStateFileName)) {
            return nil
        }
        
        let persistedPlaybackState = NSDictionary(contentsOfFile: TempDataDAO.playbackStateFileName)
        
        let persistedIndex = persistedPlaybackState?.objectForKey(TempDataDAO.INDEX_OF_NOW_PLAYING_ITEM_KEY) as? Int
        let persistedTime = persistedPlaybackState?.objectForKey(TempDataDAO.CURRENT_PLAYBACK_TIME_KEY) as? Float
        Logger.debug("retrieving playback state from temp storage \(persistedPlaybackState?.description)")
        
        if let index = persistedIndex, let playbackTime = persistedTime {
            return (index, playbackTime)
        }
        return nil
    }
    
    //MARK:Notification Registration
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        
        notificationCenter.addObserver(self, selector: "persistData:",
            name: UIApplicationWillResignActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: "persistData:",
            name: UIApplicationWillTerminateNotification, object: application)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}