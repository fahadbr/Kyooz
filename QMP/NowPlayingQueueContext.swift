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
    
    mutating func enqueue(items itemsToEnqueue:[AudioTrack], atPosition position:EnqueuePosition) {
        switch(position) {
        case .Next:
            currentQueue.insertAtIndex(itemsToEnqueue, index: indexOfNowPlayingItem + 1, placeHolderItem: MPMediaItem())
        case .Last:
            currentQueue.appendContentsOf(itemsToEnqueue)
        case .Random:
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
        var currentQueue = self.currentQueue
        currentQueue.insertAtIndex(itemsToInsert, index: index, placeHolderItem: MPMediaItem())
        if(index <= indexOfNowPlayingItem) {
            indexOfNowPlayingItem += itemsToInsert.count
        }
        self.currentQueue = currentQueue
    }
    
    mutating func deleteItemsAtIndices(indiciesToRemove:[Int]) -> Bool {
        var currentQueue = self.currentQueue
        var indicies = indiciesToRemove
        if(indicies.count > 1) {
            //if removing more than 1 element, sort the array otherwise we will run into index out of bounds issues
            indicies.sortInPlace { $0 > $1 }
        }
        var nowPlayingItemRemoved = false
        for index in indicies {
            currentQueue.removeAtIndex(index)
            if(index < indexOfNowPlayingItem) {
                indexOfNowPlayingItem--
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
            indexOfNowPlayingItem--
        } else if toIndexPath <= indexOfNowPlayingItem && indexOfNowPlayingItem < fromIndexPath {
            indexOfNowPlayingItem++
        }
        
        self.currentQueue = currentQueue
    }
    
    mutating func clearItems(towardsDirection direction:ClearDirection, atIndex index:Int) -> Bool {
        var nowPlayingItemRemoved = false
        switch(direction) {
        case .Above:
            let oldCount = currentQueue.count
            currentQueue.removeRange(0..<index)
            let newCount = currentQueue.count
            if index > indexOfNowPlayingItem {
                indexOfNowPlayingItem = 0
                nowPlayingItemRemoved = true
            } else {
                indexOfNowPlayingItem -= (oldCount - newCount)
            }
        case .Below:
            currentQueue.removeRange((index + 1)..<currentQueue.count)
            if index < indexOfNowPlayingItem {
                indexOfNowPlayingItem = 0
                nowPlayingItemRemoved = true
            }
        case .All:
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
        if shuffledQueue == nil {
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
    
    static func supportsSecureCoding() -> Bool {
        return true
    }
    
    let context:NowPlayingQueueContext
    
    init(context:NowPlayingQueueContext) {
        self.context = context
    }
    
    required init?(coder aDecoder: NSCoder) {
        let type = AudioQueuePlayerType(rawValue: aDecoder.decodeIntegerForKey(NowPlayingQueuePersistableContext.typeKey)) ?? .Default
        guard let originalQueue = aDecoder.decodeObjectOfClass(NSArray.self, forKey: NowPlayingQueuePersistableContext.originalQueueKey) as? [AudioTrack] else {
            self.context = NowPlayingQueueContext(originalQueue: [AudioTrack](), forType: type)
            return
        }
        var context = NowPlayingQueueContext(originalQueue: originalQueue, forType: type)
        
        let shuffleActive = aDecoder.decodeBoolForKey(NowPlayingQueuePersistableContext.shuffleActiveKey)
        
        if shuffleActive {
            if let shuffledQueue = aDecoder.decodeObjectOfClass(NSArray.self, forKey: NowPlayingQueuePersistableContext.shuffledQueueKey) as? [AudioTrack] {
                context.shuffledQueue = shuffledQueue
                context.shuffleActive = shuffleActive
            }
        }
        
        self.context = context
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(context.originalQueue as NSArray, forKey: NowPlayingQueuePersistableContext.originalQueueKey)
        if context.shuffleActive {
            aCoder.encodeBool(context.shuffleActive, forKey: NowPlayingQueuePersistableContext.shuffleActiveKey)
            aCoder.encodeObject(context.shuffledQueue as NSArray, forKey: NowPlayingQueuePersistableContext.shuffledQueueKey)
        }
        aCoder.encodeInteger(context.type.rawValue, forKey: NowPlayingQueuePersistableContext.typeKey)
    }
}


