//
//  QueueChangeListener.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/15/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class QueueChangeListener: NSObject {
    
    static let instance = QueueChangeListener()
    
    private var observers = [AnyObject]()
    
    lazy var userDefaults = UserDefaults(suiteName: AudioPlayerCommon.groupId)
    lazy var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    override init() {
        super.init()
        let nc = NotificationCenter.default
        observers.append(nc.addObserver(forName: AudioQueuePlayerUpdate.queueUpdate.notification,
                                        object: audioQueuePlayer,
                                        queue: OperationQueue.main,
                                        using: updateSharedContainer))
        observers.append(nc.addObserver(forName: AudioQueuePlayerUpdate.systematicQueueUpdate.notification,
                                        object: audioQueuePlayer,
                                        queue: OperationQueue.main,
                                        using: updateSharedContainer))
        
    }
    
    deinit {
        for obs in observers {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    @objc private func updateSharedContainer(_: Notification) {
        let queue = audioQueuePlayer.nowPlayingQueue
        
        let ids = queue.map { NSNumber(value: $0.id) } as NSArray
        userDefaults?.set(ids, forKey: AudioPlayerCommon.queueKey)
        userDefaults?.set((audioQueuePlayer as? DRMAudioQueuePlayer)?.lowestIndexPersisted ?? 0, forKey: AudioPlayerCommon.lastPersistedIndexKey)
    }
    
    
}
