//
//  NowPlayingQueue.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/28/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

struct NowPlayingQueueContext {
    
    var persistableContext:NowPlayingQueuePersistableContext {
        return NowPlayingQueuePersistableContext(context: self)
    }

    let type:AudioQueuePlayerType
    private (set) var shuffleActive:Bool = false
    
    var indexOfNowPlayingItem:Int = 0
    
    private var originalQueue:[AudioTrack]
    private var shuffledQueue:[AudioTrack]!
    
    private (set) var currentQueue:[AudioTrack] {
        get {
            return shuffleActive ? shuffledQueue : originalQueue
        } set {
            if shuffleActive {
                shuffledQueue = newValue
            } else {
                originalQueue = newValue
            }
        }
    }
    
    init(originalQueue:[AudioTrack], forType type:AudioQueuePlayerType) {
        self.originalQueue = originalQueue
        self.type = type
    }
    
    mutating func setShuffleActive(shuffleActive:Bool) {
        if shuffleActive {
            shuffleQueue()
        } else {
            restoreOriginalQueue()
        }
        self.shuffleActive = shuffleActive
    }
    
    mutating func overrideShuffleQueue(overrideQueue:[AudioTrack]) {
        shuffledQueue = overrideQueue
        shuffleActive = true
    }
    
    mutating func enqueue(items itemsToEnqueue:[AudioTrack], at position:EnqueueAction) {
        switch(position) {
        case .next:
            currentQueue.insertContentsOf(itemsToEnqueue, at: indexOfNowPlayingItem + 1)
        case .last:
            currentQueue.appendContentsOf(itemsToEnqueue)
        case .random:
            var queue = self.currentQueue
			let index = indexOfNowPlayingItem + 1
            itemsToEnqueue.forEach() {
                queue.insert($0, atIndex: KyoozUtils.randomNumberInRange(index..<queue.count))
            }
            self.currentQueue = queue
            
            if shuffleActive {
                KyoozUtils.doInMainQueueAsync() {
                    self.originalQueue.appendContentsOf(itemsToEnqueue)
                }
            }
        }
    }
    
    mutating func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int) {
        if(index <= indexOfNowPlayingItem) {
            indexOfNowPlayingItem += itemsToInsert.count
        }
        currentQueue.insertContentsOf(itemsToInsert, at: index)
    }
    
    mutating func deleteItemsAtIndices(indiciesToRemove:[Int]) -> Bool {
        var currentQueue = self.currentQueue
        let indicies = indiciesToRemove.sort(>)

        var nowPlayingItemRemoved = false
        for index in indicies {
            currentQueue.removeAtIndex(index)
            if(index < indexOfNowPlayingItem) {
                indexOfNowPlayingItem -= 1
            } else if (index == indexOfNowPlayingItem) {
                nowPlayingItemRemoved = true
            }
        }
        if nowPlayingItemRemoved {
            indexOfNowPlayingItem = 0
        }
        self.currentQueue = currentQueue
        return nowPlayingItemRemoved
    }
    
    mutating func moveMediaItem(fromIndexPath fromIndexPath:Int, toIndexPath:Int) {
        var currentQueue = self.currentQueue
        let tempMediaItem = currentQueue.removeAtIndex(fromIndexPath)
        currentQueue.insert(tempMediaItem, atIndex: toIndexPath)
        
        if fromIndexPath == indexOfNowPlayingItem {
            indexOfNowPlayingItem = toIndexPath
        } else if fromIndexPath < indexOfNowPlayingItem && indexOfNowPlayingItem <= toIndexPath {
            indexOfNowPlayingItem -= 1
        } else if toIndexPath <= indexOfNowPlayingItem && indexOfNowPlayingItem < fromIndexPath {
            indexOfNowPlayingItem += 1
        }
        
        self.currentQueue = currentQueue
    }
    
    mutating func clearItems(towardsDirection direction:ClearDirection, atIndex index:Int) -> Bool {
        var nowPlayingItemRemoved = false
        switch(direction) {
        case .above:
            let oldCount = currentQueue.count
            currentQueue.removeRange(0..<index)
            let newCount = currentQueue.count
            if index > indexOfNowPlayingItem {
                indexOfNowPlayingItem = 0
                nowPlayingItemRemoved = true
            } else {
                indexOfNowPlayingItem -= (oldCount - newCount)
            }
        case .below:
            currentQueue.removeRange((index + 1)..<currentQueue.count)
            if index < indexOfNowPlayingItem {
                indexOfNowPlayingItem = 0
                nowPlayingItemRemoved = true
            }
        case .bothDirections:
            let shuffleWasActive = shuffleActive
            let item = currentQueue[index]
            self = NowPlayingQueueContext(originalQueue: [item], forType: type)
            setShuffleActive(shuffleWasActive)
        }
        return nowPlayingItemRemoved
    }
    
    private mutating func shuffleQueue() {
        if originalQueue.isEmpty {
            shuffledQueue = originalQueue
            return
        }
        
        var tempOriginalQueue = originalQueue
        
        //by doing this we are ensuring that the currently playing item is always on top
        shuffledQueue = [tempOriginalQueue.removeAtIndex(indexOfNowPlayingItem)]
        var tempShuffledQueue = tempOriginalQueue
        for (index, item) in tempOriginalQueue.enumerate() {
            let randomIndex = KyoozUtils.randomNumber(belowValue: index)
            if randomIndex != index {
                tempShuffledQueue[index] = tempShuffledQueue[randomIndex]
            }
            tempShuffledQueue[randomIndex] = item
        }
        shuffledQueue.appendContentsOf(tempShuffledQueue)
        indexOfNowPlayingItem = 0
    }
    
    private mutating func restoreOriginalQueue() {
        guard shuffledQueue != nil && !shuffledQueue.isEmpty else {
            return
        }
        
        let shufSet = NSMutableSet(array: shuffledQueue)
        let origSet = NSSet(array: originalQueue)
        shufSet.minusSet(origSet as Set<NSObject>)
        if let objs = shufSet.allObjects as? [AudioTrack] {
            originalQueue.appendContentsOf(objs)
        }

        
        let item = shuffledQueue[indexOfNowPlayingItem]
        if let index = originalQueue.indexOf({ return item.id == $0.id }) {
            indexOfNowPlayingItem = index
        }
    }
    
}

final class NowPlayingQueuePersistableContext : NSObject, NSSecureCoding {
    private static let originalQueueKey = "originalQueue"
    private static let shuffledQueueKey = "shuffledQueue"
    private static let shuffleActiveKey = "shuffleActiveKey"
    private static let typeKey = "typeKey"
    
    private typealias This = NowPlayingQueuePersistableContext
    
    static func supportsSecureCoding() -> Bool {
        return true
    }
    
    let context:NowPlayingQueueContext
    
    init(context:NowPlayingQueueContext) {
        self.context = context
    }
    
    required init?(coder aDecoder: NSCoder) {
        let type = AudioQueuePlayerType(rawValue: aDecoder.decodeIntegerForKey(This.typeKey)) ?? .Default
        guard let originalQueue = aDecoder.decodeObjectOfClass(NSArray.self, forKey: This.originalQueueKey) as? [AudioTrack] else {
            self.context = NowPlayingQueueContext(originalQueue: [AudioTrack](), forType: type)
            return
        }
        var context = NowPlayingQueueContext(originalQueue: originalQueue, forType: type)
        
        let shuffleActive = aDecoder.decodeBoolForKey(This.shuffleActiveKey)
        
        if shuffleActive {
            if let shuffledQueue = aDecoder.decodeObjectOfClass(NSArray.self, forKey: This.shuffledQueueKey) as? [AudioTrack] {
                context.shuffledQueue = shuffledQueue
                context.shuffleActive = shuffleActive
            }
        }
        
        self.context = context
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(context.originalQueue as NSArray, forKey: This.originalQueueKey)
        if context.shuffleActive {
            aCoder.encodeBool(context.shuffleActive, forKey: This.shuffleActiveKey)
            aCoder.encodeObject(context.shuffledQueue as NSArray, forKey: This.shuffledQueueKey)
        }
        aCoder.encodeInteger(context.type.rawValue, forKey: This.typeKey)
    }
}


