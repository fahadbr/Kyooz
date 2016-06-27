//
//  ArrayExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

extension Array {
    
    mutating func insertAtIndex(itemsToInsert:[Element], index:Int, placeHolderItem:Element) {
        if(itemsToInsert.isEmpty) { return }
        
        if(index >= self.count) {
            self.appendContentsOf(itemsToInsert)
            return
        }
        
        if(itemsToInsert.count == 1) {
            self.insert(itemsToInsert[0], atIndex: index)
            return
        }
        
        //create a new array and place items in it accordingly, as it is much more efficient
        //than calling the insert function on the array multiple times
        let originalArray = self
        let endIndexOfInsertedItems = index + itemsToInsert.count
        let newArraySize = originalArray.count + itemsToInsert.count

        var newArray = [Element](count:newArraySize, repeatedValue:placeHolderItem)
        
        for i in 0..<newArraySize {
            if(index <= i && i < endIndexOfInsertedItems) {
                newArray[i] = itemsToInsert[i - index]
            } else if (i < index){
                newArray[i] = originalArray[i]
            } else if (i >= endIndexOfInsertedItems) {
                newArray[i] = originalArray[i - itemsToInsert.count]
            }
        }
        
        self = newArray
    }


    func diffed(with array: [Element], predicate:(Element, Element) -> Bool) -> ArrayDiff<Element> {
        return ArrayDiff(lhs: self, rhs: array, predicate: predicate)
    }
}

enum ValueResult { case Added, Removed }

struct ArrayDiffValue<T> { let index:Int, value:T, result:ValueResult }

struct ArrayDiff<T> {
    
    let diffValues:[ArrayDiffValue<T>]
    
    init(lhs:[T], rhs:[T], predicate:(T, T) -> Bool ) {
        var diffValues = [ArrayDiffValue<T>]()
        diffValues.appendContentsOf(lhs.filter { i in !rhs.contains({ predicate($0, i) }) }.enumerate().map { ArrayDiffValue(index: $0, value: $1, result: .Removed) })
        diffValues.appendContentsOf(rhs.filter { i in !lhs.contains({ predicate($0, i) }) }.enumerate().map { ArrayDiffValue(index: $0, value: $1, result: .Added) })
        self.diffValues = diffValues
    }
    
}