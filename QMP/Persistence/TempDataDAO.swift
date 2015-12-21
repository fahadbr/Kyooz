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
    private static let tempDirectory = NSURL(fileURLWithPath: NSTemporaryDirectory())
    private static let nowPlayingQueueFileName = tempDirectory.URLByAppendingPathComponent("nowPlayingQueue.txt").path!
    private static let playbackStateFileName = tempDirectory.URLByAppendingPathComponent("playbackState.txt").path!
    private static let lastFmScrobbleCacheFileName = tempDirectory.URLByAppendingPathComponent("lastFmScrobbleCache.txt").path!
    private static let miscValuesFileName = tempDirectory.URLByAppendingPathComponent("miscValues.txt").path!
    
    private static let INDEX_OF_NOW_PLAYING_ITEM_KEY = "indexOfNowPlayingItem"
    private static let CURRENT_PLAYBACK_TIME_KEY = "currentPlaybackTime"
    
    private var miscellaneousValues:NSMutableDictionary;
    
    
    static let instance:TempDataDAO = TempDataDAO()

    override init() {
        
        miscellaneousValues = NSMutableDictionary()
        if NSFileManager.defaultManager().fileExistsAtPath(TempDataDAO.miscValuesFileName) {
            if let storedValues = NSMutableDictionary(contentsOfFile: TempDataDAO.miscValuesFileName) {
                miscellaneousValues = storedValues
            }
        }
        
        super.init()
        registerForNotifications()
        
    }
    
    deinit {
        unregisterForNotifications()
    }

    //MARK:CLASS FUNCTIONS
    
    func addPersistentValue(key key:String, value:AnyObject) {
        miscellaneousValues.setValue(value, forKey: key)
    }
    
    func getPersistentValue(key key:String) -> AnyObject? {
        return miscellaneousValues.valueForKey(key)
    }
    
    func persistData(notification:NSNotification) {
        let musicPlayer = ApplicationDefaults.audioQueuePlayer
        persistLastFmScrobbleCache(LastFmScrobbler.instance.scrobbleCache)
        persistNowPlayingQueueToTempStorage(musicPlayer.nowPlayingQueue)
        persistCurrentPlaybackStateToTempStorage(musicPlayer.indexOfNowPlayingItem, currentPlaybackTime: musicPlayer.currentPlaybackTime)
        if !miscellaneousValues.writeToFile(TempDataDAO.miscValuesFileName, atomically: true) {
            Logger.debug("failed to write all misc values to temp dir")
        }
    }
    
    
    func persistNowPlayingQueueToTempStorage(mediaItems:[AudioTrack]?) {
       persistMediaItemsToTempStorageFile(TempDataDAO.nowPlayingQueueFileName, mediaItems: mediaItems)
    }
    
    func persistMediaItemsToTempStorageFile(fileName:String, mediaItems:[AudioTrack]?) {
        if(mediaItems == nil || mediaItems!.count == 0) {
            removeFile(fileName)
            return
        }
        
        var persistentIds = [NSNumber]()
        for mediaItem in mediaItems! {
            persistentIds.append(NSNumber(unsignedLongLong: mediaItem.id))
        }
        
        let nsPersistentIds = persistentIds as NSArray
        if(nsPersistentIds.writeToFile(fileName, atomically: true)) {
            Logger.debug("successfully persisted \(nsPersistentIds.count) mediaItem persistentIDs to temp data")
        } else {
            Logger.debug("failed to persist \(nsPersistentIds.count) mediaItem persistentIDs to temp data")
        }
    }
    
    func getNowPlayingQueueFromTempStorage() -> [AudioTrack]? {
        return getMediaItemsFromTempStorage(TempDataDAO.nowPlayingQueueFileName)
    }
    
    func getMediaItemsFromTempStorage(fileName:String) -> [AudioTrack]? {
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
        if(nsCurrentPlaybackState.writeToFile(TempDataDAO.playbackStateFileName, atomically: true)) {
            Logger.debug("persisting playback state \(currentPlaybackState.description)")
        } else {
            Logger.debug("failed to persist playback state")
        }
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
    
    func persistLastFmScrobbleCache(cacheItems:[[String:String]]) {
        if(cacheItems.isEmpty) {
            removeFile(TempDataDAO.lastFmScrobbleCacheFileName)
            return
        }
        let nsCacheItems = cacheItems as NSArray
        
        if(nsCacheItems.writeToFile(TempDataDAO.lastFmScrobbleCacheFileName, atomically: true)) {
            Logger.debug("saved \(nsCacheItems.count) last.fm cached scrobbles to temp data");
        } else {
            Logger.debug("failed to save \(nsCacheItems.count) last.fm cached scrobbles to temp data");
        }
    }
    
    func getLastFmScrobbleCacheFromFile() -> [[String:String]]? {
        if(!NSFileManager.defaultManager().fileExistsAtPath(TempDataDAO.lastFmScrobbleCacheFileName)) {
            return nil
        }
        
        let persistedCache = NSArray(contentsOfFile: TempDataDAO.lastFmScrobbleCacheFileName)
        Logger.debug("loading lastfm cache from temp data: \(persistedCache)")
        return persistedCache as? [[String:String]]
    }
    
    private func removeFile(filePath:String) {
        if(NSFileManager.defaultManager().fileExistsAtPath(filePath)) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(filePath)
            } catch let error as NSError {
                Logger.debug("could not remove file for reason: \(error.description)")
            }
        }
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