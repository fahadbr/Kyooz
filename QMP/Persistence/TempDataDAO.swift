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
    private static let lastFmScrobbleCacheFileName = tempDirectory.stringByAppendingPathComponent("lastFmScrobbleCache.txt")
    
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
        persistLastFmScrobbleCache(LastFmScrobbler.instance.scrobbleCache)
    }
    
    func persistNowPlayingQueueToTempStorage(mediaItems:[MPMediaItem]?) {
       persistMediaItemsToTempStorageFile(TempDataDAO.nowPlayingQueueFileName, mediaItems: mediaItems)
    }
    
    func persistMediaItemsToTempStorageFile(fileName:String, mediaItems:[MPMediaItem]?) {
        if(mediaItems == nil || mediaItems!.count == 0) {
            return
        }
        
        var persistentIds = [NSNumber]()
        for mediaItem in mediaItems! {
            Logger.debug("persisting mediaItem with persistentID:\(mediaItem.persistentID)")
            persistentIds.append(NSNumber(unsignedLongLong: mediaItem.persistentID))
        }
        
        let nsPersistentIds = persistentIds as NSArray
        nsPersistentIds.writeToFile(fileName, atomically: true)
    }
    
    func getNowPlayingQueueFromTempStorage() -> [MPMediaItem]? {
        return getMediaItemsFromTempStorage(TempDataDAO.nowPlayingQueueFileName)
    }
    
    func getMediaItemsFromTempStorage(fileName:String) -> [MPMediaItem]? {
        if(!NSFileManager.defaultManager().fileExistsAtPath(fileName)) {
            return nil
        }
        let persistedMediaIds = NSArray(contentsOfFile: fileName) as! [AnyObject]
        
        return IPodLibraryDAO.queryMediaItemsFromIds(persistedMediaIds)
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
    
    func persistLastFmScrobbleCache(cacheItems:[(MPMediaItem, NSTimeInterval)]) {
        if(cacheItems.isEmpty) { return }
        var idsToPersist = [NSNumber:NSNumber]()
        for cacheItem in cacheItems {
            idsToPersist[NSNumber(unsignedLongLong: cacheItem.0.persistentID)] = NSNumber(double: cacheItem.1 as Double)
        }
        let nsDict = idsToPersist as NSDictionary
        nsDict.writeToFile(TempDataDAO.lastFmScrobbleCacheFileName, atomically: true)
    }
    
    func getLastFmScrobbleCacheFromFile() -> [(MPMediaItem, NSTimeInterval)]? {
        if(!NSFileManager.defaultManager().fileExistsAtPath(TempDataDAO.lastFmScrobbleCacheFileName)) {
            return nil
        }
        
        let persistedCache = NSDictionary(contentsOfFile: TempDataDAO.playbackStateFileName) as! [NSNumber:NSNumber]
        var returnItems = [(MPMediaItem, NSTimeInterval)]()
        for (mediaId, timestamp) in persistedCache {
            returnItems.append(IPodLibraryDAO.queryMediaItemFromId(mediaId)!, timestamp as! NSTimeInterval)
        }
        return returnItems
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