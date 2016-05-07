//
//  TempDataPersistor.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 4/4/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

final class TempDataDAO : NSObject {
    //MARK: STATIC PROPERTIES
    static let tempDirectory = NSURL(fileURLWithPath: NSTemporaryDirectory())
    private static let playbackStateSnapshotFileName = tempDirectory.URLByAppendingPathComponent("playbackStateSnapshot.archive").path!
    private static let lastFmScrobbleCacheFileName = tempDirectory.URLByAppendingPathComponent("lastFmScrobbleCache.txt").path!
    private static let miscValuesFileName = tempDirectory.URLByAppendingPathComponent("miscValues.txt").path!
    
    
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
    
    func getPersistentNumber(key key:String) -> NSNumber? {
        return getPersistentValue(key: key) as? NSNumber
    }
    
    func persistData(notification:NSNotification) {
        persistLastFmScrobbleCache()
        persistPlaybackStateSnapshotToTempStorage()
        if !miscellaneousValues.writeToFile(TempDataDAO.miscValuesFileName, atomically: true) {
            Logger.debug("failed to write all misc values to temp dir")
        }
    }
    
    func persistPlaybackStateSnapshotToTempStorage() {
        let persistableState = ApplicationDefaults.audioQueuePlayer.playbackStateSnapshot.persistableSnapshot
        NSKeyedArchiver.archiveRootObject(persistableState, toFile: TempDataDAO.playbackStateSnapshotFileName)
    }
    
    func getPlaybackStateSnapshotFromTempStorage() -> PlaybackStateSnapshot? {
        let filename = TempDataDAO.playbackStateSnapshotFileName
        if !NSFileManager.defaultManager().fileExistsAtPath(filename) {
            return nil
        }
        
        return (NSKeyedUnarchiver.unarchiveObjectWithFile(filename) as? PlaybackStatePersistableSnapshot)?.snapshot
    }
    
    
    func persistMediaItemsToTempStorageFile(fileName:String, mediaItems:[AudioTrack]?) {
        if(mediaItems == nil || mediaItems!.count == 0) {
            removeFile(fileName)
            return
        }
        
        let array = mediaItems! as NSArray
        let archiveSuccess = NSKeyedArchiver.archiveRootObject(array, toFile: fileName)
        Logger.debug("\(archiveSuccess ? "successfully archived" : "failed to archive") \(array.count) audio tracks to temp data")
    }
    
    
    func getMediaItemsFromTempStorage(fileName:String) -> [AudioTrack]? {
        if(!NSFileManager.defaultManager().fileExistsAtPath(fileName)) {
            return nil
        }
        
        var obj:AnyObject?
        KyoozUtils.performWithMetrics(blockDescription: "unarchive media items") {
            obj = NSKeyedUnarchiver.unarchiveObjectWithFile(fileName)
        }
        guard let array = obj as? NSArray else {
            return nil
        }
        return array as? [AudioTrack]
    }
    
    func persistLastFmScrobbleCache() {
        let cacheItems = LastFmScrobbler.instance.scrobbleCache
        
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
                Logger.error("could not remove file for reason: \(error.description)")
            }
        }
    }
    
    //MARK:Notification Registration
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        
        notificationCenter.addObserver(self, selector: #selector(TempDataDAO.persistData(_:)),
            name: UIApplicationWillResignActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: #selector(TempDataDAO.persistData(_:)),
            name: UIApplicationWillTerminateNotification, object: application)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}