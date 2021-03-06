//
//  PlayQueue.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/28/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

struct PlayQueue {
    
    var persistableContext:PlayQueuePersistableWrapper {
        return PlayQueuePersistableWrapper(context: self)
    }

    let type:AudioQueuePlayerType
    fileprivate (set) var shuffleActive:Bool = false
    
    var indexOfNowPlayingItem:Int = 0
    
    fileprivate var originalQueue:[AudioTrack]
    fileprivate var shuffledQueue:[AudioTrack]!
    
    fileprivate (set) var currentQueue:[AudioTrack] {
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
    
    mutating func setShuffleActive(_ shuffleActive:Bool) {
        if shuffleActive {
            shuffleQueue()
        } else {
            restoreOriginalQueue()
        }
        self.shuffleActive = shuffleActive
    }
    
    mutating func overrideShuffleQueue(_ overrideQueue:[AudioTrack]) {
        shuffledQueue = overrideQueue
        shuffleActive = true
    }
    
    mutating func enqueue(items itemsToEnqueue:[AudioTrack], at position:EnqueueAction) {
        let index = currentQueue.isEmpty ? 0 : indexOfNowPlayingItem + 1
        switch(position) {
        case .next:
            currentQueue.insert(contentsOf: itemsToEnqueue, at: index)
        case .last:
            currentQueue.append(contentsOf: itemsToEnqueue)
        case .random:
            var queue = self.currentQueue
            itemsToEnqueue.forEach() {
				queue.insert($0, at: KyoozUtils.randomNumber(in: index..<queue.count))
            }
            self.currentQueue = queue
            
            if shuffleActive {
                originalQueue.append(contentsOf: itemsToEnqueue)
            }
        }
    }
    
    mutating func insertItemsAtIndex(_ itemsToInsert:[AudioTrack], index:Int) {
        if(index <= indexOfNowPlayingItem) {
            indexOfNowPlayingItem += itemsToInsert.count
        }
        currentQueue.insert(contentsOf: itemsToInsert, at: index)
    }
    
    mutating func deleteItemsAtIndices(_ indiciesToRemove:[Int]) -> Bool {
        var currentQueue = self.currentQueue
        let indicies = indiciesToRemove.sorted(by: >)

        var nowPlayingItemRemoved = false
        for index in indicies {
            currentQueue.remove(at: index)
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
    
    mutating func moveMediaItem(fromIndexPath:Int, toIndexPath:Int) {
        var currentQueue = self.currentQueue
        let tempMediaItem = currentQueue.remove(at: fromIndexPath)
        currentQueue.insert(tempMediaItem, at: toIndexPath)
        
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
            currentQueue.removeSubrange(0..<index)
            let newCount = currentQueue.count
            if index > indexOfNowPlayingItem {
                indexOfNowPlayingItem = 0
                nowPlayingItemRemoved = true
            } else {
                indexOfNowPlayingItem -= (oldCount - newCount)
            }
        case .below:
            currentQueue.removeSubrange((index + 1)..<currentQueue.count)
            if index < indexOfNowPlayingItem {
                indexOfNowPlayingItem = 0
                nowPlayingItemRemoved = true
            }
        case .bothDirections:
            let shuffleWasActive = shuffleActive
            let item = currentQueue[index]
            self = PlayQueue(originalQueue: [item], forType: type)
            setShuffleActive(shuffleWasActive)
        }
        return nowPlayingItemRemoved
    }
    
    fileprivate mutating func shuffleQueue() {
        if originalQueue.isEmpty {
            shuffledQueue = originalQueue
            return
        }
        
        var tempOriginalQueue = originalQueue
        
        //by doing this we are ensuring that the currently playing item is always on top
        shuffledQueue = [tempOriginalQueue.remove(at: indexOfNowPlayingItem)]
        var tempShuffledQueue = tempOriginalQueue
        for (index, item) in tempOriginalQueue.enumerated() {
            let randomIndex = KyoozUtils.randomNumber(belowValue: index)
            if randomIndex != index {
                tempShuffledQueue[index] = tempShuffledQueue[randomIndex]
            }
            tempShuffledQueue[randomIndex] = item
        }
        shuffledQueue.append(contentsOf: tempShuffledQueue)
        indexOfNowPlayingItem = 0
    }
    
    fileprivate mutating func restoreOriginalQueue() {
        guard shuffledQueue != nil && !shuffledQueue.isEmpty else {
            return
        }
        
        let shufSet = NSMutableSet(array: shuffledQueue)
        let origSet = NSSet(array: originalQueue)
        shufSet.minus(origSet as Set<NSObject>)
        if let objs = shufSet.allObjects as? [AudioTrack] {
            originalQueue.append(contentsOf: objs)
        }

        
        let item = shuffledQueue[indexOfNowPlayingItem]
        if let index = originalQueue.index(where: { return item.id == $0.id }) {
            indexOfNowPlayingItem = index
        }
    }
    
}

final class PlayQueuePersistableWrapper : NSObject, NSSecureCoding {
    fileprivate static let originalQueueKey = "originalQueue"
    fileprivate static let shuffledQueueKey = "shuffledQueue"
    fileprivate static let shuffleActiveKey = "shuffleActiveKey"
    fileprivate static let typeKey = "typeKey"
    
    fileprivate typealias This = PlayQueuePersistableWrapper
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    let context:PlayQueue
    
    init(context:PlayQueue) {
        self.context = context
    }
    
    required init?(coder aDecoder: NSCoder) {
        let type = AudioQueuePlayerType(rawValue: aDecoder.decodeInteger(forKey: This.typeKey)) ?? .default
        guard let originalQueue = aDecoder.decodeObject(of: NSArray.self, forKey: This.originalQueueKey) as? [AudioTrack] else {
            self.context = PlayQueue(originalQueue: [AudioTrack](), forType: type)
            return
        }
        var context = PlayQueue(originalQueue: originalQueue, forType: type)
        
        let shuffleActive = aDecoder.decodeBool(forKey: This.shuffleActiveKey)
        
        if shuffleActive {
            if let shuffledQueue = aDecoder.decodeObject(of: NSArray.self, forKey: This.shuffledQueueKey) as? [AudioTrack] {
                context.shuffledQueue = shuffledQueue
                context.shuffleActive = shuffleActive
            }
        }
        
        self.context = context
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(context.originalQueue as NSArray, forKey: This.originalQueueKey)
        if context.shuffleActive {
            aCoder.encode(context.shuffleActive, forKey: This.shuffleActiveKey)
            aCoder.encode(context.shuffledQueue as NSArray, forKey: This.shuffledQueueKey)
        }
        aCoder.encode(context.type.rawValue, forKey: This.typeKey)
    }
}


