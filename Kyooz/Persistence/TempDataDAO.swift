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
    static let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    private static let playbackStateSnapshotFileName = tempDirectory.appendingPathComponent("playbackStateSnapshot.archive").path
    private static let lastFmScrobbleCacheFileName = tempDirectory.appendingPathComponent("lastFmScrobbleCache.txt").path
    private static let miscValuesFileName = tempDirectory.appendingPathComponent("miscValues.txt").path
    
    
    private var miscellaneousValues:NSMutableDictionary;
    
    
    static let instance:TempDataDAO = TempDataDAO()

    override init() {
        
        miscellaneousValues = NSMutableDictionary()
        if FileManager.default.fileExists(atPath: TempDataDAO.miscValuesFileName) {
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
    
    func addPersistentValue(key:String, value:AnyObject) {
        miscellaneousValues.setValue(value, forKey: key)
    }
    
    func getPersistentValue(key:String) -> AnyObject? {
        return miscellaneousValues.value(forKey: key)
    }
    
    func getPersistentNumber(key:String) -> NSNumber? {
        return getPersistentValue(key: key) as? NSNumber
    }
    
    func persistData(_ notification:Notification) {
        persistLastFmScrobbleCache()
        persistPlaybackStateSnapshotToTempStorage()
        if !miscellaneousValues.write(toFile: TempDataDAO.miscValuesFileName, atomically: true) {
            Logger.debug("failed to write all misc values to temp dir")
        }
    }
    
    func persistPlaybackStateSnapshotToTempStorage() {
        guard !KyoozUtils.usingMockData else { return }
        
        let persistableState = ApplicationDefaults.audioQueuePlayer.playbackStateSnapshot.persistableSnapshot
        NSKeyedArchiver.archiveRootObject(persistableState, toFile: TempDataDAO.playbackStateSnapshotFileName)
    }
    
    func getPlaybackStateSnapshotFromTempStorage() -> PlaybackStateSnapshot? {
        guard !KyoozUtils.usingMockData else { return nil }
        
        let filename = TempDataDAO.playbackStateSnapshotFileName
        if !FileManager.default.fileExists(atPath: filename) {
            return nil
        }
        
        return (NSKeyedUnarchiver.unarchiveObject(withFile: filename) as? PlaybackStatePersistableSnapshot)?.snapshot
    }
    
    
    func persistMediaItemsToTempStorageFile(_ fileName:String, mediaItems:[AudioTrack]?) {
        if(mediaItems == nil || mediaItems!.count == 0) {
            removeFile(fileName)
            return
        }
        
        let array = mediaItems! as NSArray
        let archiveSuccess = NSKeyedArchiver.archiveRootObject(array, toFile: fileName)
        Logger.debug("\(archiveSuccess ? "successfully archived" : "failed to archive") \(array.count) audio tracks to temp data")
    }
    
    
    func getMediaItemsFromTempStorage(_ fileName:String) -> [AudioTrack]? {
        if(!FileManager.default.fileExists(atPath: fileName)) {
            return nil
        }
        
        var obj:AnyObject?
        KyoozUtils.performWithMetrics(blockDescription: "unarchive media items") {
            obj = NSKeyedUnarchiver.unarchiveObject(withFile: fileName)
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
        
        if(nsCacheItems.write(toFile: TempDataDAO.lastFmScrobbleCacheFileName, atomically: true)) {
            Logger.debug("saved \(nsCacheItems.count) last.fm cached scrobbles to temp data");
        } else {
            Logger.debug("failed to save \(nsCacheItems.count) last.fm cached scrobbles to temp data");
        }
    }
    
    func getLastFmScrobbleCacheFromFile() -> [[String:String]]? {
        if(!FileManager.default.fileExists(atPath: TempDataDAO.lastFmScrobbleCacheFileName)) {
            return nil
        }
        
        let persistedCache = NSArray(contentsOfFile: TempDataDAO.lastFmScrobbleCacheFileName)
        Logger.debug("loading lastfm cache from temp data: \(persistedCache)")
        return persistedCache as? [[String:String]]
    }
    
    private func removeFile(_ filePath:String) {
        if(FileManager.default.fileExists(atPath: filePath)) {
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch let error as NSError {
                Logger.error("could not remove file for reason: \(error.description)")
            }
        }
    }
    
    //MARK:Notification Registration
    
    private func registerForNotifications() {
        let notificationCenter = NotificationCenter.default
        let application = UIApplication.shared
        
        notificationCenter.addObserver(self, selector: #selector(TempDataDAO.persistData(_:)),
            name: NSNotification.Name.UIApplicationWillResignActive, object: application)
        notificationCenter.addObserver(self, selector: #selector(TempDataDAO.persistData(_:)),
            name: NSNotification.Name.UIApplicationWillTerminate, object: application)
    }
    
    private func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
